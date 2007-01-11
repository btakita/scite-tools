--[[
  Mitchell's php/snippets.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Snippets for the PHP "bundle"
]]--

-- load HTML snippets too
dofile( props['SciteDefaultHome']..'/scripts/html/html.lua' )

snippets.none.php = "<?php ${0} ?>"
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
