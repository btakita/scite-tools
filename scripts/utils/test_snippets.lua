-- Test suite for snippets.lua

local snippets = _G.snippets
snippets.tabs = "${3:three} ${1:one} ${2:two}"
snippets.etabs = "${2:one ${1:two} ${3:three}} ${4:four}"
snippets.mirrors = "${1:one} ${2:two} ${1} ${2}"
snippets.rmirrors = "${1:one} ${1/one/two/}"
snippets.rgroups = [[Ordered pair: ${1:(2, 8)} so ${1/(\d), (\d)/x = $1, y = $2/}]]
snippets.trans = "${1:one} ${1/o(ne)?/O$1/}"
snippets.scivar = "$(FilePath)"
snippets.esc = "\\${1:fake one} ${1:real one} {${2:\\} two}"
snippets.eruby = "${1:one} ${1/.+/#{$0.capitalize}/}"

function test_snippets()
  local editor = _G.editor
  local Snippets = modules.scite.snippets

  -- Tab stops
  editor:ClearAll()
  print('testing tab stops')
  editor:AddText("tabs"); Snippets.insert()
  assert( editor:GetSelText() == "one" )
  Snippets.next_item()
  assert( editor:GetSelText() == "two" )
  Snippets.next_item()
  assert( editor:GetSelText() == "three" )
  Snippets.next_item()
  assert( editor:GetText() == "three one two" )
  print('tab stops passed')

  -- Embedded tab stops
  editor:ClearAll()
  print('testing embedded tab stops')
  editor:AddText('etabs'); Snippets.insert()
  assert( editor:GetSelText() == 'two')
  Snippets.next_item()
  assert( editor:GetSelText() == 'one two ${3:three}' )
  Snippets.next_item()
  assert( editor:GetSelText() == 'three' )
  Snippets.next_item(); Snippets.next_item()
  assert( editor:GetText() == 'one two three four' )
  print('embedded tabs passed')

  -- Mirrors
  editor:ClearAll()
  print('testing mirrors')
  editor:AddText('mirrors'); Snippets.insert()
  Snippets.next_item()
  assert( editor:GetText() == 'one two one ${2}\n')
  editor:DeleteBack(); editor:AddText('three')
  Snippets.next_item()
  assert( editor:GetText() == 'one three one three' )
  print('mirrors passed')

  -- Regex Mirrors
  editor:ClearAll()
  print('testing regex mirrors')
  editor:AddText('rmirrors'); Snippets.insert()
  Snippets.next_item()
  assert( editor:GetText() == 'one two' )
  editor:ClearAll()
  editor:AddText('rmirrors'); Snippets.insert()
  editor:DeleteBack(); editor:AddText('two')
  Snippets.next_item()
  assert( editor:GetText() == 'two ' )
  print('regex mirrors passed')

  -- Regex Groups
  editor:ClearAll()
  print('testing regex groups')
  editor:AddText('rgroups'); Snippets.insert()
  Snippets.next_item()
  assert( editor:GetText() == 'Ordered pair: (2, 8) so x = 2, y = 8' )
  editor:ClearAll()
  editor:AddText('rgroups'); Snippets.insert()
  editor:DeleteBack(); editor:AddText('[5, 9]')
  Snippets.next_item()
  assert( editor:GetText() == 'Ordered pair: [5, 9] so x = 5, y = 9' )
  print('regex groups passed')

  -- Transformations
  editor:ClearAll()
  print('testing transformations')
  editor:AddText('trans'); Snippets.insert()
  Snippets.next_item()
  assert( editor:GetText() == 'one One' )
  editor:ClearAll()
  editor:AddText('trans'); Snippets.insert()
  editor:DeleteBack(); editor:AddText('once')
  Snippets.next_item()
  assert( editor:GetText() == 'once O' )
  print('transformations passed')

  -- SciTE variables
  editor:ClearAll()
  print('testing scite variables')
  editor:AddText('scivar'); Snippets.insert()
  assert( editor:GetText() == props['FilePath'] )
  print('scite variables passed')

  -- Escapes
  editor:ClearAll()
  print('testing escapes')
  editor:AddText('esc'); Snippets.insert()
  assert( editor:GetSelText() == 'real one' )
  Snippets.next_item()
  assert( editor:GetSelText() == '\\} two' )
  Snippets.next_item()
  assert( editor:GetText() == '${1:fake one} real one {} two' )
  print('escapes passed')

  -- Embeded Ruby
  editor:ClearAll()
  print('testing embedded ruby')
  editor:AddText('eruby'); Snippets.insert()
  Snippets.next_item()
  assert( editor:GetText() == 'one One' )
  editor:ClearAll()
  editor:AddText('eruby'); Snippets.insert()
  editor:DeleteBack(); editor:AddText('two')
  Snippets.next_item()
  assert( editor:GetText() == 'two Two' )
  print('embedded ruby passed')


  print('snippet tests passed')

end

scite.Open('')
test_snippets()
