-- SUPER_BRAIN
-- v1.0.0 @beat
-- https://llllllll.co/t/superbrain-multi-engine-midi-sequencer/44781
--
-- multi track sequencer
--
-- select LP_X as midi device 1
-- select 4 devices on slots 2-5

--[[
-- set true if using a Monome Grid, false if using a Novation Launchpad X
--]]
USE_GRID128 = true

LP_X = include('lib/grid/LP_X')
Grid128 = include('lib/grid/Grid128')

if USE_GRID128 then
  main_grid = Grid128.new(1, grid.connect())
else
  main_grid = LP_X.new(1,midi.connect(1),false,127)
end

MusicUtil = require 'musicutil'
tabutil = include('lib/misc/tabutil')
include('lib/misc/helper_functions')

--[[
change the sc engine here
and redefine how poly_fork should handle on and off
--]]
engine.name = "PolyPerc"
include('lib/poly_fork')
Poly_Fork.engine_on = function (pitch,vel)
  engine.amp(util.linlin(0,1,0.05,0.7,vel))
  engine.hz(MusicUtil.note_num_to_freq(pitch))
end
Poly_Fork.engine_off = function (pitch,vel) end

include('lib/brain')
BRAIN = Brain(main_grid)
MENU_ENC = 0

function init()
  -- Create data directory if it doesn't exist
  if not util.file_exists(_path.data.."SUPER_BRAIN/") then
    util.make_dir(_path.data.."SUPER_BRAIN/")
    print("Made SUPER_BRAIN data directory")
  end

  if USE_GRID128 then
    setup_device_slots({1,2,3,4})
  else
    setup_device_slots({2,3,4,5})
  end
  BRAIN:init()
  BRAIN:set_visible(1)
  
  clock.run(function () while true do redraw() clock.sleep(1/24) end end)
end

function key(n,z)
  if n==1 and z==1 then
    if BRAIN.ui_mode == "apps" then BRAIN.ui_mode = "settings"
    else BRAIN.ui_mode = "apps" end
    print(BRAIN.ui_mode)
  elseif n==2 then
    MENU_ENC = 1
    BRAIN.help = z==1
  end
end

function enc(n,d)
  MENU_ENC = util.clamp(MENU_ENC+d,1,10)
end

function redraw()
  screen:clear()
  BRAIN:redraw_screen()
  screen:update()
end

function cleanup()
  BRAIN:cleanup()
  BRAIN = nil
  for cl_id,_ in pairs(clock.threads) do clock.cancel(cl_id) end
end