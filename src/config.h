// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef  LUASHELL_CONFIG_H
#define  LUASHELL_CONFIG_H
#include <walleve/walleve.h>

namespace luashell
{

class CLuaShellBasicConfig : virtual public walleve::CWalleveConfig
{
public:
    CLuaShellBasicConfig();
    virtual ~CLuaShellBasicConfig();
    virtual bool PostLoad();
    virtual std::string ListConfig();
public:
    std::string strLuaPath;
};

class CLuaShellRPCConfig : virtual public CLuaShellBasicConfig
{
public:
    CLuaShellRPCConfig();
    virtual ~CLuaShellRPCConfig();
    virtual bool PostLoad();
    virtual std::string ListConfig();
public:
    std::string strRPCConnect;
    unsigned int nRPCPort;
    unsigned int nRPCConnectTimeout;
    std::string strRPCUser;
    std::string strRPCPass;
    bool fRPCSSLEnable;
    bool fRPCSSLVerify;
    std::string strRPCCAFile;
    std::string strRPCCertFile;
    std::string strRPCPKFile;
    std::string strRPCCiphers;
protected:
    int nRPCPortInt;
};

class CLuaShellConfig : virtual public CLuaShellBasicConfig,
                      virtual public CLuaShellRPCConfig
{
public:
    CLuaShellConfig();
    virtual ~CLuaShellConfig();
    virtual bool PostLoad();
    virtual std::string ListConfig();
};

} // namespace luashell

#endif //LUASHELL_CONFIG_H
