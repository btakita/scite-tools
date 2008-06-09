--[[
  Mitchell's terminal.lua
  Copyright (c) 2006-2008 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- (Linux only) The terminal module.
-- It enables a Linux terminal to be run inside a SciTE buffer.
-- This module requires LuaSocket, utils/shell.rb, and Ara T. Howard's
-- 'session' library for Ruby.
-- The terminal server can be started and stopped with the Ctrl+G and Ctrl+Q
-- key combinations respectively. Pressing Shift+Enter executes the current
-- selection or the contents of the current line in the shell. Pressing Enter
-- by itself behaves as it does normally in SciTE.
module('modules.terminal', package.seeall)

require 'socket'
require 'terminal/commands'

---
-- SciTE OnClear Lua extension function.
-- Checks to see whether a terminal session is currently open. If so, close it
-- because the Lua environment gets cleared and re-initialized everytime
-- buffers are switched. OnClear is called to give scripts a chance to clean up
-- after themselves.
function _G.OnClear()
  if modules.terminal.server then
    print('Closing running Terminal process')
    modules.terminal.commands.close()
  end
end
