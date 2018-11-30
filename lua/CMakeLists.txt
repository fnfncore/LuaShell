aux_source_directory(src LUA_SOURCES)
list(REMOVE_ITEM LUA_SOURCES "src/lua.c" "src/luac.c")

add_library(lua ${LUA_SOURCES})

