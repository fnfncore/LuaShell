// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef  LUASHELL_ENTRY_H
#define  LUASHELL_ENTRY_H

#include "config.h"
#include <walleve/walleve.h>
#include <boost/filesystem.hpp>

namespace luashell
{

class CLuaShellEntry : public walleve::CWalleveEntry
{
public:
    CLuaShellEntry();
    ~CLuaShellEntry();
    bool Initialize(int argc,char *argv[]);
    bool Run();
    void Exit();
protected:
    bool InitializeService();

    boost::filesystem::path GetDefaultDataDir();

    bool SetupEnvironment();
protected:
    CLuaShellConfig lsConfig;
    walleve::CWalleveLog walleveLog;
    walleve::CWalleveDocker walleveDocker;
};

} // namespace luashell

#endif //LUASHELL_ENTRY_H

