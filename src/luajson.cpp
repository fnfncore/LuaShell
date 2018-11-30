// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "luajson.h"
#include "json/json_spirit_reader_template.h"
#include "json/json_spirit_writer_template.h"
#include "json/json_spirit_utils.h"


using namespace std;
using namespace json_spirit;

///////////////////////////////
// LuaJSON

namespace luashell
{

static bool L_JsonEncodeObject(lua_State *L,Object& obj)
{
    if (!lua_isstring(L,-2))
    {
        lua_pop(L,2);
        return false;
    }
    string strKey = lua_tostring(L,-2);

    switch (lua_type(L,-1))
    {
    case LUA_TNIL:
        obj.push_back(Pair(strKey,Value::null)); 
        break;
    case LUA_TBOOLEAN:
        obj.push_back(Pair(strKey,(bool)(lua_toboolean(L,-1)))); 
        break;
    case LUA_TNUMBER:
        if (lua_isinteger(L,-1))
        {
            obj.push_back(Pair(strKey,(boost::int64_t)(lua_tointeger(L,-1)))); 
        }
        else
        {
            obj.push_back(Pair(strKey,(double)(lua_tonumber(L,-1)))); 
        }
        break;
    case LUA_TSTRING:
        obj.push_back(Pair(strKey,lua_tostring(L,-1)));
        break;
    case LUA_TTABLE:
        {
            Value val;
            if (!L_JsonEncode(L,val))
            {
                lua_pop(L,2);
                return false;
            }
            obj.push_back(Pair(strKey,val));
        }
        break;
    default:
        {
            lua_pop(L,2);
            return false;
        }
    }
    return true;
}

static bool L_JsonEncodeArray(lua_State *L,Array& array)
{
    if (lua_isstring(L,-2))
    {
        lua_pop(L,2);
        return false;
    }

    switch (lua_type(L,-1))
    {
    case LUA_TNIL:
        array.push_back(Value::null); 
        break;
    case LUA_TBOOLEAN:
        array.push_back((bool)(lua_toboolean(L,-1))); 
        break;
    case LUA_TNUMBER:
        if (lua_isinteger(L,-1))
        {
            array.push_back((boost::int64_t)(lua_tointeger(L,-1))); 
        }
        else
        {
            array.push_back((double)(lua_tonumber(L,-1))); 
        }
        break;
    case LUA_TSTRING:
        array.push_back(lua_tostring(L,-1));
        break;
    case LUA_TTABLE:
        {
            Value val;
            if (!L_JsonEncode(L,val))
            {
                lua_pop(L,2);
                return false;
            }
            array.push_back(val);
        }
        break;
    default:
        {
            lua_pop(L,2);
            return false;
        }
    }
    return true;
}

bool L_JsonEncode(lua_State *L,Value& val,int idx)
{
    lua_pushnil(L);
    if (lua_next(L,idx) != 0)
    {
        if (lua_isstring(L,-2))
        {
            Object obj;
            if (!L_JsonEncodeObject(L,obj))
            {
                return false;
            }
            lua_pop(L,1);
            while (lua_next(L,-2) != 0)
            {
                if (!L_JsonEncodeObject(L,obj))
                {
                    return false;
                }
                lua_pop(L,1);
            }
            val = obj;
        }
        else
        {
            Array array;
            if (!L_JsonEncodeArray(L,array))
            {
                return false;
            }
            lua_pop(L,1);
            while (lua_next(L,-2) != 0)
            {
                if (!L_JsonEncodeArray(L,array))
                {
                    return false;
                }
                lua_pop(L,1);
            }
            val = array;
        }
    }
    else
    {
        val = Object();
    }
    return true;
}

void L_JsonDecode(lua_State *L,const Value& val)
{
    switch (val.type())
    {
    case obj_type:
        {
            const Object& obj = val.get_obj();
            lua_newtable(L);
            for (Object::const_iterator it = obj.begin(); it != obj.end(); ++it )
            {
                lua_pushstring(L,(*it).name_.c_str());
                L_JsonDecode(L,(*it).value_);
                lua_settable(L,-3);
            }
        }
        break;
    case array_type:
        {
            const Array& array = val.get_array();
            lua_newtable(L);
            for (int i = 0;i < array.size();i++)
            {
                lua_pushnumber(L,i + 1);
                L_JsonDecode(L,array[i]);
                lua_settable(L,-3);
            }
        }
        break;
    case str_type:
        lua_pushstring(L,val.get_str().c_str());
        break;
    case bool_type:
        lua_pushboolean(L,val.get_bool());
        break;
    case int_type:
        lua_pushinteger(L,val.get_int());
        break;
    case real_type:
        lua_pushnumber(L,val.get_real());
        break;
    case null_type:
        lua_pushnil(L);
        break;
    }
}

} // luashell
