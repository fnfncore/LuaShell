// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef  LUASHELL_RPCCLIENT_H
#define  LUASHELL_RPCCLIENT_H

#include "config.h"
#include "walleve/walleve.h"
#include "json/json_spirit_value.h"

namespace luashell
{

class CRPCClient : public walleve::IIOModule, virtual public walleve::CWalleveHttpEventListener
{
public:
    typedef std::function<void(uint64, json_spirit::Value&)> RespAsyncCallback;
public:
    CRPCClient();
    ~CRPCClient();
    bool CallRPC(const std::string& strMethod,const json_spirit::Object& params,json_spirit::Object& jsonRspRet);
    bool CallAsyncRPC(uint64 nNonce, const std::string& strMethod,const json_spirit::Object& params, RespAsyncCallback callback);
    bool HandleEvent(walleve::CWalleveEventHttpGetRsp& eventHttpGetRsp);
protected:
    bool WalleveHandleInitialize();
    void WalleveHandleDeinitialize();
    const CLuaShellConfig* WalleveConfig()
    {
        return dynamic_cast<const CLuaShellConfig*>(walleve::IWalleveBase::WalleveConfig());
    }
    bool GetResponse(uint64 nNonce,json_spirit::Object& jsonReq);
protected:
    walleve::IIOProc *pHttpGet;
    walleve::CIOCompletion ioComplt;
    json_spirit::Object jsonRsp; 
    std::map<uint64, RespAsyncCallback> mapAsyncCallback;
};

} // luashell

#endif //LUASHELL_RPCCLIENT_H

