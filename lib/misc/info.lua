INFO = {
  new = function () 
    local info = {}
    info.name = "..."
    
    info.add_info = function (self,a,t)
      self[#self+1] = {area={x=a[1],y=a[2],w=a[3],h=a[4]},text=t}
    end
    
    info.draw_lpx = function (self,o_x,o_y,s)
      local x_off = o_x and o_x or 0
      local y_off = o_y and o_y or 0
      if not s then s = 4 end
      
      screen.level(2)
      -- BUTTONS
      for y=0,7 do
        for x=0,7 do
          screen.rect(x_off+x*s,y_off+y*s,s,s)
          screen.stroke()
        end
      end
      -- TOP
      for x=0,7 do
        screen.rect(x_off+x*s,y_off-1.5*s,s,s)
        screen.stroke()
      end
      -- SIDE
      for y=0,7 do
        screen.rect(x_off+8.5*s,y_off+y*s,s,s)
        screen.stroke()
      end
    end
    
    info.draw = function (self,i,o_x,o_y,s)
      local x_off = o_x and o_x or 0
      local y_off = o_y and o_y or 0
      if not s then s = 4 end
      i = i<1 and 1 or i
      i = i>#self and #self or i
      local area = {x=self[i].area.x,y=self[i].area.y,w=self[i].area.w,h=self[i].area.h}
      local x = area.x
      local y = area.y
      
      screen.font_size(8)
      
      -- BOX
      if x<9 and y<9 then
        -- ...
      --[[elseif y==9 then
        y = 0
        y_off = y_off-s/2--]]
      elseif x==10 then
        x = y
        y = 0
        local t = area.w
        area.w = area.h
        area.h = t
        y_off = y_off-s/2
      elseif x==9 then
        x_off = x_off+s/2
      end
      --[[elseif y==10 then
        local t = x
        x = y-1
        y = t
        x_off = x_off+s/2
        t = area.w
        area.w = area.h
        area.h = t
      end--]]
      screen.level(15)
      screen.rect(x_off+(x-1)*s,y_off+(y-1)*s,area.w*s,area.h*s)
      screen.stroke()
      
      x_off = o_x -- reset offset
      y_off = o_y
      
      -- TEXT
      for y,t in pairs(self[i].text) do
        screen.move(x_off+10.5*s,y_off-s+y*8)
        screen.text(t)
      end
      
    screen.move(74,60)
    screen.level(2)
    screen.text("* click _ hold")
      
    end
    
    return info
  end
  
}

return INFO