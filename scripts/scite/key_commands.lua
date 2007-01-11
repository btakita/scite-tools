--[[
  Mitchell's key_commands.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
  Documentation can be found in scripts/doc/keys_doc.txt

  Defines default key commands for SciTE (via keys.lua, custom
  binary only)

  This file must be in the same directory as keys.lua or
  in LUA_PATH.
]]--

local PLATFORM = PLATFORM or 'linux'
local ALTERNATIVE_KEYS = false

--[[
  Key shortcuts not used, excluding SciTE default shortcuts:

  Excluding ALTERNATIVE_KEYS:
  C:   A B C D E F G H       L M N O P Q R S   U V   X Y Z
  A:   A B C D   F G H   J K L     O   Q R   T U V W X Y Z
  CS:  A B C D E F G     J K L M N O P Q R S     V W X Y Z
  SA:  A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
  CA:  A B C D     G H   J K L M N O P Q R S T U V W X Y Z
  CSA: A B C D E F G H   J K L M N O P Q R S T U V W X Y Z

  Including ALTERNATIVE_KEYS:
  C:
  A:   A   C       G     J K L     O   Q R   T     W X   Z
  CS:      C D           J   L           R S   U   W
  SA:  A   C D E   G H I J K L M N O P Q R S T     W X   Z
  CA:  A B C D     G H   J K L M   O   Q R S T U V W X Y Z
  CSA:     C D     G H   J K L M   O   Q R S T U   W X   Z
]]--

-- Note: keys has been previously defined in keys.lua

keys.clear_sequence   = 'esc'  -- clear a current key sequence
keys.show_completions = 'sesc' -- show possible completions

-- quickies
keys['c0'] = { 1100 }
keys['c1'] = { 1101 }
keys['c2'] = { 1102 }
keys['c3'] = { 1103 }
keys['c4'] = { 1104 }
keys['c5'] = { 1105 }
keys['c6'] = { 1106 }
keys['c7'] = { 1107 }
keys['c8'] = { 1108 }
keys['c9'] = { 1109 }

-- open modules
keys['ca1'] = { 1110 }
keys['ca2'] = { 1111 }
keys['ca3'] = { 1112 }
keys['ca4'] = { 1113 }
keys['ca5'] = { 1114 }
keys['ca6'] = { 1115 }
keys['ca7'] = { 1116 }
keys['ca8'] = { 1117 }
keys['ca9'] = { 1118 }
keys['ca0'] = { 1119 }

-- macros
-- snippets
keys.ci   = { Snippets.insert           }
keys.csi  = { Snippets.cancel_current   }
keys.cai  = { Snippets.list             }
keys.csai = { Snippets.insert_temporary }
keys.ai   = { Snippets.show_scope       }
-- keys.? = { 1120 }, -- create snippets

-- editing...
keys.ck  = { Editing.smart_cutcopy, 'cut'   }
keys.csk = { Editing.smart_cutcopy, 'copy'  }
keys.cu  = { Editing.smart_paste,           }
keys.au  = { Editing.smart_paste, 'cycle'   }
keys.sau = { Editing.smart_paste, 'reverse' }
keys.cw  = { Editing.current_word, 'delete' }
keys.ct  = { Editing.transpose_chars        }
keys.csh = { Editing.squeeze,               }
keys.cj  = { Editing.join_lines             }
keys.ap  = { Editing.move_line, 'up'        }
keys.an  = { Editing.move_line, 'down'      }

-- code execution
keys.cae = {
  r = { Editing.ruby_exec },
  l = { Editing.lua_exec  }
}

-- enclose in...
keys.ae = {
  t      = { Editing.enclose, 'tag'        },
  st     = { Editing.enclose, 'single_tag' },
  ['s"'] = { Editing.enclose, 'dbl_quotes' },
  ["'"]  = { Editing.enclose, 'sng_quotes' },
  ['(']  = { Editing.enclose, 'parens'     },
  ['[']  = { Editing.enclose, 'brackets'   },
  ['{']  = { Editing.enclose, 'braces'     },
  c      = { Editing.enclose, 'chars'      },
}

-- select in...
keys.as = {
  e      = { Editing.select_enclosed               },
  t      = { Editing.select_enclosed, 'tags'       },
  ['s"'] = { Editing.select_enclosed, 'dbl_quotes' },
  ["'"]  = { Editing.select_enclosed, 'sng_quotes' },
  ['(']  = { Editing.select_enclosed, 'parens'     },
  ['[']  = { Editing.select_enclosed, 'brackets'   },
  ['{']  = { Editing.select_enclosed, 'braces'     },
  w      = { Editing.current_word,    'select'     },
  l      = { Editing.select_line                   },
  p      = { Editing.select_paragraph              },
  i      = { Editing.select_indented_block         },
  s      = { Editing.select_scope                  },
}

-- multiple lines...
keys.am = {
  a  = { MLines.add          },
  sa = { MLines.add_multiple },
  u  = { MLines.update       },
  c  = { MLines.clear        },
}

-- file management...
keys.caf = {
  c = { FileBrowser.create            },
  o = { FileBrowser.action            },
  d = { FileBrowser.show_file_details },
}

-- etc...
keys['c\n'] = { function() editor:LineEnd() editor:NewLine() end }

