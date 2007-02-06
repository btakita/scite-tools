--[[
  Mitchell's scite/macros.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Provides macro recording and playback for the SciTE 'bundle'
  (custom binary only)

  API (see functions for descriptions):
    - Macros.play( [macro_name] )
    - Macros.save
    - Macros.load
  Note OnMacro is part of the SciTE Lua Extension in custom binary
]]--

local MACRO_FILENAME =
  props['SciteDefaultHome']..'/saved_macros.lua'

Macros = { list = {}, current = {}, recording = false }

-- called whenever a macro notification is received
-- upon macro:startrecord notification, new macro table is
-- initialized and filled as macro:record notifications and
-- messages are received
function OnMacro(cmd, msg)
  if cmd == 'macro:startrecord' then
    Macros.current = {}
    Macros.recording = true
    props['Macro'] = 'Macro Recording'
    scite.UpdateStatusBar()
  elseif cmd == 'macro:record' then
    table.insert(Macros.current, msg)
  elseif cmd == 'macro:stoprecord' then
    if Macros.recording then
      local macro_name = inputdialog('Save Macro', 'Macro Name:')
      if macro_name and macro_name ~= '' then
        Macros.list[macro_name] = Macros.current
        Macros.save()
      end
      Macros.recording = false
      props['Macro'] = ''
      scite.UpdateStatusBar()
    end
  end
end

-- displays a completion dialog of currently stored macros
-- and runs the selected macro or macro passed as parameter
function Macros.play(...)
  local macro
  if not arg[1] then
    macro = CDialog.choose_key(Macros.list, 'Macros', true)
  else
    macro = Macros.list[ arg[1] ]
  end
  if macro then
    macro = Macros.list[macro]
    for _, msg in ipairs(macro) do
      local _, _, cmd, arg1, arg2 =
        string.find(msg, '(.-);(.-);(.-);')
      scite.SendEditor(cmd, arg1, arg2)
    end
  end
end

-- save recorded macros to file
function Macros.save()
  local f = assert( io.open(MACRO_FILENAME, 'w') )
  for name, macro in pairs(Macros.list) do
    f:write(name, '\n')
    for _, cmd in ipairs(macro) do f:write(cmd, '\n') end
    f:write('\n')
  end
  f:close()
end

-- loads recorded macros from file
function Macros.load()
  local f = io.open(MACRO_FILENAME, 'r')
  if f then
    local name, current_macro
    for line in f:lines() do
      if not name then -- new macro
        name = line
        current_macro = {}
      else
        if line == '' then -- finished, save current macro
          Macros.list[name] = current_macro
          name = nil
        else
          table.insert(current_macro, line)
        end
      end
    end
    f:close()
  end
end

Macros.load() -- load saved macros
