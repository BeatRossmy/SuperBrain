include('lib/track')
include('lib/engine')

QuantumPhysics = include('lib/engines/quantumphysics')
GraphTheory = include('lib/engines/graphtheory')
TimeWaver = include('lib/engines/timewaver')

Info = include('lib/misc/info')
include('lib/docu')

engines = {GraphTheory.name,QuantumPhysics.name,TimeWaver.name}
engine_icons = {GraphTheory.icon,QuantumPhysics.icon,TimeWaver.icon}
new_engine = {GraphTheory.new,QuantumPhysics.new,TimeWaver.new}

midi_slots = {}
setup_device_slots = function (d_list)
  for i,d in pairs(d_list) do midi_slots[i] = {device=midi.connect(d), name=midi.vports[d].name} end
end
start_midi_devices = function ()
  for _,s in pairs(midi_slots) do s.device:start() end
end
continue_midi_devices = function () end
stop_midi_devices = function ()
  for _,s in pairs(midi_slots) do s.device:stop() end
end

Brain = function (g)
  return {
    grid = g,
    grid_handler = include('lib/grid/grid_handler').new(),
    keys = include('lib/isomorphic_keyboard'),
    tracks = {},
    ui_mode = "apps", -- "apps","settings","presets"
    preset = 1,
    focus = 1,
    transport_state = "stop",
    overlay = {text="superbrain",time=util.time()+3},
    help = false,
    
    init = function (self)
      self.tracks = {}
      for i=1,5 do self.tracks[i] = new_track(i,self.keys) end
      
      self:load_preset(1)
      
      self.grid:all(0)
      self.grid:refresh()

      self.grid.key = function (gx,gy,gz) 
        -- print("Key "..gx.." "..gy.." "..gz)
        self:grid_key(gx,gy,gz)
        -- self:key(x,y,z) 
      end
      
      self.grid_handler.grid_event = function (e) self:grid_event(e) end
      
      -- DRAW
      clock.run(function (self) while true do self:redraw() clock.sleep(1/30) end end ,self)
    end,
    
    set_overlay = function (self,t,st,duration)
      self.overlay = {text="",subtext="",time=0}
      self.overlay.text = t
      self.overlay.subtext = st
      self.overlay.time = util.time()+(duration and duration or 2)
    end,
    
    draw_help = function (info)
      local x_off = 1
      local y_off = 20
      local w = 4
      
      -- NAME
      if info.name then
        screen.level(15)
        screen.font_size(8)
        screen.move(x_off,8)
        screen.text(info.name)
      end
      screen.level(2)
      screen.move(106,8)
      screen.text("focus")
      
      info:draw_lpx(x_off,y_off,w)
      
      i = info[highlight]
      
      info:draw(MENU_ENC,x_off,y_off,w)
    end,
    
    redraw_screen = function (self)
      screen.move(8,60)
      screen.font_size(8)
      screen.level(self.help and 15 or 2)
      screen.text("help")
      
      local info = Docu[self.tracks[self.focus].engine.name]
      if self.help and info then
        self.draw_help(info)
        return
      end
      
      -- OUT
      screen.line_width(1)
      for _,n in pairs(self.tracks[self.focus].output.active_notes) do
        local x = util.linlin(1,127,9,121,n.note)
        screen.pixel(x,2)
        screen.stroke()
      end
      
      -- TOP LINE
      screen.level(15)
      screen.move(9,5)
      screen.line(121,5)
      screen.stroke()
      
      -- PLAY / STOP
      local level = self.transport_state=="pre_play" and 2 or 15 
      -- if self.transport_state=="play" then level = math.floor(util.linlin(0,1,15,2,math.fmod(clock.get_beats(),1))) end
      screen.level(level)
      if self.transport_state=="stop" then
        screen.rect(10,9,6,6)
      else
        screen.move(10,9)
        screen.line(16,12)
        screen.line(10,15)
      end
      screen.fill()
      
      -- STEP
      screen.level(self.transport_state=="pre_play" and 15 or 2)
      screen.move(13,25)
      screen.font_size(8)
      screen.text_center(1+math.fmod(math.floor(clock.get_beats()),4))
      
      -- SELECTED TRACK
      screen.level(15)
      screen.rect(113,9,8,8)
      screen.stroke()
      screen.move(117,15)
      screen.font_size(8)
      screen.text_center(self.focus)
      
      -- OVERLAY
      if self.overlay then
        -- TEXT
        screen.level(15)
        screen.font_size(16)
        screen.move(64,40)
        screen.text_center(self.overlay.text)
        -- SUBTEXT
        if self.overlay.subtext then
          screen.level(2)
          screen.font_size(8)
          screen.move(64,56)
          screen.text_center(self.overlay.subtext)
        end
        -- REMOVE OVERLAY
        if util.time() > self.overlay.time then self.overlay = nil end
      else
        -- DRAW TRACK
        self.tracks[self.focus]:redraw()
      end
    end,
    
    redraw = function (self)
      local sel_tr = self.tracks[self.focus]
      self.grid:all(0)
      
      -- ADAPTED TO NEW LPX INDICES --
      -- ========================== --
      -- TRANSPORT
        self.grid:led(10,1,self.transport_state=="play" and 15 or 2)
        self.grid:led(10,2,2)
      
      -- TRACK SELECTION
      for i=1,#self.tracks do
        self.grid:led(10,8-#self.tracks+i,i==self.focus and 15 or 2)
      end
      
      if self.ui_mode=="apps" then
        -- FOCUSSED TRACK
        if sel_tr.visible and sel_tr.engine then sel_tr.engine:redraw(self.grid) end
        -- KEYBOARD
        if self.keys.visible then self.keys:redraw(self.grid) end
      elseif self.ui_mode=="settings" then
        sel_tr:show_settings(self.grid)
      elseif self.ui_mode=="presets" then
        local folder = _path.data.."SUPER_BRAIN/"
        listing = util.scandir(folder)
        --tab.print(listing)
        for i=1,64 do
          local file_path = _path.data.."SUPER_BRAIN/preset_"..i..".txt"
          if util.file_exists (file_path) then
            local pos = index_to_pos[i]
            self.grid:led(pos.x,pos.y,3)
          end
        end
        local pos = index_to_pos[self.preset]
        self.grid:led(pos.x,pos.y,5,"fade")
      end
      
      self.grid:refresh()
    end,
    
    grid_event = function (self,e)
      local sel_tr = self.tracks[self.focus]
      
      -- ADAPTED TO NEW LPX INDICES --
      -- ========================== --
      
      -- TOP BAR
      if e.x==10 then
        -- TRANSPORT
        if e.y<3 then
          if e.type=="press" or e.type=="double" then
            self.transport_state = e.y==1 and "pre_play" or "stop"
            for _,t in pairs(self.tracks) do
              if self.transport_state=="pre_play" then 
                clock.run(function (tr) clock.sync(4) tr:play() end, t)
              elseif self.transport_state=="stop" then
                t:stop()
              end
            end
            if self.transport_state=="pre_play" then
              clock.run(function (b)
                clock.sync(4)
                b.transport_state="play"
                start_midi_devices() end, self)
            elseif self.transport_state=="stop" then
              stop_midi_devices()
            end
          end
          
        -- PRESTS
        elseif e.y==3 then
          if e.type=="hold" then
            self.ui_mode = "presets"
          elseif e.type=="release" and self.ui_mode=="presets" then
            self.ui_mode = "apps"
          end
          
        -- TRACKS
        elseif e.y>8-#self.tracks then
          local t = e.y-(8-#self.tracks)
          self:set_visible(t)
          if (e.type=="double_click") then
            self.tracks[t]:reset_engine()
          elseif e.type=="hold" then
            self.ui_mode = "settings"
          elseif e.type=="release" then
            self.ui_mode = "apps"
          end
        end
        
      -- ADAPTED TO NEW LPX INDICES --
      -- ========================== --
      
      -- SIDE
      elseif e.x==9 then
        -- ENGINE SIDE BUTTONS
        if (e.y<5) and self.ui_mode=="apps" then
          sel_tr.engine:grid_event(e)
        -- TRANSPOSE
        elseif (e.y==5 or e.y==6) and self.ui_mode=="apps" then
          if (e.type=="press" or e.type=="double") then self.keys:transpose(e.y==5 and 1 or -1) end
        end
      
      -- MATRIX
      elseif e.x<9 and e.y<9 then
        -- APPS
        if self.ui_mode=="apps" then
          if self.ui_mode=="apps" then sel_tr.engine:grid_event(e) end
        -- SETTINGS
        elseif self.ui_mode=="settings" and (e.type=="press" or e.type=="double") and e.y<9 then
          sel_tr:handle_settings(e)
        -- PRESETS
        elseif self.ui_mode=="presets" and e.y<9 then
          local pre_nr = (e.y-1)*8+e.x
          if e.type=="click" then
            print("select",pre_nr)
            self.preset = pre_nr
            self:load_preset(pre_nr)
          elseif e.type=="hold" then
            print("save to",pre_nr)
            self:save_preset(pre_nr)
          end
        end
      end
    end,

    grid_key = function (self, gx, gy, gz)
      if self.ui_mode=="apps" then
        -- KEYBOARD
        if self.keys.area:in_area(gx,gy) then
          self.keys:key(gx,gy,gz)
          return
        end
      end
      self.grid_handler:key(gx,gy,gz)
    end,

    set_visible = function (self, index) 
      self.tracks[self.focus]:set_unvisible()
      self.focus = util.clamp(index,1,#self.tracks)
      self.tracks[self.focus]:set_visible()
    end,
    
    save_preset = function (self,pre_nr)
      local preset_table = {}
      
      for i,t in pairs(self.tracks) do
        -- local s = {id=t.id, engine=t.engine, output=t.output:get()}
        preset_table[i] = t:get_state_for_preset()
      end
    
      tabutil.save(preset_table, _path.data.."SUPER_BRAIN/preset_"..pre_nr..".txt")
    end,
    
    load_preset = function (self, pre_nr)
      local file_path = _path.data.."SUPER_BRAIN/preset_"..pre_nr..".txt"
      if util.file_exists (file_path) then
        -- load from file
        local saved_data = tabutil.load(file_path)
        for i,t in pairs(self.tracks) do
          t:load_preset(saved_data[i])
        end
        print("loaded "..pre_nr)
      else
        for i,t in pairs(self.tracks) do
          --t:default()
          print("set to default")
        end
      end
    end,
    
    cleanup = function (self)
      for _,t in pairs(self.tracks) do
        if t.output then t.output:kill_all_notes() end
      end
      
      if self.grid.enter_mode then self.grid:enter_mode("live") end
    end
  }
end

-- return BRAIN