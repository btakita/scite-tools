--[[
  Mitchell's lua.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- The lua module.
-- It provides utilities for editing Lua code.
module('modules.lua', package.seeall)

if type(keys) == 'table' then
  ---
  -- Container for Lua-specific key commands.
  -- @class table
  -- @name keys.lua
  keys[SCLEX_LUA] = {}
end

require 'lua/snippets'
require 'lua/commands'
