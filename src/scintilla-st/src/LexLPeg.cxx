/*
	Mitchell's Lua-powered lexer

	API:
		StyleTo(position, style)
		GetProperty(property, defaultVal=0)
*/

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "Platform.h"

#include "PropSet.h"
#include "Accessor.h"
#include "DocumentAccessor.h"
#include "KeyWords.h"
#include "Scintilla.h"
#include "SciLexer.h"

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#define eq(s1, s2) (strcasecmp((s1), (s2)) == 0)

static lua_State *luaState = NULL;
static WindowID windowID;
static DocumentAccessor *accessor;
static unsigned int startSeg;
static unsigned int maxLength;
static const char * LuaScript = "/usr/share/scite/scripts/lexers/lexer.lua";

static const char * lexers[] = {
	"container",
	"null",
	"python",
	"cpp",
	"html",
	"xml",
	"perl",
	"sql",
	"vb",
	"props",
	"errorlist", // 10
	"makefile",
	"batch",
	"xcode",
	"latex",
	"lua",
	"diff",
	"conf",
	"pascal",
	"ave",
	"ada", // 20
	"lisp",
	"ruby",
	"eiffel",
	"eiffelkw",
	"tcl",
	"nncrontab",
	"bullant",
	"vbscript",
	"asp",
	"php", // 30
	"baan",
	"matlab",
	"scriptol",
	"asm",
	"cppnocase",
	"fortran",
	"f77",
	"css",
	"pov",
	"lout", // 40
	"escript",
	"ps",
	"nsis",
	"mmixal",
	"clarion",
	"clarionnocase",
	"lot",
	"yaml",
	"tex",
	"metapost", // 50
	"powerbasic",
	"forth",
	"erlang",
	"octave",
	"mssql",
	"verilog",
	"kix",
	"gui4cli",
	"specman",
	"au3", // 60
	"apdl",
	"bash",
	"asn1",
	"vhdl",
	"caml",
	"blitzbasic",
	"purebasic",
	"haskell",
	"phpscript",
	"tads3", // 70
	"rebol",
	"smalltalk",
	"flagship",
	"csound",
	"freebasic",
	"innosetup",
	"opal",
	"spice",
	"d",
	"cmake", // 80
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"", // 90
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"llpeg", // 99
	0
};

//~ static int lua_send_scintilla(lua_State *L) {
	//~ unsigned int msg = static_cast<unsigned int>(luaL_checkinteger(L, -3));
	//~ unsigned long wParam = static_cast<unsigned long>(luaL_checklong(L, -2));
	//~ long lParam = luaL_checklong(L, -1);
	//~ long retVal = Platform::SendScintilla(windowID, msg, wParam, lParam);
	//~ lua_pushnumber(L, retVal);
	//~ return 1;
//~ }

// prints an error message residing at
// the top of the  stack and pops it off
static int lua_handle_error(lua_State *L) {
	const char *errmsg = lua_tostring(L, -1);
	Platform::DebugPrintf("Lua Error: %s\n", errmsg);
	lua_pop(L, 1);
	return 0;
}

// if something goes horribly wrong...
static int lua_panic(lua_State *L) {
	lua_handle_error(L);
	if (L == luaState)
		lua_close(L);
	luaState = NULL;
	return 0;
}

// sets styling up to a position
// e.g. StyleTo(pos, style)
static int lua_style_to(lua_State *L) {
	unsigned int position = luaL_checkinteger(L, -2) - 1;
	int style = luaL_checkinteger(L, -1);
	if (style >= 0 && style <= STYLE_MAX) {
		if (position > startSeg && position - 1 < maxLength)
			accessor->ColourTo(position - 1, style);
	} else {
		lua_pushstring(L, "Bad style number");
		lua_handle_error(L);
	}
	return 0;
}

// returns property value
// e.g. GetProperty('fold')
static int lua_get_property(lua_State *L) {
	const char *property;
	int defaultValue;
	if (lua_gettop(L) > 1) {
		property = lua_tostring(L, -2);
		defaultValue = luaL_checkinteger(L, -1);
	} else if (lua_gettop(L) == 0) {
		property = lua_tostring(L, -1);
		defaultValue = 0;
	} else {
		lua_pushstring(L, "Too many arguments to GetProperty; 1 or 2 expected");
		lua_handle_error(L);
		return 0;
	}
	lua_pushnumber(L, accessor->GetPropertyInt(property, defaultValue));
	return 1;
}

