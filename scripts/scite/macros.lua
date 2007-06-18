--[[
  Mitchell's scite/macros.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- (Linux only) Macro recording and playback for the scite module.
-- This module requires utils/completion.rb.
-- There is one option variable used:
--   MACRO_FILENAME: The location of the file to save and load
--     macros from.
module('modules.scite.macros', package.seeall)

local MACRO_FILENAME =
  props['SciteDefaultHome']..'/saved_macros.lua'

---
-- [Local table] All available macros indexed by name.
-- @class table
-- @name list
local list = {}

---
-- [Local table] The current macro being recorded.
-- Contains an ordered list of actions.
-- @class table
-- @name list
local current = {}

local recording = false

---
-- SciTE OnMacro Lua extension function.
-- It is called whenever a macro notification is received.
-- If a macro:startrecord notification is received, a new macro
-- table is created and filled as macro:record notifications and
-- messages are received. When macro:stoprecord is received,
-- an inputdialog is displayed prompting a name for the recorded
-- macro. The macro is then saved to MACRO_FILENAME.
function _G.OnMacro(cmd, msg)
  if cmd == 'macro:startrecord' then
    current = {}
    recording = true
    props['Macro'] = 'Macro Recording'
    scite.UpdateStatusBar()
  elseif cmd == 'macro:record' then
    table.insert(current, msg)
  elseif cmd == 'macro:stoprecord' then
    if recording then
      local macro_name = inputdialog('Save Macro', 'Macro Name:')
      if macro_name and macro_name ~= '' then
        list[macro_name] = current
        save()
      end
      recording = false
      props['Macro'] = ''
      scite.UpdateStatusBar()
    end
  end
end

---
-- Runs the specified macro.
-- @param macro_name Optional name of a macro to play. If this is
--   not specified, a completion dialog of currently stored macros
--   is displayed for user selection.
function play(macro_name)
  local macro
  if not macro_name then
    macro = CDialog.choose_key(list, 'Macros', true)
  else
    macro = list[macro_name]
  end
  if macro then
    macro = list[macro]
    for _, msg in ipairs(macro) do
      local _, _, cmd, arg1, arg2 =
        string.find(msg, '(.-);(.-);(.-);')
      scite.SendEditor(cmd, arg1, arg2)
    end
  end
end

---
-- Save recorded macros to MACRO_FILENAME.
function save()
  local f = assert( io.open(MACRO_FILENAME, 'w') )
  for name, macro in pairs(list) do
    f:write(name, '\n')
    for _, cmd in ipairs(macro) do f:write(cmd, '\n') end
    f:write('\n')
  end
  f:close()
end

---
-- Load recorded macros from MACRO_FILENAME.
function load()
  local f = io.open(MACRO_FILENAME, 'r')
  if f then
    local name, current_macro
    for line in f:lines() do
      if not name then -- new macro
        name = line
        current_macro = {}
      else
        if line == '' then -- finished, save current macro
          list[name] = current_macro
          name = nil
        else
          table.insert(current_macro, line)
        end
      end
    end
    f:close()
  end
end

load() -- load saved macros
