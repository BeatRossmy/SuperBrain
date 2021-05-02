-- ADAPTED TO NEW LPX INDICES --
-- ========================== --

GraphTheory = {
  name = "graph^theory",
  icon = "^",
  
  speeds = {1/16,1/8,1/4,1/2,1,2,4,8},
  views = {[0]="steps",[1]="speed"},
  
  VERTEX = function (_id,conf)
    return {
      id = _id,
      notes = conf and conf["notes"] or {},
      edges = conf and conf["edges"] or {(_id==32 and 1 or _id+1)},
      
      set_note = function (self, n)
        tabutil.add_or_remove(self.notes,n)
      end,
      
      set_edge = function (self, e)
        if #self.edges==1 and tabutil.contains(self.edges,e) then return end
        tabutil.add_or_remove(self.edges,e)
      end,
      
      next = function (self,vertices)
        i = math.random(1,#self.edges)
        e = self.edges[i]
        return vertices[e]
      end
    }
  end,
  
  PLAYHEAD = function(_id,conf,vertices)
    return {
      id = _id,
      vertex = nil,
      start = conf and conf["start"] or nil,
      next = conf and vertices[conf["start"]] or nil,
      clock_id = nil,
      speed = conf and conf["speed"] or 2,
      active = conf and conf["active"] or false,
      
      destroy = function (self)
        if self.clock_id then clock.cancel(self.clock_id) end
        self = nil
      end,
      
      stop = function (self,vertices)
        if self.clock_id then
          clock.cancel(self.clock_id)
          self.clock_id = nil
        end
        self.clock_id = nil
        self.next = self.start and vertices[self.start] or self.next
      end,
      
      tick = function (self,vertices,out)
        if self.next then
          self.vertex = self.next
          self.next = nil
        elseif self.vertex == nil then
          self.vertex = vertices[1]
        else
          self.vertex = self.vertex:next(vertices)
        end
        if #self.vertex.notes>0 and self.active then
          for _,n in pairs(self.vertex.notes) do
            out:note(n,0.6,clock.get_beat_sec(GraphTheory.speeds[self.speed])*0.95)
          end
        end
      end,
      
      run = function (self,vertices,out) 
        while true do
          self:tick(vertices,out)
          clock.sync(GraphTheory.speeds[self.speed])
        end
      end
    }
  end,
  
  new = function (engine_state,_p)
    local gt = engine_template(_p)
    
    gt.engine_type = GraphTheory
    gt.name = GraphTheory.name
    
    gt.area = {new_area(1,1,8,4),new_area(1,10,4,1)}
    gt.selected_vertex = nil
    gt.selected_playhead = nil
    gt.view = "steps"
    
    gt.vertices = {}
    for i=1,32 do
      gt.vertices[i] = GraphTheory.VERTEX(i,engine_state and engine_state["vertices"][i] or nil)
    end
    
    gt.playheads = {}
    for i=1,4 do
      gt.playheads[i] = GraphTheory.PLAYHEAD(i,engine_state and engine_state["playheads"][i] or nil, gt.vertices)
    end
    
    gt.destroy = function (self)
      for _,p in pairs(self.playheads) do p:destroy() end
      self = nil
    end
    
    gt.get = function (self)
      return{
        name=GraphTheory.name,
        playheads = self.playheads,
        vertices = self.vertices
      }
    end
    
    gt.grid_event = function (self,e)
      local i = e.x+(e.y-1)*8
      
      if self.view=="speed" then
        if e.type=="click" then
          self.playheads[e.y].speed = e.x
          BRAIN:set_overlay("speed",GraphTheory.speeds[e.x])
        end
      end
      
      if e.x==9 then
        if e.type=="double_hold" then self.view = GraphTheory.views[e.y]
        elseif e.type=="release" then self.view = GraphTheory.views[0]
        elseif e.type=="click" then self.playheads[e.y].active = not self.playheads[e.y].active
        elseif e.type=="hold" and not self.selected_playhead then self.selected_playhead = e.y end
        if e.y==self.selected_playhead and e.type=="release" then self.selected_playhead = nil end
        return  
      end
      
      if self.selected_playhead then
        if e.type=="click" then
          self.playheads[self.selected_playhead].next = self.vertices[i]
        elseif e.type=="hold" and e.x<9 then
          self.playheads[self.selected_playhead].start = i
          BRAIN:set_overlay("start","vertex "..i)
        end
        return
      end
      
      if e.type=="hold" and not self.selected_vertex then self.selected_vertex = i
      elseif e.type=="release" and self.selected_vertex == i then self.selected_vertex = nil end
        
      if e.type=="click" then
        if self.selected_vertex then self.vertices[self.selected_vertex]:set_edge(i)
        elseif #self.keys:get_held_notes()>0 then 
          for _,n in pairs(self.keys:get_held_notes()) do
            self.vertices[i]:set_note(n)
          end
        end
      end
      
      if e.type=="double_click" then self.vertices[i].notes = {} end
    end
    
    gt.note_on = function (self,pitch,vel)
      if self.selected_vertex then
        self.vertices[self.selected_vertex]:set_note(pitch)
        -- velocity ???
      else
        self.output:note_on(pitch,vel)
      end
    end
    
    gt.note_off = function (self,pitch,vel)
      if self.selected_row then
      else self.output:note_off(pitch,vel) end
    end
    
    gt.play = function (self)
      for _,p in pairs(self.playheads) do
        if not p.clock_id then p.clock_id = clock.run(p.run,p,self.vertices,self.output) end
      end
    end
    
    gt.stop = function (self)
      for _,p in pairs(self.playheads) do p:stop(self.vertices) end
    end
    
    gt.redraw = function (self, lp)
      
      if self.view == "speed" then
        for _,p in pairs(self.playheads) do
          v_radio(lp,1,#GraphTheory.speeds,p.id,p.speed,2,10)
        end
        return
      end
    
      for _,v in pairs(self.vertices) do
        if #v.notes>0 then 
          local pos = index_to_pos[v.id]
          lp:led(pos.x,pos.y,2)
        end
      end
      
      -- playhead
      for i,p in pairs(self.playheads) do
        lp:led(9,p.id,p.active and 5 or 2)
        if p.active then
          local step = p.vertex and p.vertex.id or 1
          local pos = index_to_pos[step]
          local level = self.selected_vertex and 1 or 15
          level = (self.selected_playhead and self.selected_playhead~=i) and 5 or level
          local style = p.clock_id==nil and "fade" or nil
          lp:led(pos.x,pos.y,level,style)
        end
        
      end
      
      if self.selected_playhead then
        local p = self.playheads[self.selected_playhead]
        if p.start then
          local pos = index_to_pos[p.start]
          lp:led(pos.x,pos.y,15)
        end
      end
      
      -- selected vertex
      if self.selected_vertex then
        local pos = index_to_pos[self.selected_vertex]
        lp:led(pos.x,pos.y,15)
        for _,e in pairs(self.vertices[self.selected_vertex].edges) do
          local pos = index_to_pos[e]
          lp:led(pos.x,pos.y,15,"fade")
        end
      end
      
      if self.selected_vertex then
        self.keys.external_notes = self.vertices[self.selected_vertex].notes
      else
        self.keys.external_notes = self.output:get_notes()
      end
    end
    
    return gt
  end
}

return GraphTheory