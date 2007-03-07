--[[
  Mitchell's php.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  PHP "bundle" loader
]]--

PHP = {}
if type(keys) == 'table' then keys[SCLEX_HTML] = {} end

require 'php/snippets'
require 'php/commands'
