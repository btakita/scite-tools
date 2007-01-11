--[[
  Mitchell's lua_ext.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Loads libraries
]]--

PLATFORM = 'linux' -- or 'windows'
LUA_PATH = props['SciteDefaultHome']..'/scripts/?.lua'
if _VERSION == 'Lua 5.1' then
  package.path = package.path..';'..LUA_PATH
end

require 'scite/scite' -- load SciTE "bundle"

if PLATFORM == 'windows' then
  -- I don't know how to do this in C++ in windows
  -- thanks to Nathan Robinson for this idea
  function scite.GetClipboardText()
    if not output:CanPaste() then return '' end
    local anchor, pos = output.Anchor, output.CurrentPos
    if pos < anchor then anchor, pos = pos, anchor end
    output:Paste() output.Anchor = anchor
    local txt = output:GetSelText()
    output:Undo()
    output.Anchor, output.CurrentPos = anchor, pos
    return txt
  end
end
