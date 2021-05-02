Docu = {}

Docu[QuantumPhysics.name] = Info.new() 
Docu[QuantumPhysics.name].name = QuantumPhysics.name
Docu[QuantumPhysics.name]:add_info({1,1,8,1} ,{"*  start", "** stop"})
Docu[QuantumPhysics.name]:add_info({9,1,1,1},{"_  rsts, spd, ptch", "*  stop"})
-- GLOBAL
Docu[QuantumPhysics.name]:add_info({10,1,1,1} ,{"*  global play"})
Docu[QuantumPhysics.name]:add_info({10,2,1,1} ,{"*  global stop"})
Docu[QuantumPhysics.name]:add_info({10,3,1,1} ,{"_  presets"})
Docu[QuantumPhysics.name]:add_info({10,4,1,5} ,{"   track selector", "_  track menu", "** engine reset"})
Docu[QuantumPhysics.name]:add_info({1,5,8,4} ,{"   isomorphic keys"})
Docu[QuantumPhysics.name]:add_info({9,5,1,2},{"   octave buttons"})


Docu[GraphTheory.name] = Info.new() 
Docu[GraphTheory.name].name = GraphTheory.name
Docu[GraphTheory.name]:add_info({1,1,8,4} ,{"_  set pitch & targets", "** delete pitch"})
Docu[GraphTheory.name]:add_info({9,1,1,1},{"_  set next pos", "*  un/mute head", "*_ set speed"})
-- GLOBAL
Docu[GraphTheory.name]:add_info({10,1,1,1} ,{"*  global play"})
Docu[GraphTheory.name]:add_info({10,2,1,1} ,{"*  global stop"})
Docu[GraphTheory.name]:add_info({10,3,1,1} ,{"_  presets"})
Docu[GraphTheory.name]:add_info({10,4,1,5} ,{"   track selector", "_  track menu", "** engine reset"})
Docu[GraphTheory.name]:add_info({1,5,8,4} ,{"   isomorphic keys"})
Docu[GraphTheory.name]:add_info({9,5,1,2},{"   octave buttons"})


Docu[TimeWaver.name] = Info.new() 
Docu[TimeWaver.name].name = TimeWaver.name
Docu[TimeWaver.name]:add_info({9,1,1,1},{"*  arm loop", "**  clear loop", "_  time frame"})
-- GLOBAL
Docu[TimeWaver.name]:add_info({10,1,1,1} ,{"*  global play"})
Docu[TimeWaver.name]:add_info({10,2,1,1} ,{"*  global stop"})
Docu[TimeWaver.name]:add_info({10,3,1,1} ,{"_  presets"})
Docu[TimeWaver.name]:add_info({10,4,1,5} ,{"   track selector", "_  track menu", "** engine reset"})
Docu[TimeWaver.name]:add_info({1,5,8,4} ,{"   isomorphic keys"})
Docu[TimeWaver.name]:add_info({9,5,1,2},{"   octave buttons"})