--[[
  Mitchell's html.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- The html module.
-- It provides utilities for editing HTML.
module('modules.html', package.seeall)

if type(keys) == 'table' then
  ---
  -- Container for HTML-specific key commands.
  -- @class table
  -- @name keys.html
  keys[SCLEX_HTML] = {}
end

require 'html/snippets'
require 'html/commands'