bool LoadLexerScript(lua_State *L) {
	// read script
	if (luaL_loadfile(L, LuaScript) == 0) {
		if (lua_pcall(L, 0, 0, 1) != 0)
			return false;
	} else {
		lua_handle_error(L);
		return false;
	}

	// load the lexer and style properties
	lua_getglobal(L, "InitLexer");
	if (lua_isfunction(L, -1)) {
		int lexerNum = Platform::SendScintilla(windowID, SCI_GETLEXER);
		lua_pushstring(L, lexers[lexerNum]);
		if (lua_pcall(L, 1, 0, 1) != 0)
			return false;
	} else {
		lua_pushstring(L, "'InitLexer' function not found");
		lua_handle_error(L);
		return false;
	}

	// register the two most important functions
	lua_register(L, "StyleTo", lua_style_to);
	lua_register(L, "GetProperty", lua_get_property);
	return true;
}

bool SetupStyling(lua_State *L) {
	// reset to default states
	Platform::SendScintilla(windowID, SCI_STYLECLEARALL);

	// register properties (case insensitive)
	// eg:
	// styles = {
	//   [1] = { Fore = color, Back = color, ... }
	//   [2] = { EOLFilled = true, ... }
	// }
	lua_getglobal(L, "Lexer");
	if (lua_istable(L, -1)) {
		lua_getfield(L, -1, "Styles");
		if (lua_istable(L, -1)) {
			int styles_index = lua_gettop(L);
			lua_pushnil(L);
			while (lua_next(L, styles_index) != 0) { // styles table
				if (lua_isnumber(L, -2) && lua_istable(L, -1)) {
					int style_num = luaL_checkinteger(L, -2); // [num] = { properties }
					int props_index = lua_gettop(L);
					lua_pushnil(L);
					while (lua_next(L, props_index)) { // properties table
						const char *prop = lua_tostring(L, -2);
						if (eq(prop, "font"))
							Platform::SendScintillaPointer(windowID, SCI_STYLESETFONT, style_num, const_cast<char *>(lua_tostring(L, -1)));
						else if (eq(prop, "size"))
							Platform::SendScintilla(windowID, SCI_STYLESETSIZE, style_num, (int) lua_tointeger(L, -1));
						else if (eq(prop, "bold"))
							Platform::SendScintilla(windowID, SCI_STYLESETBOLD, style_num, lua_toboolean(L, -1));
						else if (eq(prop, "italic"))
							Platform::SendScintilla(windowID, SCI_STYLESETITALIC, style_num, lua_toboolean(L, -1));
						else if (eq(prop, "underline"))
							Platform::SendScintilla(windowID, SCI_STYLESETUNDERLINE, style_num, lua_toboolean(L, -1));
						else if (eq(prop, "fore"))
							Platform::SendScintilla(windowID, SCI_STYLESETFORE, style_num, (int) lua_tointeger(L, -1));
						else if (eq(prop, "back"))
							Platform::SendScintilla(windowID, SCI_STYLESETBACK, style_num, (int) lua_tointeger(L, -1));
						else if (eq(prop, "eolfilled"))
							Platform::SendScintilla(windowID, SCI_STYLESETEOLFILLED, style_num, lua_toboolean(L, -1));
						else if (eq(prop, "characterset"))
							Platform::SendScintilla(windowID, SCI_STYLESETCHARACTERSET, style_num, (int) lua_tointeger(L, -1));
						else if (eq(prop, "case"))
							Platform::SendScintilla(windowID, SCI_STYLESETCASE, style_num, (int) lua_tointeger(L, -1));
						else if (eq(prop, "visible"))
							Platform::SendScintilla(windowID, SCI_STYLESETVISIBLE, style_num, lua_toboolean(L, -1));
						else if (eq(prop, "changeable"))
							Platform::SendScintilla(windowID, SCI_STYLESETCHANGEABLE, style_num, lua_toboolean(L, -1));
						else if (eq(prop, "hotspot"))
							Platform::SendScintilla(windowID, SCI_STYLESETHOTSPOT, style_num, lua_toboolean(L, -1));
						lua_pop(L, 1);
					} // end properties table iteration
				}
				lua_pop(L, 1);
			} // end styles table iteration
		} else {
			lua_pushstring(L, "'Lexer.Styles' table not found");
			lua_handle_error(L);
			return false;
		}
	} else {
		lua_pushstring(L, "'Lexer' table not found");
		lua_handle_error(L);
		return false;
	}
	return true;
}

