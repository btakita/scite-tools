--[[
  Mitchell's php/snippets.lua
  Copyright (c) 2006-2008 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Snippets for the php module.
module('modules.php.snippets', package.seeall)

-- Load HTML snippets and commands too.
require 'html/html'

local snippets = _G.snippets[SCLEX_HTML]

snippets.php = "<?php ${0} ?>"
snippets[SCE_HPHP_DEFAULT] = {
  t = "$this->${0}",
  p = "$_POST['${1:item}']${0}",
  g = "$_GET['${1:item}']${0}",
  c = "$_COOKIE['${1:item}']${0}",
  f =
[[function ${1:name}(${2:args}) {
  ${0}
}]]
}
