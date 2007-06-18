--[[
  Mitchell's extension.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Loads libraries
]]--

PLATFORM = 'linux' -- or 'windows'
LUA_PATH = props['SciteDefaultHome']..'/scripts/?.lua'
package.path  = package.path..';'..LUA_PATH
package.path  = string.gsub(package.path, 'local/', '')
package.cpath = string.gsub(package.cpath, 'local/', '')

require 'scite/scite' -- load scite module

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
