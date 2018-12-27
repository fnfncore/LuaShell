# LuaShell
A LUA shell for fnfn RPC.  
There are two usage: 
1. Run `luashell` to use it like a lua explanation (See [**Shell Console**](#shell-console))
2. Run `luashell ...` to execute a .lua file (See [**Execute File**](#execute-file))

## Setup
1. cd LuaShell
2. ./INSTALL.sh


## Usage
### Shell Console
```
$ luashell
fnfn>rpc = require "rpc"
fnfn>rpc.listkey()
```

### Execute File
```
$ luashell exec run 0
$ luashell exec stop 0 10
```

## How to add script
1. In `script/lua/` directory, add a new lua file.
2. Copy the lua file to ~/.luashell/lua/, or execute `INSTALL.sh`.
3. Use it (See [**Usage**](#usage))
4. Example:
    eg1.lua: 
    ```
    --
    -- eg1.lua
    --
    local eg1 = { _version = "0.1" }

    function eg1.print()
    print("eg1")
    end

    return eg1

    ```
    eg2.lua: 
    ```
    --
    -- eg2.lua
    --

    print("eg2")
    ```

    After `./INSTALL.sh`: 
    ```
    $ luashell
    fnfn>eg1 = require "eg1"
    fnfn>eg1.print()
    eg1
    ```
    ```
    $ luashell eg2
    eg2
    ```

