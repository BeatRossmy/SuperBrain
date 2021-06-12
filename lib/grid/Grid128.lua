Grid128 = {}

Grid128.new = function (_id, _grid)
  obj = {
    id = _id,
    grid = _grid,
    aftertouch_active = false,
    intensity_level = 127,
    leds = {},
    ledBuffer = {},

    init = function (self)
      print("lp init")
      self:set_aftertouch (self.aftertouch_active)
      self:intensity (self.intensity_level)
      
      for x=1,10 do
        self.leds[x] = {}
        self.ledBuffer[x] = {} 
        for y=1,8 do
          self.leds[x][y] = 3
          self.ledBuffer[x][y] = 3
        end
      end

      self.grid.key = function(gx,gy,gz)
        self.key(gx,gy,gz)
      end
      
      
    --   clock.run(function (d) while true do d:clock() clock.sync(1/24) end end, self.device)
    end,
    
    set_aftertouch = function (self, state)
      print("set aftertouch")
      self.aftertouch_active = state
      t = state and 0 or 2
    --   msg = {240, 0, 32, 41, 2, 12, 11, t, 247}
    --   self.device:send(msg)
    end,
    
    intensity = function (self, i)
      print("set intensity")
      i = util.clamp(i,0,127)
    --   msg = {240, 0, 32, 41, 2, 12, 8, i, 247}
    --   self.device:send(msg)
    end,
    
    key = function (gx,gy,gz) end,
    
    --                          c1= brightness c2=color
    led = function (self, x, y, val,t)
      if x>10 or x<1 or y>8 or y<1 then return end
      
    --   self.ledBuffer[x][y] = nil
      self.ledBuffer[x][y] = util.round(val)
    --   if t=="fade" then
    --     val = val>0 and math.floor(util.linlin(1,15,1,3,val)) or 0
    --     self.ledBuffer[x][y] = COLOR.new(2,pos_to_midi[x][y],val)
    --   else
    --     val = val>0 and math.floor(util.linlin(1,15,2,127,val)) or 0
    --     self.ledBuffer[x][y] = val
    --   end
    end,
    
    all = function (self, val)
      for x=1,10 do
        for y=1,8 do
          val = val>0 and val or 0
          self.ledBuffer[x][y] = val
        end
      end
    end,
    
    refresh = function (self)
    --   msg = {240,0,32,41,2,12,3}
    --   for x=1,10 do
    --     for y=1,8 do
    --       if not COLOR.equals(self.ledBuffer[x][y],self.leds[x][y]) then
    --         COLOR.copy(self.leds[x][y],self.ledBuffer[x][y])
    --         tabutil.insert_table(msg,self.leds[x][y])
    --       end
    --       COLOR.copy(self.ledBuffer[x][y],self.leds[x][y])
    --     end
    --   end
    --   table.insert(msg,247)
    --   self.device:send(msg)

      self.grid:all(0)

      for x=1,10 do
        for y=1,8 do

            if self.ledBuffer[x][y] ~= self.leds[x][y] then
              self.leds[x][y] = self.ledBuffer[x][y]
              -- tabutil.insert_table(msg,self.leds[x][y])
            end
            self.ledBuffer[x][y] = self.leds[x][y]
            self.grid:led(x,y, self.ledBuffer[x][y])
        end
      end


      self.grid:refresh()
    end
  }

  obj:init()

  

  return obj
end
  
return Grid128