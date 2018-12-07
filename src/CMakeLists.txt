#------------------------------------------------------------------------------
# CMake file for TxDataDemo
#
# Copyright (c) 2016 The Multiverse developers
# Distributed under the MIT/X11 software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
#------------------------------------------------------------------------------

set(src
	luashell.cpp
	config.cpp config.h
	entry.cpp entry.h
	rpcclient.cpp rpcclient.h
	luajson.cpp luajson.h
	interactive.cpp interactive.h
)
set(sources
	${src}
)


add_executable(luashell ${sources})

include_directories(../walleve ../lua/src ./)

target_link_libraries(luashell
	Boost::system
	Boost::filesystem
	Boost::program_options
	Boost::thread
	Boost::date_time
	Boost::regex
	OpenSSL::SSL
	OpenSSL::Crypto
	${Readline_LIBRARY}
	walleve
	lua
)

# install to path
install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/luashell"
	DESTINATION bin)