#
# Template CMakeLists.txt, customize it if necessary
#

cmake_minimum_required(VERSION 3.14)
set(CMAKE_C_STANDARD 11)

# Setup the project and its name from the environment
set(PLAYDATE_PROJECT_NAME $ENV{PROJECT})
project(${PLAYDATE_PROJECT_NAME} C ASM)

# Include the playdate module CMake configuration
include($ENV{PLAYDATE_MODULE}/playdate.cmake)