// initializes Lua if it hasn't been already, reads
// lexer script, and loads lexing style properties
bool InitLua() {
	if (!luaState) {
		luaState = lua_open();
		if (!luaState) {
			Platform::DebugPrintf("Lua failed to initialize\n");
			return false;
		}
		lua_atpanic(luaState, lua_panic);

		// load table and string libraries
		lua_pushcfunction(luaState, luaopen_base);
		lua_pushstring(luaState, "");
		lua_call(luaState, 1, 0);
		lua_pushcfunction(luaState, luaopen_table);
		lua_pushstring(luaState, LUA_TABLIBNAME);
		lua_call(luaState, 1, 0);
		lua_pushcfunction(luaState, luaopen_string);
		lua_pushstring(luaState, LUA_STRLIBNAME);
		lua_call(luaState, 1, 0);
		lua_pushcfunction(luaState, luaopen_package);
		lua_pushstring(luaState, LUA_LOADLIBNAME);
		lua_call(luaState, 1, 0);
	}
	lua_settop(luaState, 0);
	lua_pushcfunction(luaState, lua_handle_error); // main error handling function

	return LoadLexerScript(luaState);
}

//~ void lua_close() {
	//~ if (luaState != NULL)
		//~ lua_close(luaState);
	//~ luaState = NULL;
//~ }

static void InitDoc(Accessor &styler) {
	DocumentAccessor &da = static_cast<DocumentAccessor &>(styler);
	windowID = da.GetWindow();
	if (InitLua())
		SetupStyling(luaState);
	//~ InitLua();
	return;
}

static void ColouriseDoc(unsigned int startPos, int length, int initStyle, WordList** /* keywordlists[] */, Accessor &styler) {
	DocumentAccessor &da = static_cast<DocumentAccessor &>(styler);
	windowID = da.GetWindow();
	//~ accessor = &styler;
	accessor = &da;

	startSeg = startPos;
	maxLength = startPos + length;

	// get all document text for highlighting
	char *text = new char[da.Length() + 1];
	//~ for (unsigned int i = startPos; i < maxLength; i++)
	//~	text[i - startPos] = styler.SafeGetCharAt(i, ' ');
	//~ text[length] = '\0';
	TextRange tr;
	tr.chrg.cpMin = 0;
	tr.chrg.cpMax = da.Length();
	tr.lpstrText = text;
	Platform::SendScintillaPointer(windowID, SCI_GETTEXTRANGE, 0, &tr);

	accessor->StartAt(startPos);
	accessor->StartSegment(startPos);

	// load lua and initiate the lexxing
	if (luaState && LoadLexerScript(luaState)) {
		lua_getglobal(luaState, "RunLexer");
		if (lua_isfunction(luaState, -1)) {
			lua_pushstring(luaState, text);
			lua_pcall(luaState, 1, 0, 1);
		} else {
			lua_pushstring(luaState, "'RunLexer' function not found");
			lua_handle_error(luaState);
		}
		accessor->ColourTo(maxLength - 1, initStyle);
		delete []text;
		//~ lua_close();
	}
}

static void FoldLPeg(unsigned int startPos, int length, int /* initStyle */, WordList *[], Accessor &styler) {

}

static const char * const wordListDesc[] = { 0 };

