new_area = function (_x,_y,_w,_h)
  a = {x=_x,y=_y,w=_w,h=_h}
  a.in_area = function (self,x,y)

    -- print("In Area "..x.." "..y)
    -- print("w,h Area "..self.x.." "..self.y)

    return (x>=self.x and y>=self.y and x<self.x+self.w and y<self.y+self.h)
  end
  return a
end

snap_length_to_array = function (length, snap_array)
  local snap_array_len = #snap_array
  if snap_array_len == 1 then
    length = snap_array[1]
  elseif length >= snap_array[snap_array_len] then
    length = snap_array[snap_array_len]
  else
    local delta
    local prev_delta = math.huge
    for s = 1, snap_array_len + 1 do
      if s > snap_array_len then
        length = length + prev_delta
        break
      end
      delta = snap_array[s] - length
      if delta == 0 then
        break
      elseif math.abs(delta) >= math.abs(prev_delta) then
        length = length + prev_delta
        break
      end
      prev_delta = delta
    end
  end
  return length
end

index_to_pos = {
  {x=1,y=1},{x=2,y=1},{x=3,y=1},{x=4,y=1},{x=5,y=1},{x=6,y=1},{x=7,y=1},{x=8,y=1},
  {x=1,y=2},{x=2,y=2},{x=3,y=2},{x=4,y=2},{x=5,y=2},{x=6,y=2},{x=7,y=2},{x=8,y=2},
  {x=1,y=3},{x=2,y=3},{x=3,y=3},{x=4,y=3},{x=5,y=3},{x=6,y=3},{x=7,y=3},{x=8,y=3},
  {x=1,y=4},{x=2,y=4},{x=3,y=4},{x=4,y=4},{x=5,y=4},{x=6,y=4},{x=7,y=4},{x=8,y=4},
  {x=1,y=5},{x=2,y=5},{x=3,y=5},{x=4,y=5},{x=5,y=5},{x=6,y=5},{x=7,y=5},{x=8,y=5},
  {x=1,y=6},{x=2,y=6},{x=3,y=6},{x=4,y=6},{x=5,y=6},{x=6,y=6},{x=7,y=6},{x=8,y=6},
  {x=1,y=7},{x=2,y=7},{x=3,y=7},{x=4,y=7},{x=5,y=7},{x=6,y=7},{x=7,y=7},{x=8,y=7},
  {x=1,y=8},{x=2,y=8},{x=3,y=8},{x=4,y=8},{x=5,y=8},{x=6,y=8},{x=7,y=8},{x=8,y=8}
}

v_range = function (grid,a,b,y,d_l,h_l)
  for x=a,b do
    local level = (x==a or x==b) and h_l or d_l
    grid:led(x,y,level)
  end
end

v_radio = function (grid,a,b,y,v,d_l,h_l)
  for x=a,b do
    local level = (x-(a-1)==v) and h_l or d_l
    grid:led(x,y,level)
  end
end