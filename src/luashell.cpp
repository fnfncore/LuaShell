// Copyright (c) 2017-2018 The Multiverse developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "entry.h"
#include <iostream>
#include <exception>
#include <walleve/walleve.h>

using namespace luashell;

static CLuaShellEntry lsEntry;

void LuaShellShutdown()
{
    lsEntry.Stop();
}

int main(int argc,char **argv)
{
    try
    {
        if (lsEntry.Initialize(argc,argv))
        {
            lsEntry.Run();
        }
    }
    catch (std::exception& e)
    {
        std::cerr << "LuaShell exception caught : " << e.what() << "\n";
    }
    catch (...)
    {
        std::cerr << "LuaShell exception caught : unknown\n";
    }

    lsEntry.Exit();
    return 0;
}

