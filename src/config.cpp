// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "config.h"

using namespace std;
using namespace boost::filesystem;
using boost::asio::ip::tcp;
using namespace walleve;
using namespace luashell;


#define DEFAULT_RPCPORT                 6812
#define DEFAULT_RPC_CONNECT_TIMEOUT     120

namespace po = boost::program_options;

#define OPTBOOL(name,var,def)           (name,po::value<bool>(&(var))->default_value(def))
#define OPTUINT(name,var,def)           (name,po::value<unsigned int>(&(var))->default_value(def))
#define OPTINT(name,var,def)            (name,po::value<int>(&(var))->default_value(def))
#define OPTFLOAT(name,var,def)          (name,po::value<float>(&(var))->default_value(def))
#define OPTSTR(name,var,def)            (name,po::value<string>(&(var))->default_value(def))
#define OPTVEC(name,var)                (name,po::value<vector<string> >(&(var)))

//////////////////////////////
// CLuaShellBasicConfig

CLuaShellBasicConfig::CLuaShellBasicConfig()
{
    po::options_description desc("LuaShellBasic");

    desc.add_options()

    OPTSTR("luapath",strLuaPath,"");

    AddOptions(desc);
}

CLuaShellBasicConfig::~CLuaShellBasicConfig()
{
}

bool CLuaShellBasicConfig::PostLoad()
{
    if (strLuaPath.empty())
    {
        strLuaPath = (pathRoot / "lua").string();
    }

    return true;
}

string CLuaShellBasicConfig::ListConfig()
{   
    ostringstream oss;
    return oss.str();
}

//////////////////////////////
// CLuaShellRPCConfig

CLuaShellRPCConfig::CLuaShellRPCConfig()
{
    po::options_description desc("LuaShellRPC");

    desc.add_options()

    OPTSTR("rpcconnect",strRPCConnect,"127.0.0.1")
    OPTINT("rpcport",nRPCPortInt,0)
    OPTUINT("rpctimeout",nRPCConnectTimeout,DEFAULT_RPC_CONNECT_TIMEOUT)

    OPTSTR("rpcuser",strRPCUser,"")
    OPTSTR("rpcpassword",strRPCPass,"")

    OPTBOOL("rpcssl",fRPCSSLEnable,false)
    OPTBOOL("rpcsslverify",fRPCSSLVerify,true)
    OPTSTR("rpcsslcafile",strRPCCAFile,"ca.crt")
    OPTSTR("rpcsslcertificatechainfile",strRPCCertFile,"server.crt")
    OPTSTR("rpcsslprivatekeyfile",strRPCPKFile,"server.key")
    OPTSTR("rpcsslciphers",strRPCCiphers,"TLSv1+HIGH:!SSLv2:!aNULL:!eNULL:!AH:!3DES:@STRENGTH");

    AddOptions(desc);
}

CLuaShellRPCConfig::~CLuaShellRPCConfig()
{
}

bool CLuaShellRPCConfig::PostLoad()
{
    if (nRPCPortInt <= 0 || nRPCPortInt > 0xFFFF)
    {
        nRPCPort = DEFAULT_RPCPORT;
    }
    else
    {
        nRPCPort = (unsigned short)nRPCPortInt;
    }

    if (nRPCConnectTimeout == 0)
    {
        nRPCConnectTimeout = 1;
    }

    if (!path(strRPCCAFile).is_complete())
    {
        strRPCCAFile = (pathRoot / strRPCCAFile).string();
    }

    if (!path(strRPCCertFile).is_complete())
    {
        strRPCCertFile = (pathRoot / strRPCCertFile).string();
    }

    if (!path(strRPCPKFile).is_complete())
    {
        strRPCPKFile = (pathRoot / strRPCPKFile).string();
    }

    return true;
}

string CLuaShellRPCConfig::ListConfig()
{
    return "";
}

//////////////////////////////
// CLuaShellConfig

CLuaShellConfig::CLuaShellConfig()
{
}

CLuaShellConfig::~CLuaShellConfig()
{
}

bool CLuaShellConfig::PostLoad()
{
    return (CWalleveConfig::PostLoad()
            && CLuaShellBasicConfig::PostLoad()
            && CLuaShellRPCConfig::PostLoad());
}

string CLuaShellConfig::ListConfig()
{
    return (CWalleveConfig::ListConfig()
            + CLuaShellBasicConfig::ListConfig()
            + CLuaShellRPCConfig::ListConfig());
}
