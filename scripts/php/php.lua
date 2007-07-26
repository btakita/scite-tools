--[[
  Mitchell's php.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- The php module.
-- It provides utilities for editing PHP code.
module('modules.php', package.seeall)

if type(_G.snippets) == 'table' then
  ---
  -- Container for PHP-specific key commands.
  -- @class table
  -- @name snippets.php
  _G.snippets[SCLEX_HTML] = {}
end

if type(_G.keys) == 'table' then
  ---
  -- Container for PHP-specific key commands.
  -- @class table
  -- @name keys.php
  _G.keys[SCLEX_HTML] = {}
end

require 'php/snippets'
require 'php/commands'
