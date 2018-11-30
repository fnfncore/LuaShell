// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef  LUASHELL_INTERACTIVE_H
#define  LUASHELL_INTERACTIVE_H

#include "config.h"
#include "rpcclient.h"
#include "lua.hpp"
#include "walleve/walleve.h"
#include "json/json_spirit_value.h"

namespace luashell
{

class CInteractive : public walleve::CConsole
{
public:
    CInteractive();
    ~CInteractive();
protected:
    bool WalleveHandleInitialize();
    void WalleveHandleDeinitialize();
    void EnterLoop();
    void LeaveLoop();
    bool HandleLine(const std::string& strLine);
    void ReportError();
    const CLuaShellConfig* WalleveConfig()
    {
        return dynamic_cast<const CLuaShellConfig*>(walleve::IWalleveBase::WalleveConfig());
    }
    void LoadCFunc();
    static int L_Error(lua_State *L,int errcode,const std::string& strMsg = "");
    static int L_RPCCall(lua_State *L); 
    static int L_RPCJson(lua_State *L); 
protected:
    CRPCClient* pRPCClient;
    lua_State* luaState;
    std::string strLineCache;
    static const std::string strLuaPrintResult;
};

} // luashell

#endif //LUASHELL_INTERACTIVE_H

