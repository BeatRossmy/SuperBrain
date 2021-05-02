include('lib/grid/COLOR')

LP_X = {}

pos_to_midi = {
  {81,71,61,51,41,31,21,11},
  {82,72,62,52,42,32,22,12},
  {83,73,63,53,43,33,23,13},
  {84,74,64,54,44,34,24,14},
  {85,75,65,55,45,35,25,15},
  {86,76,66,56,46,36,26,16},
  {87,77,67,57,47,37,27,17},
  {88,78,68,58,48,38,28,18},
  {89,79,69,59,49,39,29,19},
  {91,92,93,94,95,96,97,98}
}

data_to_pos = {}
for x=1,9 do
  for y,r_y in pairs({80,70,60,50,40,30,20,10}) do
    data_to_pos[r_y+x] = {x=x,y=y}
  end
end
for y=1,8 do 
  data_to_pos[90+y] = {x=10,y=y}
end

index_to_coo = function (id)
  id = id-1
  x = id%8 + 1
  y = math.floor(id/8) + 1
  return {x=x,y=y}
end

LP_X.new = function (_id, _dev, _aftertouch, _intensity)
  obj = {
    id = _id,
    device = _dev,
    aftertouch_active = _aftertouch,
    intensity_level = _intensity,
    leds = {},
    ledBuffer = {},
    modes = {["live"] = 0, ["programmer"] = 1},
    
    init = function (self)
      print("lp init")
      self:enter_mode("programmer")
      self:set_aftertouch (self.aftertouch_active)
      self:intensity (self.intensity_level)
      
      for x=1,10 do
        self.leds[x] = {}
        self.ledBuffer[x] = {} 
        for y=1,8 do
          self.leds[x][y] = COLOR.new(0,i,3)
          self.ledBuffer[x][y] = COLOR.new(0,i,3)
        end
      end
      
      clock.run(function (d) while true do d:clock() clock.sync(1/24) end end, self.device)
    end,
    
    enter_mode = function (self, mode)
      mode = self.modes[mode]
      if not mode then mode = 0 end
      msg = {240, 0, 32, 41, 2, 12, 14, mode, 247}
      self.device:send(msg)
    end,
    
    set_aftertouch = function (self, state)
      print("set aftertouch")
      self.aftertouch_active = state
      t = state and 0 or 2
      msg = {240, 0, 32, 41, 2, 12, 11, t, 247}
      self.device:send(msg)
    end,
    
    intensity = function (self, i)
      print("set intensity")
      i = util.clamp(i,0,127)
      msg = {240, 0, 32, 41, 2, 12, 8, i, 247}
      self.device:send(msg)
    end,
    
    key = function (x,y,z) end,
    
    --                          c1= brightness c2=color
    led = function (self, x, y, val,t)
      if x>10 or x<1 or y>8 or y<1 then return end
      
      self.ledBuffer[x][y] = nil
      if t=="fade" then
        val = val>0 and math.floor(util.linlin(1,15,1,3,val)) or 0
        self.ledBuffer[x][y] = COLOR.new(2,pos_to_midi[x][y],val)
      else
        val = val>0 and math.floor(util.linlin(1,15,2,127,val)) or 0
        self.ledBuffer[x][y] = COLOR.new(3,pos_to_midi[x][y],val,val,val)
      end
    end,
    
    all = function (self, val)
      for x=1,10 do
        for y=1,8 do
          val = val>0 and math.floor(util.linlin(1,15,2,127,val)) or 0
          self.ledBuffer[x][y] = COLOR.new(3,pos_to_midi[x][y],val,val,val)
        end
      end
    end,
    
    refresh = function (self)
      msg = {240,0,32,41,2,12,3}
      for x=1,10 do
        for y=1,8 do
          if not COLOR.equals(self.ledBuffer[x][y],self.leds[x][y]) then
            COLOR.copy(self.leds[x][y],self.ledBuffer[x][y])
            tabutil.insert_table(msg,self.leds[x][y])
          end
          COLOR.copy(self.ledBuffer[x][y],self.leds[x][y])
        end
      end
      table.insert(msg,247)
      self.device:send(msg)
    end
  }
  
  obj.device.event = function (data)
    -- AFTER TOUCH
    if data[1]==160 then return end
    local pos = data_to_pos[data[2]]
    if not pos then return end
    
    local z = util.linlin(0,127,0,1,data[3])
    -- print(pos.x,pos.y,z)
    obj.key(pos.x,pos.y,z)
  end
  
  obj:init()
  return obj
end
  
return LP_X