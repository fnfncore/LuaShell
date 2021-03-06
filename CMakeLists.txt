#------------------------------------------------------------------------------
# CMake file for LuaShell
#
# Copyright (c) 2016 The Multiverse developers
# Distributed under the MIT/X11 software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
#------------------------------------------------------------------------------

project(LuaShell)

cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}/cmake" CACHE PATH "The path to the cmake directory")
list(APPEND CMAKE_MODULE_PATH ${CMAKE_DIR})

# support c++14, c++14 is like a small patch for c++11
set(CMAKE_CXX_STANDARD 14)

# packages
set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_MULTITHREADED ON)
find_package(Boost 1.58.0 REQUIRED COMPONENTS
    program_options
    filesystem
    system
    thread
    date_time
    regex
    unit_test_framework
)
find_package(OpenSSL 1.0.0 REQUIRED) 
find_package(Readline 5.0 REQUIRED)

if(OPENSSL_VERSION VERSION_EQUAL 1.1.0 OR 
    (OPENSSL_VERSION VERSION_GREATER 1.1.0 AND OPENSSL_VERSION VERSION_LESS 1.2.0))
    add_definitions(-DUSE_SSL_110)
endif()

# libs
if(WIN32)
    add_definitions(-DWIN32_LEAN_AND_MEAN)
    find_library(WS2_32_LIB NAMES ws2_32)
    find_library(WSSOCK32_LIB NAMES wsock32)
endif()

# sub directories
add_subdirectory(src)
add_subdirectory(walleve)
add_subdirectory(lua)
