-- SUPER_BRAIN
-- v1.0.0 @beat
-- llllllll.co/t/22222
--
-- select LP_X as midi device 1
-- select 4 devices on slots 2-5

engine.name = "PolyPerc"
MusicUtil = require 'musicutil'
tabutil = include('lib/misc/tabutil')
include('lib/misc/helper_functions')

LP_X = include('lib/grid/LP_X')

include('lib/poly_fork')
Poly_Fork.engine_on = function (pitch,vel)
  engine.amp(util.linlin(0,1,0.05,0.7,vel))
  engine.hz(MusicUtil.note_num_to_freq(pitch))
end
Poly_Fork.engine_off = function (pitch,vel) end

include('lib/track')
include('lib/engine')

QuantumPhysics = include('lib/engines/quantumphysics')
GraphTheory = include('lib/engines/graphtheory')
TimeWaver = include('lib/engines/timewaver')

Info = include('lib/misc/info')
include('lib/docu')

engines = {GraphTheory.name,QuantumPhysics.name,TimeWaver.name}
engine_icons = {GraphTheory.icon,QuantumPhysics.icon,TimeWaver.icon}
new_engine = {GraphTheory.new,QuantumPhysics.new,TimeWaver.new}

midi_slots = {}
setup_device_slots = function (d_list)
  for i,d in pairs(d_list) do midi_slots[i] = {device=midi.connect(d), name=midi.vports[d].name} end
end
start_midi_devices = function ()
  for _,s in pairs(midi_slots) do s.device:start() end
end
continue_midi_devices = function () end
stop_midi_devices = function ()
  for _,s in pairs(midi_slots) do s.device:stop() end
end

BRAIN = include('lib/brain')
MENU_ENC = 0


--[[
=========================================================================
=========================================================================
--]]

function init()
  setup_device_slots({2,3,4,5})
  
  BRAIN:init()
  BRAIN:set_visible(1)
  
  clock.run(function () while true do redraw() clock.sleep(1/24) end end)
end

function key(n,z)
  if n==1 and z==1 then
    if BRAIN.ui_mode == "apps" then BRAIN.ui_mode = "settings"
    else BRAIN.ui_mode = "apps" end
    print(BRAIN.ui_mode)
  end
  
  if n==2 then
    if z==1 then
      MENU_ENC = 1
      BRAIN.help = true
    else
      BRAIN.help = false  
      MENU_ENC = 1
    end
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
  for cl_id,_ in pairs(clock.threads) do
    clock.cancel(cl_id)
  end
end