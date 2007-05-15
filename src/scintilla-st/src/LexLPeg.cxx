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

static WindowID windowID;
static DocumentAccessor *accessor;
static unsigned int startSeg;
static unsigned int maxLength;
static const char * LuaScript = "/usr/share/scite/scripts/lexers/lexer.lua";

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
	lua_close(L);
	L = NULL;
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

bool LoadLexerScript(lua_State *L, const char *languageName) {
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
		lua_pushstring(L, languageName);
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

// argument is opened Lua State (from ScintillaBase.cxx)
// (re)initializes Lua, reads lexer script,
// and loads lexxing style properties
bool InitLua(lua_State *L) {
	if (!L) {
		Platform::DebugPrintf("Lua failed to initialize\n");
		return false;
	}
	lua_atpanic(L, lua_panic);

	// load table and string libraries
	lua_pushcfunction(L, luaopen_base);
	lua_pushstring(L, "");
	lua_call(L, 1, 0);
	lua_pushcfunction(L, luaopen_table);
	lua_pushstring(L, LUA_TABLIBNAME);
	lua_call(L, 1, 0);
	lua_pushcfunction(L, luaopen_string);
	lua_pushstring(L, LUA_STRLIBNAME);
	lua_call(L, 1, 0);
	lua_pushcfunction(L, luaopen_package);
	lua_pushstring(L, LUA_LOADLIBNAME);
	lua_call(L, 1, 0);
	lua_settop(L, 0);
	lua_pushcfunction(L, lua_handle_error); // main error handling function

	return true;
}

static void InitDoc(lua_State *L, const char *languageName, Accessor &styler) {
	DocumentAccessor &da = static_cast<DocumentAccessor &>(styler);
	windowID = da.GetWindow();
	if (InitLua(L) && LoadLexerScript(L, languageName))
		SetupStyling(L);
	return;
}

static void ColouriseDoc(unsigned int startPos, int length, int initStyle, lua_State *L, WordList** /* keywordlists[] */, Accessor &styler) {
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
	if (L) {
		lua_getglobal(L, "RunLexer");
		if (lua_isfunction(L, -1)) {
			lua_pushstring(L, text);
			lua_pcall(L, 1, 0, 1);
		} else {
			lua_pushstring(L, "'RunLexer' function not found");
			lua_handle_error(L);
		}
		accessor->ColourTo(maxLength - 1, initStyle);
		delete []text;
	}
}

static void FoldLPeg(unsigned int startPos, int length, int /* initStyle */, lua_State *L, WordList *[], Accessor &styler) {

}

static const char * const wordListDesc[] = { 0 };

#ifndef USELPEGLEX
LexerModule lmLPeg(SCLEX_LPEG, ColouriseDoc, "llpeg", FoldLPeg, wordListDesc, 7);
#else
LexerModule lmLPeg(SCLEX_LPEG, InitDoc, ColouriseDoc, "llpeg", FoldLPeg, wordListDesc, 7);
LexerModule lmNull(SCLEX_NULL, InitDoc, ColouriseDoc, "null");
#endif
