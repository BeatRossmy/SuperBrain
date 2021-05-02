COLOR = {
  -- PRIME COLORS
  RED = 5,
  YELLOW = 13,
  GREEN = 21,
  CYAN = 29,
  LIGHTBLUE = 37,
  BLUE = 45,
  MAGENTA = 53,
  ORANGE = 61,
  
  -- MODES
  STATIC = 0,
  FLASHING = 1,
  PULSING = 2,
  RGB = 3,
  
  new = function (t,i,d1,d2,d3) return {t,i,d1,d2,d3} end,
  
  copy = function (t,s)
    t[1] = s[1]
    t[2] = s[2]
    t[3] = s[3]
    t[4] = s[4]
    t[5] = s[5]
  end,
  
  equals = function(c1,c2) return c1[1]==c2[1] and c1[2]==c2[2] and c1[3]==c2[3] and c1[4]==c2[4] and c1[5]==c2[5] end,
  
  print = function (c)
    print(c[1],c[2],c[3],c[4],c[5])
  end
}

return COLOR