#ifndef USELPEGLEX
LexerModule lmLPeg(SCLEX_LPEG, ColouriseDoc, "llpeg", FoldLPeg, wordListDesc, 7);
#else
LexerModule lmLPeg(SCLEX_LPEG, InitDoc, ColouriseDoc, "llpeg", FoldLPeg, wordListDesc, 7);
LexerModule lmAPDL(SCLEX_APDL, InitDoc, ColouriseDoc, "apdl", FoldLPeg, wordListDesc, 7);
LexerModule lmAU3(SCLEX_AU3, InitDoc, ColouriseDoc, "au3", FoldLPeg, wordListDesc, 7);
LexerModule lmAVE(SCLEX_AVE, InitDoc, ColouriseDoc, "ave", FoldLPeg, wordListDesc, 7);
LexerModule lmAda(SCLEX_ADA, InitDoc, ColouriseDoc, "ada", FoldLPeg, wordListDesc, 7);
LexerModule lmAsm(SCLEX_ASM, InitDoc, ColouriseDoc, "asm", FoldLPeg, wordListDesc, 7);
LexerModule lmAns1(SCLEX_ASN1, InitDoc, ColouriseDoc, "asn1", FoldLPeg, wordListDesc, 7);
LexerModule lmBaan(SCLEX_BAAN, InitDoc, ColouriseDoc, "baan", FoldLPeg, wordListDesc, 7);
LexerModule lmBash(SCLEX_BASH, InitDoc, ColouriseDoc, "bash", FoldLPeg, wordListDesc, 7);
LexerModule lmBlitzBasic(SCLEX_BLITZBASIC, InitDoc, ColouriseDoc, "blitzbasic", FoldLPeg, wordListDesc, 7);
LexerModule lmPureBasic(SCLEX_PUREBASIC, InitDoc, ColouriseDoc, "purebasic", FoldLPeg, wordListDesc, 7);
LexerModule lmFreeBasic(SCLEX_FREEBASIC, InitDoc, ColouriseDoc, "freebasic", FoldLPeg, wordListDesc, 7);
LexerModule lmBullant(SCLEX_BULLANT, InitDoc, ColouriseDoc, "bullant", FoldLPeg, wordListDesc, 7);
LexerModule lmClw(SCLEX_CLW, InitDoc, ColouriseDoc, "clarion", FoldLPeg, wordListDesc, 7);
LexerModule lmClwNoCase(SCLEX_CLWNOCASE, InitDoc, ColouriseDoc, "clarionnocase", FoldLPeg, wordListDesc, 7);
LexerModule lmCPP(SCLEX_CPP, InitDoc, ColouriseDoc, "cpp", FoldLPeg, wordListDesc, 7);
LexerModule lmCPPNoCase(SCLEX_CPPNOCASE, InitDoc, ColouriseDoc, "cppnocase", FoldLPeg, wordListDesc, 7);
LexerModule lmCss(SCLEX_CSS, InitDoc, ColouriseDoc, "css", FoldLPeg, wordListDesc, 7);
LexerModule lmCaml(SCLEX_CAML, InitDoc, ColouriseDoc, "caml", FoldLPeg, wordListDesc, 7);
LexerModule lmCmake(SCLEX_CMAKE, InitDoc, ColouriseDoc, "cmake", FoldLPeg, wordListDesc, 7);
LexerModule lmConf(SCLEX_CONF, InitDoc, ColouriseDoc, "conf", FoldLPeg, wordListDesc, 7);
LexerModule lmNncrontab(SCLEX_NNCRONTAB, InitDoc, ColouriseDoc, "nncrontab", FoldLPeg, wordListDesc, 7);
LexerModule lmCsound(SCLEX_CSOUND, InitDoc, ColouriseDoc, "csound", FoldLPeg, wordListDesc, 7);
LexerModule lmD(SCLEX_D, InitDoc, ColouriseDoc, "d", FoldLPeg, wordListDesc, 7);
LexerModule lmESCRIPT(SCLEX_ESCRIPT, InitDoc, ColouriseDoc, "escript", FoldLPeg, wordListDesc, 7);
LexerModule lmEiffel(SCLEX_EIFFEL, InitDoc, ColouriseDoc, "eiffel", FoldLPeg, wordListDesc, 7);
LexerModule lmEiffelkw(SCLEX_EIFFELKW, InitDoc, ColouriseDoc, "eiffelkw", FoldLPeg, wordListDesc, 7);
LexerModule lmErlang(SCLEX_ERLANG, InitDoc, ColouriseDoc, "erlang", FoldLPeg, wordListDesc, 7);
LexerModule lmFlagShip(SCLEX_FLAGSHIP, InitDoc, ColouriseDoc, "flagship", FoldLPeg, wordListDesc, 7);
LexerModule lmForth(SCLEX_FORTH, InitDoc, ColouriseDoc, "forth",FoldLPeg,wordListDesc, 7);
LexerModule lmFortran(SCLEX_FORTRAN, InitDoc, ColouriseDoc, "fortran", FoldLPeg, wordListDesc, 7);
LexerModule lmF77(SCLEX_F77, InitDoc, ColouriseDoc, "f77", FoldLPeg, wordListDesc, 7);
LexerModule lmGui4Cli(SCLEX_GUI4CLI, InitDoc, ColouriseDoc, "gui4cli", FoldLPeg, wordListDesc, 7);
LexerModule lmHTML(SCLEX_HTML, InitDoc, ColouriseDoc, "html", FoldLPeg, wordListDesc, 7);
LexerModule lmXML(SCLEX_XML, InitDoc, ColouriseDoc, "xml", FoldLPeg, wordListDesc, 7);
LexerModule lmASP(SCLEX_ASP, InitDoc, ColouriseDoc, "asp", FoldLPeg, wordListDesc, 7);
LexerModule lmPHP(SCLEX_PHP, InitDoc, ColouriseDoc, "php", FoldLPeg, wordListDesc, 7);
LexerModule lmPHPSCRIPT(SCLEX_PHPSCRIPT, InitDoc, ColouriseDoc, "phpscript", FoldLPeg, wordListDesc, 7);
LexerModule lmHaskell(SCLEX_HASKELL, InitDoc, ColouriseDoc, "haskell");
LexerModule lmInno(SCLEX_INNOSETUP, InitDoc, ColouriseDoc, "inno", FoldLPeg, wordListDesc, 7);
LexerModule lmKix(SCLEX_KIX, InitDoc, ColouriseDoc, "kix");
LexerModule lmLISP(SCLEX_LISP, InitDoc, ColouriseDoc, "lisp", FoldLPeg, wordListDesc, 7);
LexerModule lmLout(SCLEX_LOUT, InitDoc, ColouriseDoc, "lout", FoldLPeg, wordListDesc, 7);
LexerModule lmLua(SCLEX_LUA, InitDoc, ColouriseDoc, "lua", FoldLPeg, wordListDesc, 7);
LexerModule lmMMIXAL(SCLEX_MMIXAL, InitDoc, ColouriseDoc, "mmixal", FoldLPeg, wordListDesc, 7);
LexerModule lmLot(SCLEX_LOT, InitDoc, ColouriseDoc, "lot", FoldLPeg, wordListDesc, 7);
LexerModule lmMSSQL(SCLEX_MSSQL, InitDoc, ColouriseDoc, "mssql", FoldLPeg, wordListDesc, 7);
LexerModule lmMatlab(SCLEX_MATLAB, InitDoc, ColouriseDoc, "matlab", FoldLPeg, wordListDesc, 7);
LexerModule lmOctave(SCLEX_OCTAVE, InitDoc, ColouriseDoc, "octave", FoldLPeg, wordListDesc, 7);
LexerModule lmMETAPOST(SCLEX_METAPOST, InitDoc, ColouriseDoc, "metapost", FoldLPeg, wordListDesc, 7);
LexerModule lmNsis(SCLEX_NSIS, InitDoc, ColouriseDoc, "nsis", FoldLPeg, wordListDesc, 7);
LexerModule lmOpal(SCLEX_OPAL, InitDoc, ColouriseDoc, "opal", FoldLPeg, wordListDesc, 7);
LexerModule lmBatch(SCLEX_BATCH, InitDoc, ColouriseDoc, "batch", FoldLPeg, wordListDesc, 7);
LexerModule lmDiff(SCLEX_DIFF, InitDoc, ColouriseDoc, "diff", FoldLPeg, wordListDesc, 7);
LexerModule lmProps(SCLEX_PROPERTIES, InitDoc, ColouriseDoc, "props", FoldLPeg, wordListDesc, 7);
LexerModule lmMake(SCLEX_MAKEFILE, InitDoc, ColouriseDoc, "makefile", FoldLPeg, wordListDesc, 7);
LexerModule lmErrorList(SCLEX_ERRORLIST, InitDoc, ColouriseDoc, "errorlist", FoldLPeg, wordListDesc, 7);
LexerModule lmLatex(SCLEX_LATEX, InitDoc, ColouriseDoc, "latex", FoldLPeg, wordListDesc, 7);
LexerModule lmNull(SCLEX_NULL, InitDoc, ColouriseDoc, "null");
LexerModule lmPB(SCLEX_POWERBASIC, InitDoc, ColouriseDoc, "powerbasic", FoldLPeg, wordListDesc, 7);
LexerModule lmPOV(SCLEX_POV, InitDoc, ColouriseDoc, "pov", FoldLPeg, wordListDesc, 7);
LexerModule lmPS(SCLEX_PS, InitDoc, ColouriseDoc, "ps", FoldLPeg, wordListDesc, 7);
LexerModule lmPascal(SCLEX_PASCAL, InitDoc, ColouriseDoc, "pascal", FoldLPeg, wordListDesc, 7);
LexerModule lmPerl(SCLEX_PERL, InitDoc, ColouriseDoc, "perl", FoldLPeg, wordListDesc, 7);
LexerModule lmPython(SCLEX_PYTHON, InitDoc, ColouriseDoc, "python", FoldLPeg, wordListDesc, 7);
LexerModule lmREBOL(SCLEX_REBOL, InitDoc, ColouriseDoc, "rebol", FoldLPeg, wordListDesc, 7);
LexerModule lmRuby(SCLEX_RUBY, InitDoc, ColouriseDoc, "ruby", FoldLPeg, wordListDesc, 7);
LexerModule lmSQL(SCLEX_SQL, InitDoc, ColouriseDoc, "sql", FoldLPeg, wordListDesc, 7);
LexerModule lmScriptol(SCLEX_SCRIPTOL, InitDoc, ColouriseDoc, "scriptol", FoldLPeg, wordListDesc, 7);
LexerModule lmSmalltalk(SCLEX_SMALLTALK, InitDoc, ColouriseDoc, "smalltalk", FoldLPeg, wordListDesc, 7);
LexerModule lmSpecman(SCLEX_SPECMAN, InitDoc, ColouriseDoc, "specman", FoldLPeg, wordListDesc, 7);
LexerModule lmSpice(SCLEX_SPICE, InitDoc, ColouriseDoc, "spice", FoldLPeg, wordListDesc, 7);
LexerModule lmTADS3(SCLEX_TADS3, InitDoc, ColouriseDoc, "tads3", FoldLPeg, wordListDesc, 7);
LexerModule lmTCL(SCLEX_TCL, InitDoc, ColouriseDoc, "tcl", FoldLPeg, wordListDesc, 7);
LexerModule lmTeX(SCLEX_TEX, InitDoc, ColouriseDoc, "tex", FoldLPeg, wordListDesc, 7);
LexerModule lmVB(SCLEX_VB, InitDoc, ColouriseDoc, "vb", FoldLPeg, wordListDesc, 7);
LexerModule lmVBScript(SCLEX_VBSCRIPT, InitDoc, ColouriseDoc, "vbscript", FoldLPeg, wordListDesc, 7);
LexerModule lmVHDL(SCLEX_VHDL, InitDoc, ColouriseDoc, "vhdl", FoldLPeg, wordListDesc, 7);
LexerModule lmVerilog(SCLEX_VERILOG, InitDoc, ColouriseDoc, "verilog", FoldLPeg, wordListDesc, 7);
LexerModule lmYAML(SCLEX_YAML, InitDoc, ColouriseDoc, "yaml", FoldLPeg, wordListDesc, 7);
#endif