if ALTERNATIVE_KEYS then
  -- navigation
  keys.cf  = { editor.CharRight,       editor }
  keys.csf = { editor.CharRightExtend, editor }
  keys.af  = { editor.WordRight,       editor }
  keys.saf = { editor.WordRightExtend, editor }
  keys.cb  = { editor.CharLeft,        editor }
  keys.csb = { editor.CharLeftExtend,  editor }
  keys.ab  = { editor.WordLeft,        editor }
  keys.sab = { editor.WordLeftExtend,  editor }
  keys.cn  = { editor.LineDown,        editor }
  keys.csn = { editor.LineDownExtend,  editor }
  keys.cp  = { editor.LineUp,          editor }
  keys.csp = { editor.LineUpExtend,    editor }
  keys.ca  = { editor.VCHome,          editor }
  keys.csa = { editor.HomeExtend,      editor }
  keys.ce  = { editor.LineEnd,         editor }
  keys.cse = { editor.LineEndExtend,   editor }
  keys.cv  = { editor.PageDown,        editor }
  keys.csv = { editor.PageDownExtend,  editor }
  keys.av  = { editor.ParaDown,        editor }
  keys.sav = { editor.ParaDownExtend,  editor }
  keys.cy  = { editor.PageUp,          editor }
  keys.csy = { editor.PageUpExtend,    editor }
  keys.ay  = { editor.ParaUp,          editor }
  keys.say = { editor.ParaUpExtend,    editor }
  keys.ch  = { editor.DeleteBack,      editor }
  keys.ah  = { editor.DelWordLeft,     editor }
  keys.cd  = { editor.Clear,           editor }
  keys.ad  = { editor.DelWordRight,    editor }

  keys.csaf = { editor.CharRightRectExtend, editor }
  keys.csab = { editor.CharLeftRectExtend,  editor }
  keys.csan = { editor.LineDownRectExtend,  editor }
  keys.csap = { editor.LineUpRectExtend,    editor }
  keys.csaa = { editor.VCHomeRectExtend,    editor }
  keys.csae = { editor.LineEndRectExtend,   editor }
  keys.csav = { editor.PageDownRectExtend,  editor }
  keys.csay = { editor.PageUpRectExtend,    editor }

  keys.cc   = {} -- command chain
  keys.cc.b = {} -- bookmark chain
  keys.cc.e = {} -- editing chain
  keys.cc.f = {} -- folding chain
  keys.cc.s = {} -- session chain
  keys.cc.v = {} -- view chain
  keys.cs   = {} -- search chain
  -- menu commands
  keys.cc.n   = { 101 } -- new
  keys.cr     = { 102 } -- open
  keys.cx     = { 105 } -- close
  keys.co     = { 106 } -- save
  keys.cso    = { 110 } -- save as
  keys.cc.s.l = { 132 } -- load session
  keys.cc.s.s = { 133 } -- save session
  keys.csq    = { 140 } -- quit
  keys.cz     = { 201 } -- undo
  keys.csz    = { 202 } -- redo
  keys['del'] = { 206 } -- delete
  keys.as.a   = { 207 } -- select all
  keys.cs.s   = { 210 } -- find
  keys.cs.n   = { 211 } -- find next
  keys.cs.p   = { 212 } -- find previous
  keys.cs.f   = { 215 } -- find in files
  keys.cs.r   = { 216 } -- replace
  keys.cl     = { 220 } -- goto line
  keys.cc.b.n = { 221 } -- next bookmark
  keys.cc.b.a = { 222 } -- toggle bookmark (add)
  keys.cc.b.d = { 222 } -- toggle bookmark (delete)
  keys.cc.b.p = { 223 } -- prev bookmark
  keys.cc.b.c = { 224 } -- clear bookmarks
  keys.cm     = { 230 } -- match brace
  keys.csm    = { 231 } -- select to matching brace
  keys.cc.s.c = { 232 } -- show calltip
  keys['a ']  = { 233 } -- complete symbol
  keys['c ']  = { 234 } -- complete word
  keys.cc.f.a = { 236 } -- toggle fold all
  keys.cc.f.f = { 237 } -- toggle fold (fold)
  keys.cc.f.u = { 237 } -- toggle fold (unfold)
  keys.cc.e.u = { 240 } -- uppercase
  keys.cc.e.l = { 241 } -- lowercase
  keys.cc.e.d = { 250 } -- duplicate
  keys.cs.i   = { 252 } -- incremental search
  --keys.cc   = { 301 } -- compile
  --keys.csc  = { 302 } -- make
  keys.cg     = { 303 } -- go
  keys.csg    = { 304 } -- stop execute
  keys.cc.v.e = { 403 } -- toggle view EOL
  keys.cc.v.o = { 409 } -- toggle view output
  keys.cc.v.p = { 412 } -- view params
  keys.cc.v.w = { 414 } -- toggle wrap
  keys.cc.v.c = { 420 } -- clear output
  keys.cc.v.s = { 421 } -- switch pane
  keys.cc.v.t = { 440 } -- tabsize
  keys.cal    = { 464 } -- lua startup script
  keys.cap    = { 501 } -- prev file
  keys.can    = { 502 } -- next file
  keys.csx    = { 503 } -- close all files
end

if PLATFORM == 'linux' then
  if ALTERNATIVE_KEYS then
    if not keys.cc then keys.cc = { e = {} } end
    keys.cc.e.r = { Editing.reformat_paragraph }
    keys.cc.e.f = { FilterThrough.filter       }
    keys.am.r   = { 311 } -- macro start record
    keys.am.s   = { 312 } -- macro stop record
    keys.am.p   = { Macros.play }
  end
  -- keys['c;']  = { CDialog.get_command   }
  keys['c\t'] = { CDialog.switch_buffer }
end
