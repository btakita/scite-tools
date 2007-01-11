--[[
  Mitchell's lua.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Lua "bundle" loader
]]--

Lua = {}
if type(keys) == 'table' then keys[SCLEX_LUA] = {} end

require 'lua/snippets'
require 'lua/commands'
