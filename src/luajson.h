// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef  LUASHELL_LUAJSON_H
#define  LUASHELL_LUAJSON_H

#include "lua.hpp"
#include "json/json_spirit_value.h"

namespace luashell
{

bool L_JsonEncode(lua_State *L,json_spirit::Value& val,int idx = -2);
void L_JsonDecode(lua_State *L,const json_spirit::Value& val);

} // luashell

#endif //LUASHELL_LUAJSON_H

