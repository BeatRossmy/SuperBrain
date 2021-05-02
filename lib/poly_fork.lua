NOTE_mt = {__eq = function (e1, e2) return (e1.note==e2.note) end}
NOTE = function (_note,_vel,_ch)
  note = {note=_note,vel=_vel,ch=_ch}
  setmetatable(note, NOTE_mt)
  return note
end

CH_mt = {__eq = function (e1, e2) return (e1.ch==e2.ch) end,
         __lt = function (e1, e2) return (e1.ch<e2.ch) end,
         __le = function (e1, e2) return (e1.ch<=e2.ch) end}
CH = function (_ch)
  ch = {ch=_ch,used=util.time()}
  setmetatable(ch, CH_mt)
  return ch
end

Poly_Fork = {
  engine_on = function(pitch,vel) end,
  engine_off = function(pitch,vel) end,
  targets = {"engine","midi"},
  modes = {"poly","fork"},
  
  new = function (self)
    pf = {
      target = "engine",
      port = 1,
      mode = "poly",
      channels = {CH(1)},
      
      device = midi_slots[1].device,
      engine_on = nil,
      engine_off = nil,
      active_notes = {},
      
      get = function (self)
        local ch = {}
        for _,c in pairs(self.channels) do table.insert(ch,c.ch) end
        return{port=self.port,channels=ch,mode=self.mode,target=self.target}
      end,
      
      init = function (self, out_config)
        self.engine_on = Poly_Fork.engine_on
        self.engine_off = Poly_Fork.engine_off
        
        if out_config then
          self.port = out_config["port"]
          self.device = midi_slots[self.port].device
          
          self.target = out_config["target"]
          self.mode = out_config["mode"]
          
          local ch = out_config["channels"]
          self.channels = {}
          self:add_channels(ch)
        end
      end,
      
      set_target = function (self, t)
        self:kill_all_notes()
        self.target = Poly_Fork.targets[t]
      end,
      
      target_key = function (self)
        return tabutil.key(Poly_Fork.targets,self.target)
      end,
      
      set_port = function (self, p)
        self:kill_all_notes()
        self.port = p
        self.device = midi_slots[self.port].device
      end,
      
      set_mode = function (self, m)
        self:kill_all_notes()
        self.mode = Poly_Fork.modes[m]
        
        if self.mode=="poly" then
          table.sort(self.channels)
          local n_ch = self.channels[1]
          self:clear_channels()
          self.channels[1] = n_ch
        end
      end,
      
      mode_key = function (self)
        return tabutil.key(Poly_Fork.modes,self.mode)
      end,
      
      kill_all_notes = function (self)
        for _,note in pairs(self.active_notes) do
          self:note_off(note.note,note.vel)
        end
      end,
      
      clear_channels = function (self)
        self.channels = {}
      end,
      
      add_channels = function (self, ch)
        if self.mode=="poly" then
          if #ch>0 then
            self:clear_channels()
            self.channels[1] = CH(ch[1])
          end
          return
        end
        for _,c in pairs(ch) do
          if #self.channels>1 or tabutil.contains(self.channels,CH(c)) == false then tabutil.add_or_remove(self.channels,CH(c)) end
        end
      end,
      
      get_notes = function (self)
        local notes = {}
          for _,n in pairs(self.active_notes) do table.insert(notes,n.note) end
        return notes
      end,
      
      note = function (self,note,vel,length,delay)
        clock.run(function (s,n,v,l,d)
          if d then clock.sleep(d) end
          s:note_on(n,v)
          clock.sleep(l)
          s:note_off(n,0)
        end,self,note,vel,length,delay)
      end,
      
      notes = function (self,notes,delay)
        if not notes then return end
        for _,n in pairs(notes) do
          self:note(n.note,n.vel,n.length,delay)
        end
      end,
      
      note_on = function (self,note,vel)
        local ch = 1
        if self.mode=="poly" and #self.channels>0 then
          ch = self.channels[1].ch
        elseif self.mode=="fork" then
          if #self.active_notes==#self.channels then -- stop one note if all channels are full
            n = self.active_notes[1]
            self:note_off(n.note,0,n.ch)
          end
          table.sort(self.channels,function(a,b) return a.used>b.used end)
          ch = self.channels[#self.channels].ch
          self.channels[#self.channels].used = 100000000000 + util.time()
        end
        -- NOTE ON
        if self.target=="midi" then
          v = math.floor(util.linlin(0,1,0,127,vel))
          self.device:note_on(note,v,ch)
        elseif self.target=="engine" then
          self.engine_on(note,vel,ch)
        end
        table.insert(self.active_notes,NOTE(note,vel,ch))
      end,
      
      note_off = function (self,note,vel)
        local n = tabutil.get(self.active_notes,NOTE(note,0,0))
        if n then
          if self.mode=="fork" then
            for _,c in pairs(self.channels) do if n.ch==c.ch then c.used = util.time() end end  
          end
          -- NOTE OFF
          if self.target=="midi" then
            v = math.floor(util.linlin(0,1,0,127,vel))
            self.device:note_off(note,v,n.ch)
          elseif self.target=="engine" then
            self.engine_off(note,vel,n.ch)
          end
          tabutil.remove(self.active_notes,n)
        end
      end
    }
    
    return pf
  end
}