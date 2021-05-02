new_track = function (_id,_keys)
  local track = {
    id = _id,
    keys = _keys,
    engine_type = 1, -- nil
    engine = nil,
    output = Poly_Fork:new(), --"engine",1,"poly"
    visible = false,
    
    -- handle_keaboard = function (self) end,
    
    reset_engine = function (self)
      self:set_engine(self.engine_type,nil)
    end,
    
    set_engine = function (self, engine_type, engine_state)
      if self.engine then self.engine:destroy() end
      self.engine = nil
      self.engine_type = engine_type
      self.engine = new_engine[engine_type](engine_state, self)
      
      -- self.engine:init(self)
      
      if self.visible then self.keys.target = self.engine end
      self.engine.keys = self.keys
    end,
    
    set_visible = function (self)
      if not self.visible then
        self.keys.target = self.engine
      end
      self.visible = true
    end,
    
    set_unvisible = function (self)
      if self.visible then
        self.keys.target = nil
      end
      self.visible = false
    end,
    
    handle_settings = function (self, e)
      if (e.type=="press" or e.type=="double") then
        -- 1st row -> engine: ...
        if e.y==1 and e.x<=#engines then
          self:set_engine(e.x,nil)
          BRAIN:set_overlay("engine",engines[e.x])
          
        -- 2nd row -> target: internal, midi & ports: 1-4
        elseif e.y==2 and e.x<3 then
          self.output:set_target(e.x)
          BRAIN:set_overlay("target",(e.x==1 and "internal" or "midi"))
        -- port
        elseif e.y==2 and e.x>4 then
          self.output:set_port(e.x-4)
          BRAIN:set_overlay("slot","midi "..e.x-4)
          
        -- 3rd row -> mode: poly, fork(=mono)
        elseif e.y==3 and e.x<3 then
          self.output:set_mode(e.x)
          BRAIN:set_overlay("midi routing",e.x==1 and "poly" or "fork")
          
        -- 4+5 row -> channels
        elseif e.y==4 or e.y==5 then
          local x = e.x + (e.y==5 and 8 or 0)
          self.output:add_channels({x})
          BRAIN:set_overlay("channel",x)
        end
      end
    end,
    
    show_settings = function (self, lp)
      -- 1st row -> engine: ...
      for x=1,3 do
        lp:led(x,1,x==self.engine_type and 15 or 3)
      end
      -- 2nd row -> target: internal, midi & ports: 1-4
      for x=1,2 do
        lp:led(x,2,x==self.output:target_key() and 15 or 3)
      end
      for x=1,4 do
        local level = self.output.target=="engine" and 1 or 3
        lp:led(x+4,2,(level==3 and x==self.output.port) and 15 or level)
      end
      -- 3rd row -> mode: poly, fork(=mono)
      for x=1,2 do
        lp:led(x,3,x==self.output:mode_key() and 15 or 3)
      end
      -- 4+5 row -> channels
      for x=1,16 do
        y = x<9 and 4 or 5
        lp:led(x<9 and x or x-8,y,3)
      end
      for _,ch in pairs(self.output.channels) do
        x = ch.ch
        y = x<9 and 4 or 5
        lp:led(x<9 and x or x-8,y,15)
      end
    end,
    
    rec = function(self) end,
    
    play = function(self)
      if self.engine then self.engine:play() end
    end,
    
    stop = function(self) 
      if self.engine then self.engine:stop() end
      -- self:save()
    end,
    
    save = function (self)
      e = self.engine and self.engine:get() or {}
      s = {id=self.id, engine=e, output=self.output:get()}
      tabutil.save(s, _path.data.."SUPER_BRAIN/"..self.id.."_track_state.txt")
    end,
    
    redraw = function (self)
      screen.level(15)
      screen.font_size(32)
      screen.move(64,48)
      screen.text_center(engine_icons[self.engine_type])
    end,
    
    get_state_for_preset = function (self)
      return {id=self.id, engine=self.engine, output=self.output:get()}
    end,
    
    load_preset = function (self, preset)
      local engine_state = preset["engine"]
      local engine_type = preset["engine"]["name"]
      if engine_type then self:set_engine(tabutil.key(engines,engine_type),engine_state) end
      local output_config = preset["output"]
      self.output:init(output_config)
    end
  }
  
  track:reset_engine()
  track.output:init()
  
  return track
end