// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "interactive.h"
#include "luajson.h"
#include "json/json_spirit_reader_template.h"
#include "json/json_spirit_writer_template.h"
#include "json/json_spirit_utils.h"

#include <boost/filesystem.hpp>

using namespace std;
using namespace luashell;
using namespace walleve;
using namespace json_spirit;

///////////////////////////////
// CInteractive

CInteractive::CInteractive() 
: CConsole("interactive","fnfn>")
{
    pRPCClient = NULL;
}

CInteractive::~CInteractive()
{
}

bool CInteractive::WalleveHandleInitialize()
{
    if (!WalleveGetObject("rpcclient",pRPCClient))
    {
        WalleveLog("Failed to request rpc client\n");
        return false;
    }

    luaState = luaL_newstate();
    if (luaState == NULL)
    {
        WalleveLog("Failed to initalize lua\n");
        return false;
    }

    boost::filesystem::path pathLib(WalleveConfig()->strLuaPath);

    luaL_openlibs(luaState);

    lua_getglobal(luaState, "package");
    lua_pushstring(luaState, (pathLib / "?.lua").string().c_str());
    lua_setfield(luaState, -2, "path");
    lua_pop(luaState, 1);

    LoadCFunc();
/*
    if (!CLoMoLua(pService).Load(luaState))
    {
        WalleveLog("Failed to load lua service\n");
        return false;
    }
*/
    if (luaL_loadbuffer(luaState, strLuaPrintResult.c_str(),strLuaPrintResult.size(),"presult") != 0
        || lua_pcall(luaState, 0, 0, 0) != 0)
    {
        WalleveLog("Failed to load lua printresult\n");
        return false;
    }
    return true;
}

void CInteractive::WalleveHandleDeinitialize()
{
    if (luaState != NULL)
    {
        lua_close(luaState);
        luaState = NULL;
    }

    pRPCClient = NULL;
}

void CInteractive::EnterLoop()
{
    lua_settop(luaState,0);
    strLineCache.empty();
}

void CInteractive::LeaveLoop()
{
}

bool CInteractive::HandleLine(const string& strLine)
{
    int status = -1;
    bool fSingleLine = strLineCache.empty();
    strLineCache += strLine + "\n";
    lua_settop(luaState, 0);
    if (fSingleLine)
    {
        string strAddRet = string("return ") + strLine + ";";
        status = luaL_loadbuffer(luaState, strAddRet.c_str(),strAddRet.size(), "=fnfn");
        if (status != 0)
        {   
            lua_pop(luaState, 2);
        }
    }
    if (status != 0)
    {
        status = luaL_loadbuffer(luaState, strLineCache.c_str(),strLineCache.size(), "=fnfn");
    }
    if (status == LUA_ERRSYNTAX)
    {
        size_t lmsg;
        const char *msg = lua_tolstring(luaState, -1, &lmsg);
        const size_t marklen = sizeof("<eof>") - 1;

        if (lmsg >= marklen && strcmp(msg + lmsg - marklen,"<eof>") == 0)
        {
            lua_pop(luaState, 1);
            return false;
        }
    }

    strLineCache.clear();

    if (status == 0)
    {
        status = lua_pcall(luaState,0,LUA_MULTRET,0);
        if (status == 0 && lua_gettop(luaState) > 0)
        {
            lua_getglobal(luaState, "presult");
            lua_insert(luaState, 1);
            lua_pcall(luaState, lua_gettop(luaState)-1, 0, 0);
        }
    }

    if (status != 0)
    {
        ReportError();
        lua_gc(luaState, LUA_GCCOLLECT, 0);
    }
    return fSingleLine;
}

void CInteractive::ReportError()
{
    if (!lua_isnil(luaState, -1))
    {
        const char *msg = lua_tostring(luaState, -1);
        if (!msg)
        {
            msg = "(error object is not a string)";
        }
        cerr << msg << "\n" << std::flush;
        lua_pop(luaState, 1);
    }
}

int CInteractive::L_Error(lua_State *L,int errcode,const string& strMsg)
{
    lua_pushinteger(L,errcode);
    lua_pushstring(L,strMsg.c_str());
    return 2;
}

