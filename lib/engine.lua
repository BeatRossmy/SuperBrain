engine_template = function (_p)
  return {
    name = "",
    area = {new_area(1,1,8,4)},
    parent = _p,
    keys = nil,
    grid_handler = nil,
    output = _p.output,
    engine_type = nil,
    
    destroy = nil,
    
    init = function (self, parent) 
      self.parent = parent
      self.keys = parent.keys
      self.grid_handler = parent.grid_handler
      self.output = parent.output
    end,
    
    grid_event = function (self,e) end,
    
    start = function (self) end,
    stop = function (self) end,
    pause = function (self) end,
    reset = function (self) end,
    
    note_on = function (self,pitch,vel) end,
    note_off = function (self,pitch,vel) end,
    
    redraw = function (self, lp) end,
    cleanup = function (self) end,
    draw_screen = function (self) end
  }
end