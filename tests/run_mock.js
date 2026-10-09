const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const state = lauxlib.luaL_newstate();
lualib.luaL_openlibs(state);

const addonPath = path.join(__dirname, '..', 'ProfessionLevelTooltipBeta.lua');
const addon = fs.readFileSync(addonPath, 'utf8');
lua.lua_pushstring(state, to_luastring(addon));
lua.lua_setglobal(state, to_luastring('__addon'));

const source = fs.readFileSync(path.join(__dirname, 'test_tooltip.lua'), 'utf8');
let status = lauxlib.luaL_loadstring(state, to_luastring(source));
if (status === lua.LUA_OK) status = lua.lua_pcall(state, 0, 0, 0);
if (status !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