int CInteractive::L_RPCCall(lua_State *L)
{
    CRPCClient* pRPCClient = static_cast<CRPCClient*>(lua_touserdata(L,lua_upvalueindex(1)));
    if (lua_gettop(L) < 2 || !lua_isstring(L,1) || !lua_istable(L,2))
    {
        return L_Error(L,-32602,"invalid parameter");
    }
   
    Value param;
    if (!L_JsonEncode(L,param,2) || param.type() != obj_type)
    {
        return L_Error(L,-32602,"invalid parameter");
    } 

    Object reply;
    if (!pRPCClient->CallRPC(lua_tostring(L,1),param.get_obj(),reply))
    {
        return L_Error(L,-32603,"rpc failed");
    }

    const Value& error = find_value(reply, "error");
    if (error.type() == obj_type)
    {
        const Value& code = find_value(error.get_obj(),"code");
        const Value& message = find_value(error.get_obj(),"message");
        if (code.type() != int_type || message.type() != str_type)
        {
            return L_Error(L,-32603,"invalid replay");
        }
        return L_Error(L,code.get_int(),message.get_str());
    }
    
    lua_pushinteger(L,0);
    L_JsonDecode(L,find_value(reply, "result"));
    return 2;    
}
 
int CInteractive::L_RPCJson(lua_State *L)
{
    CRPCClient* pRPCClient = static_cast<CRPCClient*>(lua_touserdata(L,lua_upvalueindex(1)));
    if (lua_gettop(L) < 2 || !lua_isstring(L,1) || !lua_isstring(L,2))
    {
        return L_Error(L,-32602,"invalid parameter");
    }

    Value valParam;
    if (!read_string(string(lua_tostring(L,2)), valParam) || valParam.type() != obj_type)
    {
        return L_Error(L,-32602,"invalid parameter");
    }
    
    Object reply;
    if (!pRPCClient->CallRPC(lua_tostring(L,1),valParam.get_obj(),reply))
    {
        return L_Error(L,-32603,"rpc failed");
    }

    const Value& error = find_value(reply, "error");
    if (error.type() == obj_type)
    {
        const Value& code = find_value(error.get_obj(),"code");
        const Value& message = find_value(error.get_obj(),"message");
        if (code.type() != int_type || message.type() != str_type)
        {
            return L_Error(L,-32603,"invalid replay");
        }
        return L_Error(L,code.get_int(),message.get_str());
    }

    lua_pushinteger(L,0);
    lua_pushstring(L,write_string(find_value(reply, "result"), false).c_str());

    return 2;    
}

void CInteractive::LoadCFunc()
{
    lua_settop(luaState,0);

    lua_pushlightuserdata(luaState,pRPCClient);
    lua_pushcclosure(luaState,CInteractive::L_RPCCall,1);
    lua_setglobal(luaState,"rpccall");

    lua_pushlightuserdata(luaState,pRPCClient);
    lua_pushcclosure(luaState,CInteractive::L_RPCJson,1);
    lua_setglobal(luaState,"rpcjson");
}

const string CInteractive::strLuaPrintResult =
"\
function presult(...) \n\
    print(...) \n\
    function print_table(o,indent) \n\
        indent = indent or 0 \n\
        if type(o)==\"number\" then \n\
            io.write(o) \n\
        elseif type(o)==\"boolean\" then \n\
            if o then io.write(\"true\") else io.write(\"false\") end \n\
        elseif type(o) ==\"string\" then \n\
            io.write(string.format(\"%q\",o)) \n\
        elseif type(o)==\"table\" then \n\
            io.write(\"{\\n\") \n\
            for k,v in pairs(o) do \n\
                io.write(string.rep (\" \", indent + 2)) \n\
                if \"string\" == type(k) then io.write(k,\"=\") end \n\
                print_table(v,indent + 2) \n\
                io.write(\",\\n\") \n\
            end \n\
            io.write(string.rep (\" \", indent)) \n\
            if indent==0 then \n\
                io.write(\"}\\n\") \n\
            else \n\
                io.write(\"}\") \n\
            end \n\
        end \n\
    end \n\
    for k,v in pairs{...} do \n\
        if \"table\" == type(v) then print_table(v) end \n\
    end \n\
end \n\
";

