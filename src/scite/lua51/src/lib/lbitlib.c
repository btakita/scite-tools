/* Bitwise operations library */
/* Reuben Thomas   nov00-09jan04 */


/* README
 *                           bitlib release 17
 *                           -----------------
 * 
 *                    by Reuben Thomas (rrt@sc3d.org)
 * 
 * 
 * bitlib is a C library for Lua 5.0 that provides bitwise operations.
 * It is copyright Reuben Thomas 2000-2003, and is released under the
 * MIT license, like Lua (see http://www.lua.org/copyright.html for the
 * full license; it's basically the same as the BSD license). There is no
 * warranty.
 * 
 * Please report bugs and make suggestions to the email address above.
 * 
 * Thanks to John Passaniti for his bitwise operations library, some of
 * whose ideas I used, and to Thatcher Ulrich for portability fixes.
 * 
 * 
 * Installation
 * ------------
 * 
 * There is no header file.  The initialisation function is luaopen_bit.
 * Declare the function as extern int luaopen_bit(lua_State *L).
 *
 * 
 * Use
 * ---
 * 
 * Lua functions provided:
 * 
 * bit.bnot(a)       returns the one's complement of a
 * bit.band(w1,...)  returns the bitwise and of the w's
 * bit.bor(w1,...)   returns the bitwise or of the w's
 * bit.bxor(w1,...)  returns the bitwise exclusive or of the w's
 * bit.lshift(a,b)   returns a shifted left b places
 * bit.rshift(a,b)   returns a shifted logically right b places
 * bit.arshift(a,b)  returns a shifted arithmetically right b places
 * bit.mod(a,b)      returns the integer remainder of a divided by b
 * 
 * All function arguments should be integers. The number of bits
 * available for logical operations depends on the data type used to
 * represent Lua numbers; this is typically 8-byte IEEE floats, which
 * give 53 bits (the size of the mantissa).
 * 
 * The logical operations start with "b" for "bit" to avoid clashing with
 * reserved words; although "xor" isn't a reserved word, it seemed better
 * to use "bxor" for consistency.
 */

#define LUA_LIB

#include "lauxlib.h"
#include "lua.h"

typedef long long Integer;
typedef unsigned long long UInteger;

#define luaL_checkbit(L, n)  ((Integer)luaL_checknumber(L, n))
#define luaL_checkubit(L, n) ((UInteger)luaL_checkbit(L, n))

#define TDYADIC(name, op, checkbit1, checkbit2) \
  static int bit_ ## name(lua_State* L) { \
    lua_pushnumber(L, \
      (lua_Number)(checkbit1(L, 1) op checkbit2(L, 2))); \
    return 1; \
  }

#define DYADIC(name, op) \
  TDYADIC(name, op, luaL_checkbit, luaL_checkbit)

#define MONADIC(name, op) \
  static int bit_ ## name(lua_State* L) { \
    lua_pushnumber(L, (lua_Number)(op luaL_checkbit(L, 1))); \
    return 1; \
  }

#define VARIADIC(name, op) \
  static int bit_ ## name(lua_State *L) { \
    int n = lua_gettop(L), i; \
    Integer w = luaL_checkbit(L, 1); \
    for (i = 2; i <= n; i++) \
      w op luaL_checkbit(L, i); \
    lua_pushnumber(L, (lua_Number)(w)); \
    return 1; \
  }

MONADIC(bnot,     ~)
VARIADIC(band,    &=)
VARIADIC(bor,     |=)
VARIADIC(bxor,    ^=)
TDYADIC(lshift,  <<, luaL_checkbit, luaL_checkubit)
TDYADIC(rshift,  >>, luaL_checkubit, luaL_checkubit)
TDYADIC(arshift, >>, luaL_checkbit, luaL_checkubit)
DYADIC(mod,      %)

static const struct luaL_reg bitlib[] = {
  {"bnot",    bit_bnot},
  {"band",    bit_band},
  {"bor",     bit_bor},
  {"bxor",    bit_bxor},
  {"lshift",  bit_lshift},
  {"rshift",  bit_rshift},
  {"arshift", bit_arshift},
  {"mod",     bit_mod},
  {NULL, NULL}
};

LUALIB_API int luaopen_bit (lua_State *L) {
  luaL_openlib(L, "bit", bitlib, 0);
  return 1;
}
