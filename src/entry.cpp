// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "entry.h"
#include "rpcclient.h"
#include "interactive.h"

#include <map>
#include <string>

#ifdef WIN32
#ifdef _MSC_VER
#pragma warning(disable:4786)
#pragma warning(disable:4804)
#pragma warning(disable:4805)
#pragma warning(disable:4717)
#endif
#include "shlobj.h"
#include "shlwapi.h"
#endif

using namespace std;
using namespace walleve;
using namespace luashell;
using namespace boost::filesystem;

//////////////////////////////
// CLuaShellEntry

CLuaShellEntry::CLuaShellEntry()
{
}

CLuaShellEntry::~CLuaShellEntry()
{
    Exit(); 
}

bool CLuaShellEntry::Initialize(int argc,char *argv[])
{
    if (!lsConfig.Load(argc,argv,GetDefaultDataDir(),"luashell.conf") || !lsConfig.PostLoad())
    {
        cerr << "Failed to load/parse arguments and config file\n";
        return false;
    }
  
    if (lsConfig.fHelp)
    {
        return false;
    }

    path& pathData = lsConfig.pathData;
    if (!exists(pathData))
    {
        create_directories(pathData);
    }

    if (!is_directory(pathData))
    {
        cerr << "Failed to access data directory : " << pathData << "\n";
        return false;
    }

    if (!walleveLog.SetLogFilePath((pathData / "luashell.log").string()))
    {
        cerr << "Failed to open log file : " << (pathData / "luashell.log") << "\n";
        return false; 
    }

    if (!walleveDocker.Initialize(&lsConfig,&walleveLog))
    {
        cerr << "Failed to initialize docker\n";
        return false;
    }

    return InitializeService();
}

bool CLuaShellEntry::InitializeService()
{
    CHttpGet *pHttpGet = new CHttpGet();
    if (!pHttpGet || !walleveDocker.Attach(pHttpGet))
    {
        delete pHttpGet;
        return false;
    }

    CRPCClient *pRPCClient = new CRPCClient();
    if (!pRPCClient || !walleveDocker.Attach(pRPCClient))
    {
        delete pRPCClient;
        return false;
    }

    CInteractive *pInteractive = new CInteractive(lsConfig.vecCommand.size() == 0);
    if (!pInteractive || !walleveDocker.Attach(pInteractive))
    {
        delete pInteractive;
        return false;
    }

    return true;
}

bool CLuaShellEntry::Run()
{
    if (!walleveDocker.Run())
    {
        return false;
    }

    return CWalleveEntry::Run();
}

void CLuaShellEntry::Exit()
{
    walleveDocker.Exit();
}

path CLuaShellEntry::GetDefaultDataDir()
{
    // Windows: C:\Documents and Settings\username\Local Settings\Application Data\LuaShell
    // Mac: ~/Library/Application Support/LuaShell
    // Unix: ~/.luashell

#ifdef WIN32
    // Windows
    char pszPath[MAX_PATH] = "";
    if (SHGetSpecialFolderPathA(NULL, pszPath,CSIDL_LOCAL_APPDATA,true))
    {
        return path(pszPath) / "LuaShell";
    }
    return path("C:\\LuaShell");
#else
    path pathRet;
    char* pszHome = getenv("HOME");
    if (pszHome == NULL || strlen(pszHome) == 0)
    {
        pathRet = path("/");
    }
    else
    {
        pathRet = path(pszHome);
    }
#ifdef __APPLE__
    // Mac
    pathRet /= "Library/Application Support";
    create_directory(pathRet);
    return pathRet / "LuaShell";
#else
    // Unix
    return pathRet / ".luashell";
#endif    
#endif   
}

bool CLuaShellEntry::SetupEnvironment()
{
#ifdef _MSC_VER
    // Turn off microsoft heap dump noise
    _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_WARN, CreateFileA("NUL", GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, 0));
#endif
#if _MSC_VER >= 1400
    // Disable confusing "helpful" text message on abort, ctrl-c
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
#endif
#ifndef WIN32
    umask(077);
#endif
    return true;
}


