PRE_REC = 2

TimeWaver = {
  name = "time~waver",
  icon = "~",
  
  Wave = function (o,conf)
    return {
      steps = conf and conf["steps"] or {},
      playing = conf and conf["playing"] or false,
      recording = false,
      
      start_beat = conf and conf["start_beat"] or 0,
      length = conf and conf["length"] or nil,
      quant_grid = conf and conf["quant_grid"] or 1/4, --beat == 1/16 bar
      note_count = conf and conf["note_count"] or 0,
      
      playhead = 0,
      clock_id = nil,
      out = o,
      
      early = conf and conf["early"] or 1,
      late = conf and conf["late"] or 8,
      
      destroy = function (self)
        if self.clock_id then clock.cancel(self.clock_id) end
        self = nil
      end,
      
      calculate_next_beat = function (interval)
        return util.round_up(clock.get_beats(),interval)
      end,
      
      quant = function (self,step)
        local s = util.round(step,self.quant_grid)
        local dir = util.linlin(-self.quant_grid/2,self.quant_grid/2,-1,1,step-s)
        return dir<-0.5 and s-self.quant_grid or s
      end,
      
      rec_note = function(self, note)
        local step = note.beat-self.start_beat
        step = self:quant(step)
        if self.clock_id then step = math.fmod(step,self.length) end
        if not self.recording or step<=0 then return end
        if self.steps[step]==nil then self.steps[step] = {} end
        self.note_count = self.note_count+1
        table.insert(self.steps[step],{note=note.note,vel=note.vel,length=note.length,t_index=self.note_count})
      end,
      
      rec = function (self)
        if self.recording then return end
        self.recording = true
        self.start_beat = self.length and self.start_beat or self.calculate_next_beat(PRE_REC)
      end,
      
      stop_rec = function (self)
        if not self.recording then return end
        -- INITIAL LOOP
        if not self.length then
          self.length = util.round(clock.get_beats() - self.start_beat)
          self.length = snap_length_to_array(self.length,{8,16,32,64,128,256,512,1024,2048})
          self:play()
        end
        self.recording = false
      end,
      
      clear = function (self)
        self.recording, self.playing = false, false
        self.steps = {}
        self.start_beat, self.playhead, self.note_count = 0, 0, 0
        if self.clock_id then clock.cancel(self.clock_id) end
        self.clock_id, self.length = nil, nil
      end,
      
      toggle_mode = function (self)
        if not self.recording then self:rec()
        else self:stop_rec() end
      end,
      
      play = function (self)
        if self.clock_id then return end
        self.playing = true
        self.clock_id = clock.run(
          function (w)
            clock.sync(w.quant_grid)
            while true do
              w.playhead = math.fmod(util.round(clock.get_beats()-w.start_beat,w.quant_grid),w.length)
              --w.out:notes(w.steps[w.playhead],0)
              if w.steps[w.playhead] then
                for _,n in pairs(w.steps[w.playhead]) do
                  local t = util.linlin(0,w.note_count,1,8,n.t_index)
                  if t>=w.early and t<=w.late then w.out:note(n.note,n.vel,n.length,0) end
                end
              end
              clock.sync(w.quant_grid)
            end
          end, self)
      end,
      
      draw = function (self,y,lp)
        local x = not self.length and 1 or math.floor(util.linlin(0,self.length,1,9,self.playhead))
        lp:led(x,y,10)
      end,
        
      stop = function (self)
        if not self.clock_id then return end
        self.playing = false
        clock.cancel(self.clock_id)
        self.clock_id = nil
      end
    }
  end,
  
  new = function (engine_state, _p)
    local tw = engine_template(_p)
    tw.engine_type = TimeWaver
    tw.name = TimeWaver.name
    tw.area = {new_area(1,1,8,4)}
    tw.note_buffer = {}
    tw.view = "wave" -- "wave","time_frame"
    tw.waves = {}
    for w=1,4 do
      tw.waves[w] = TimeWaver.Wave(tw.output, engine_state and engine_state["waves"][w] or nil)
    end
    
    tw.destroy = function (self)
      for _,w in pairs(self.waves) do w:destroy() end
      self = nil
    end
    
    tw.get = function (self)
      return{name=TimeWaver.name, waves=self.waves}
    end
    
    tw.play = function (self)
      for _,w in pairs(self.waves) do
        if w.length then w:play() end
      end
    end
    
    tw.stop = function (self)
      for _,w in pairs(self.waves) do
        w:stop()
      end
    end
    
    tw.note_on = function (self,pitch,vel)
      self.output:note_on(pitch,vel)
      self.note_buffer[pitch] = {note=pitch,vel=vel,beat=clock.get_beats()}
    end
    
    tw.note_off = function (self,pitch,vel)
      self.output:note_off(pitch,vel)
      
      if self.note_buffer[pitch] then
        local msg = self.note_buffer[pitch]        -- get "note_on" msg
        msg.length = clock.get_beats()-msg.beat    -- calculate length
        self.note_buffer[pitch] = nil              -- delete note from buffer
        
        for _,w in pairs(self.waves) do
          if w.recording then w:rec_note(msg) end
        end
      end
    end
    
    tw.grid_event = function (self,e)
      if e.type=="hold" and e.x==9 then
        self.view = "time_frame"
      elseif self.view=="time_frame" and e.type=="release" and e.x==9 then
        self.view = "wave"
      end
      
      if self.view=="wave" and e.x==9 then
        if e.type=="click" then
          self.waves[e.y]:toggle_mode()
        elseif e.type=="double_click"then
          self.waves[e.y]:clear()
        end  
      elseif self.view=="time_frame" then
        if e.type=="press" and e.x<9 then
          local d_e = self.waves[e.y].early-e.x
          local d_l = e.x-self.waves[e.y].late
          if d_e>0 or d_e>=d_l then
            self.waves[e.y].early=e.x
          elseif d_l>0 or d_l>=d_e then
            self.waves[e.y].late=e.x
          end
        end
      end
    end
    
    tw.redraw = function (self, lp)
      self.keys.external_notes = self.output:get_notes()
      if self.view=="wave" then
        for y,w in pairs(self.waves) do
          local level = w.recording and 10 or 2
          lp:led(9,y,level)
          if w.length then w:draw(y,lp) end
          if not w.length and w.recording and w.start_beat>clock.get_beats() then
            local x = util.round(util.linlin(0,PRE_REC,1,8,w.start_beat-clock.get_beats()),1)
            for i=1,x do lp:led(i,y,10) end
          end
        end
      elseif self.view=="time_frame" then
        for y,w in pairs(self.waves) do
          v_range(lp,w.early,w.late,y,3,10)
        end
      end
    end
    
    return tw
  end
}

return TimeWaver