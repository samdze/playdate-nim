#
# Template CMakeLists.txt, customize it if necessary
#
# Variables:
# $ENV{PLAYDATE_PROJECT_NAME}: the project name
# $ENV{PLAYDATE_MODULE_DIR}: the path to the installed playdate Nim module
# $ENV{NIM_CACHE_DIR}: the path to the project Nim cache files
# $ENV{NIM_C_SOURCE_FILES}: list of semicolon-separated, Nim-generated C files that have to be compiled
# $ENV{NIM_INCLUDE_DIR}: the path to required Nim header files

cmake_minimum_required(VERSION 3.14)
set(CMAKE_OSX_ARCHITECTURES x86_64 arm64 CACHE STRING "" FORCE)
set(CMAKE_C_STANDARD 11)

# Setup the project and its name from the environment
project($ENV{PLAYDATE_PROJECT_NAME} C ASM)

# Include the playdate module CMake configuration, this defines the targets
include($ENV{PLAYDATE_MODULE_DIR}/playdate.cmake)

# Targets:
# ${PLAYDATE_GAME_NAME}: simulator
# ${PLAYDATE_GAME_DEVICE}: device