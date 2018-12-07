// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "interactive.h"
#include "luajson.h"
#include "json/json_spirit_reader_template.h"
#include "json/json_spirit_writer_template.h"
#include "json/json_spirit_utils.h"

#include <numeric>
#include <boost/filesystem.hpp>

using namespace std;
using namespace luashell;
using namespace walleve;
using namespace json_spirit;

extern void LuaShellShutdown();

///////////////////////////////
// CInteractive

CInteractive::CInteractive(const bool fConsoleIn) 
: CConsole("interactive", "fnfn>", fConsoleIn),
  vecAsyncResp(nMaxRespSize), nRead(0), nWrite(0)
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

bool CInteractive::WalleveHandleInvoke()
{
    if (!CConsole::WalleveHandleInvoke())
    {
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

void CInteractive::ExecuteCommand()
{
    const auto& vecCommand = WalleveConfig()->vecCommand;
    try
    {
        if (vecCommand.size() == 0)
        {
            throw runtime_error("");
        }

        // modpath = package.searchpath(modname, package.path)
        string modname = vecCommand[0].substr(0, vecCommand[0].find(".lua"));
        lua_settop(luaState, 0);
        lua_getglobal(luaState, "package");
        lua_getfield(luaState, 1, "searchpath");
        lua_pushstring(luaState, modname.c_str());
        lua_getfield(luaState, 1, "path");
        lua_remove(luaState, 1);
        lua_pcall(luaState, 2, 1, 0);
        if (lua_gettop(luaState) < 1 || !lua_isstring(luaState, -1))
        {
            lua_settop(luaState,0);
            lua_getglobal(luaState, "package");
            lua_getfield(luaState, 1, "path");
            const char* path = lua_tostring(luaState, -1);
            throw runtime_error(string("Not found ") + vecCommand[0] + " in " + path);
        }
        string modpath = lua_tostring(luaState, -1);

        // loadfile(modpath)(arg1, arg2, ...)
        lua_settop(luaState, 0);
        if (luaL_loadfile(luaState, modpath.c_str()))
        {
            const char* err = lua_tostring(luaState, -1);
            throw runtime_error(string("Load fail: ") + err);
        }
        lua_checkstack(luaState, vecCommand.size());
        for (int i = 1; i < vecCommand.size(); i++)
        {
            lua_pushstring(luaState, vecCommand[i].c_str());
        }

        lua_pushboolean(luaState, true);
        lua_setglobal(luaState, "running");
        lua_pcall(luaState, vecCommand.size() - 1, LUA_MULTRET, 0);

        if (lua_gettop(luaState) > 0 && lua_isstring(luaState, -1))
        {
            cerr << lua_tostring(luaState, -1) << endl;
        }
    }
    catch (exception& e)
    {
        cerr << e.what() << endl;
    }

    LuaShellShutdown();
}

void CInteractive::ExitCommand()
{
    lua_pushboolean(luaState, false);
    lua_setglobal(luaState, "running");
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
    CInteractive* ptr = static_cast<CInteractive*>(lua_touserdata(L,lua_upvalueindex(1)));
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
    if (!ptr->pRPCClient->CallRPC(lua_tostring(L,1),param.get_obj(),reply))
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
    CInteractive* ptr = static_cast<CInteractive*>(lua_touserdata(L,lua_upvalueindex(1)));
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
    if (!ptr->pRPCClient->CallRPC(lua_tostring(L,1),valParam.get_obj(),reply))
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

int CInteractive::L_RPCAsyncCall(lua_State *L)
{
    CInteractive* ptr = static_cast<CInteractive*>(lua_touserdata(L,lua_upvalueindex(1)));
    if (lua_gettop(L) < 3 || !lua_isinteger(L, 1) || !lua_isstring(L, 2) || !lua_istable(L, 3))
    {
        return L_Error(L,-32602,"invalid parameter");
    }
   
    Value param;
    if (!L_JsonEncode(L,param,3) || param.type() != obj_type)
    {
        return L_Error(L,-32602,"invalid parameter");
    } 

    uint64 nNonce = lua_tointeger(L, 1);
    if (!ptr->pRPCClient->CallAsyncRPC(nNonce, lua_tostring(L,2),
            param.get_obj(), bind(&CInteractive::RPCAsyncCallback, ptr, _1, _2)))
    {
        return L_Error(L,-32603,"rpc failed");
    }

    ptr->mapAsyncLuaState[nNonce] = L;
    lua_pushinteger(L, 0);
    lua_pushstring(L, "success");
    return lua_yield(L, 2);
}

int CInteractive::L_RPCAsyncWait(lua_State *L)
{
    CInteractive* ptr = static_cast<CInteractive*>(lua_touserdata(L,lua_upvalueindex(1)));
    auto tm = boost::chrono::system_clock::now();
    if (lua_gettop(L) >= 1 && lua_isinteger(L, 1))
    {
        tm += boost::chrono::milliseconds(lua_tointeger(L, 1));
    }
    else
    {
        tm += boost::chrono::milliseconds(1);
    }

    int nWork = 0;
    boost::unique_lock<boost::mutex> lock(ptr->mtx);
    while (true)
    {
        while(ptr->nRead != ptr->nWrite)
        {
            auto& resp = ptr->vecAsyncResp[ptr->nRead % nMaxRespSize];
            uint64 nNonce = resp.first;
            Value& jsonRspRet = resp.second;
            auto it = ptr->mapAsyncLuaState.find(nNonce);
            if (it != ptr->mapAsyncLuaState.end())
            {
                lua_State* pState = it->second;
                do
                {
                    if (jsonRspRet.type() != Value_type::obj_type)
                    {
                        L_Error(pState, -32603, "invalid replay");
                        break;
                    }

                    Object reply = jsonRspRet.get_obj();
                    const Value& error = find_value(reply, "error");
                    if (error.type() == obj_type)
                    {
                        const Value& code = find_value(error.get_obj(),"code");
                        const Value& message = find_value(error.get_obj(),"message");
                        if (code.type() != int_type || message.type() != str_type)
                        {
                            L_Error(pState, -32603, "invalid replay");
                            break;
                        }
                        L_Error(pState, code.get_int(), message.get_str());
                        break;
                    }
                
                    lua_pushinteger(pState, 0);
                    L_JsonDecode(pState, find_value(reply, "result"));

                } while (false);

                lua_resume(pState, 0, 2);

                ++nWork;
            }

            ++ptr->nRead;
        }

        if (!ptr->cond.wait_until(lock, tm, [=]() { return ptr->nRead != ptr->nWrite; }))
        {
            // timeout
            break;
        }
    }

    lua_pushinteger(L, nWork);
    return 1;
}

int CInteractive::L_Sleep(lua_State *L)
{
    int ms = (lua_gettop(L) >= 1) ? lua_tointeger(L, 1) : 1;
    this_thread::sleep_for(chrono::milliseconds(ms));
    return 0;
}

int CInteractive::L_Now(lua_State *L)
{
    auto now = chrono::system_clock::now();
    lua_pushinteger(L, chrono::duration_cast<chrono::milliseconds>(now.time_since_epoch()).count());
    return 1;
}

void CInteractive::LoadCFunc()
{
    lua_settop(luaState,0);

    lua_pushlightuserdata(luaState, this);
    lua_pushcclosure(luaState,CInteractive::L_RPCCall,1);
    lua_setglobal(luaState,"rpccall");

    lua_pushlightuserdata(luaState, this);
    lua_pushcclosure(luaState,CInteractive::L_RPCJson,1);
    lua_setglobal(luaState,"rpcjson");

    lua_pushlightuserdata(luaState, this);
    lua_pushcclosure(luaState,CInteractive::L_RPCAsyncCall,1);
    lua_setglobal(luaState,"rpcasynccall");

    lua_pushlightuserdata(luaState, this);
    lua_pushcclosure(luaState,CInteractive::L_RPCAsyncWait,1);
    lua_setglobal(luaState,"rpcasyncwait");

    lua_pushcclosure(luaState,CInteractive::L_Sleep,0);
    lua_setglobal(luaState,"sleep");

    lua_pushcclosure(luaState,CInteractive::L_Now,0);
    lua_setglobal(luaState,"now");
}

void CInteractive::RPCAsyncCallback(uint64 nNonce, json_spirit::Value& jsonRspRet)
{
    vecAsyncResp[nWrite % nMaxRespSize] = make_pair(nNonce, jsonRspRet);
    ++nWrite;
    cond.notify_all();
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

