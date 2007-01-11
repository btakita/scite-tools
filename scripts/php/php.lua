--[[
  Mitchell's php.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  PHP "bundle" loader
]]--

PHP = {}
if type(keys) == 'table' then keys[SCLEX_HTML] = {} end

require 'php/snippets'
require 'php/commands'
