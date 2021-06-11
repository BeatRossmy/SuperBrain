set_led = function (g, x, y, brightness, fade)
    fade = fade and fade or ""
    -- print("set led "..x.." "..y.." "..brightness.." "..fade)
    x = util.round (x)
    y = util.round(y)
    brightness = util.round(brightness)
    g:led(x, y,brightness)
end