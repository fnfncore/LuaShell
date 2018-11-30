// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "rpcclient.h"
#include "json/json_spirit_reader_template.h"
#include "json/json_spirit_writer_template.h"
#include "json/json_spirit_utils.h"

using namespace std;
using namespace luashell;
using namespace walleve;
using namespace json_spirit;

///////////////////////////////
// CRPCClient

CRPCClient::CRPCClient()
: IIOModule("rpcclient")
{
    pHttpGet = NULL;
}

CRPCClient::~CRPCClient()
{
}

bool CRPCClient::WalleveHandleInitialize()
{   
    if (!WalleveGetObject("httpget",pHttpGet))
    {
        cerr << "Failed to request httpget\n";
        return false;
    }
    return true;
}   
    
void CRPCClient::WalleveHandleDeinitialize()
{   
    pHttpGet = NULL;
}

bool CRPCClient::HandleEvent(CWalleveEventHttpGetRsp& eventHttpGetRsp)
{
    CWalleveHttpRsp& rsp = eventHttpGetRsp.data;
    if (rsp.nStatusCode == 200 && !rsp.strContent.empty())
    {
        Value valReply;
        if (read_string(rsp.strContent, valReply))
        {
            jsonRsp = valReply.get_obj();
            ioComplt.Completed(true);
            return true;
        }
    }
    ioComplt.Completed(false);
    return true;
}

bool CRPCClient::CallRPC(const string& strMethod,const Object& params,Object& jsonRspRet)
{
    try
    {
        Object request;
        request.push_back(Pair("method", strMethod));
        request.push_back(Pair("params", params));
        request.push_back(Pair("id",1));
        if (GetResponse(1,request))
        {
            jsonRspRet = jsonRsp; 
            return true;
        }
    }
    catch (...)
    {
    }
    return false;
}

bool CRPCClient::GetResponse(uint64 nNonce,Object& jsonReq)
{
    CWalleveEventHttpGet eventHttpGet(nNonce);
    CWalleveHttpGet& httpGet = eventHttpGet.data;
    httpGet.strIOModule = WalleveGetOwnKey();
    httpGet.nTimeout = WalleveConfig()->nRPCConnectTimeout;;
    if (WalleveConfig()->fRPCSSLEnable)
    {
        httpGet.strProtocol = "https";
        httpGet.fVerifyPeer = true;
        httpGet.strPathCA   = WalleveConfig()->strRPCCAFile;
        httpGet.strPathCert = WalleveConfig()->strRPCCertFile;
        httpGet.strPathPK   = WalleveConfig()->strRPCPKFile;
    }
    else
    {
        httpGet.strProtocol = "http";
    }
    CNetHost host(WalleveConfig()->strRPCConnect,WalleveConfig()->nRPCPort);
    httpGet.mapHeader["host"] = host.ToString();
    httpGet.mapHeader["url"] = string("/") + "0.1.0";
    httpGet.mapHeader["method"] = "POST";
    httpGet.mapHeader["accept"] = "application/json";
    httpGet.mapHeader["content-type"] = "application/json";
    httpGet.mapHeader["user-agent"] = string("multivers-json-rpc/");
    httpGet.mapHeader["connection"] = "Keep-Alive";
    if (!WalleveConfig()->strRPCPass.empty() || !WalleveConfig()->strRPCUser.empty())
    {
        string strAuth;
        CHttpUtil().Base64Encode(WalleveConfig()->strRPCUser + ":" + WalleveConfig()->strRPCPass,strAuth);
        httpGet.mapHeader["authorization"] = string("Basic ") + strAuth;
    }

    httpGet.strContent = write_string(Value(jsonReq), false) + "\n";

    ioComplt.Reset();

    if (!pHttpGet->DispatchEvent(&eventHttpGet))
    {
        throw runtime_error("failed to send json request");
    }
    bool fResult = false;
    return (ioComplt.WaitForComplete(fResult) && fResult);
}
