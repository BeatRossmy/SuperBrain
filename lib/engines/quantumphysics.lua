-- ADAPTED TO NEW LPX INDICES --
-- ========================== --
include('lib/misc/grid_util')

QuantumPhysics = {
  name = "quantum#physics",
  icon = "#",
  
  speeds = {1/16,1/8,1/4,1/2,1},
  
  ROW = function (r,p,rs,out)
    local row = {
      start = 4,
      pos = 0,
      next_pos = nil,
      pitch = p,
      vel = 0.66,
      resets = {r},
      speed = 2,
      clock_id = nil,
      
      destroy = function (self)
        if self.clock_id then clock.cancel(self.clock_id) end
        self = nil
      end,
      
      load_state = function (self, state)
        self.start = state["start"]
        self.pitch = state["pitch"]
        self.vel = state["vel"]
        self.resets = state["resets"]
        self.speed = state["speed"]
      end,
      
      set_speed = function (self, s)
        self.speed = s
      end,
      
      tick = function (self,rows,out)
        -- MOVE & TRIGGER
        if self.next_pos then
          self.pos = self.next_pos
          self.next_pos = nil
        elseif self.pos>0 then
          self.pos = self.pos-1
        end
        -- PLAY & RESET
        if self.pos==1 then
          out:note(self.pitch,self.vel,clock.get_beat_sec(QuantumPhysics.speeds[self.speed]))
          for _,r in pairs(self.resets) do rows[r].next_pos = rows[r].start end
        end
      end,
      
      run = function (self,rows,out) 
        while true do
          self:tick(rows,out)
          clock.sync(QuantumPhysics.speeds[self.speed])
        end
      end
    }
    
    return row
  end,

  new = function (engine_state, _p)
    local qp = engine_template(_p)
    
    qp.engine_type = QuantumPhysics
    qp.name = QuantumPhysics.name
    
    qp.destroy = function (self)
      for _,r in pairs(self.rows) do r:destroy() end
      self = nil
    end
    
    qp.area = {new_area(1,1,8,4)}
    
    qp.rows = {}
    for i=1,4 do qp.rows[i] = QuantumPhysics.ROW(i,60) end
    if engine_state then
      for i=1,4 do qp.rows[i]:load_state(engine_state["rows"][i]) end
    end
    
    qp.mode = "position"
    qp.selected_row = nil
    
    qp.get = function (self)
      return{
        name=QuantumPhysics.name,
        rows=self.rows
      }
    end
    
    qp.play = function (self)
      for _,r in pairs(self.rows) do
        if not r.clock_id then r.clock_id = clock.run(r.run,r,self.rows,self.output) end
      end
    end
    
    qp.stop = function (self)
      for _,r in pairs(self.rows) do
        if r.clock_id then
          clock.cancel(r.clock_id)
          r.clock_id = nil
        end
      end
    end
    
    qp.note_on = function (self,pitch,vel)
      if self.selected_row then
        self.rows[self.selected_row].pitch = pitch
        self.rows[self.selected_row].vel = vel
      else
        self.output:note_on(pitch,vel)
      end
    end
    
    qp.note_off = function (self,pitch,vel)
      if not self.selected_row then
        self.output:note_off(pitch,vel)
      end
    end
    
    qp.grid_event = function (self,e)
      if e.x==9 and e.type=="hold" then
        self.mode = "speed"
        self.selected_row = e.y
      elseif e.x==9 and e.type=="release" then
        self.mode = "position"
        self.selected_row = nil
        
      elseif self.mode=="position" then
        if e.x<9 and e.type=="click" then
          self.rows[e.y].start = e.x
          self.rows[e.y].pos = e.x
        elseif e.x<9 and e.type=="double_click" then
          self.rows[e.y].pos = 0
        elseif e.x==9 and e.type=="click" then
          if self.rows[e.y].pos>0 then self.rows[e.y].pos = 0
          else self.rows[e.y].pos = self.rows[e.y].start end
        end
        
        
      elseif self.mode=="speed" and e.x<9 then
        -- RESETS
        if e.x==8 and e.type=="click" then
          local resets = self.rows[self.selected_row].resets
          k = tabutil.key(resets,e.y)
          local action = k and table.remove or table.insert
          action(resets,k and k or e.y)
          BRAIN:set_overlay("reset",e.y)
        
        -- SPEED
        elseif e.x<6 and e.type=="click" then
          self.rows[e.y]:set_speed(e.x)
          BRAIN:set_overlay("speed",QuantumPhysics.speeds[e.x])
        end
      end
    end
    
    qp.redraw = function (self, lp)
      local act_notes = self.output:get_notes() 
      local sel_pitch = self.selected_row and {self.rows[self.selected_row].pitch} or {}
      self.keys.external_notes = self.mode=="position" and act_notes or sel_pitch
      
      if self.mode == "position" then
        for y,t in pairs(self.rows) do
          set_led(lp, t.start,y,2)
          local level = t.pos==1 and 15 or 5
          local style = t.clock_id and nil or "fade"
          set_led(lp, t.pos,y,level,style)
          level = t.pos==0 and 2 or 5
          set_led(lp, 9,y,level)
        end
      elseif self.mode=="speed" then
        for y=1,4 do
          local level = y==self.selected_row and 15 or 0
          set_led(lp, 9,y,level)
          
          local resets = self.rows[self.selected_row].resets
          level = tabutil.contains(resets,y) and 15 or 2
          set_led(lp, 8,y,level)
          
          v_radio(lp,1,#QuantumPhysics.speeds,y,self.rows[y].speed,2,10)
        end
      end
    end
    
    return qp
  end
}

return QuantumPhysics