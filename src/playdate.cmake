#
# CMake include file for Playdate games
#
cmake_minimum_required(VERSION 3.19)

if (NOT $ENV{PLAYDATE_SDK_PATH} STREQUAL "")
	# Convert path from Windows
	file(TO_CMAKE_PATH $ENV{PLAYDATE_SDK_PATH} SDK)
else()
	execute_process(
			COMMAND bash -c "egrep '^\\s*SDKRoot' $HOME/.Playdate/config"
			COMMAND head -n 1
			COMMAND cut -c9-
			OUTPUT_VARIABLE SDK
			OUTPUT_STRIP_TRAILING_WHITESPACE
	)
endif()

if (NOT EXISTS ${SDK})
	message(FATAL_ERROR "SDK Path not found; set ENV value PLAYDATE_SDK_PATH")
	return()
endif()

set(CMAKE_CONFIGURATION_TYPES "Debug;Release")
set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

# Game Name Customization
set(PLAYDATE_GAME_NAME $ENV{PLAYDATE_PROJECT_NAME}_simulator)
set(PLAYDATE_GAME_DEVICE $ENV{PLAYDATE_PROJECT_NAME}_device)

# Include Nim required headers
include_directories($ENV{NIM_INCLUDE_DIR})

if (TOOLCHAIN STREQUAL "armgcc")
	add_executable(${PLAYDATE_GAME_DEVICE} $ENV{NIM_C_SOURCE_FILES})
	target_link_libraries(${PLAYDATE_GAME_DEVICE} rdimon c m gcc nosys)
else()
	add_library(${PLAYDATE_GAME_NAME} SHARED $ENV{NIM_C_SOURCE_FILES})
endif()

include(${SDK}/C_API/buildsupport/playdate.cmake)

set(BUILD_SUB_DIR "")

if (TOOLCHAIN STREQUAL "armgcc")
	set_property(TARGET ${PLAYDATE_GAME_DEVICE} PROPERTY OUTPUT_NAME "${PLAYDATE_GAME_DEVICE}.elf")

	add_custom_command(
		TARGET ${PLAYDATE_GAME_DEVICE} POST_BUILD
		COMMAND ${CMAKE_STRIP} --strip-unneeded -R .comment -g
		${PLAYDATE_GAME_DEVICE}.elf
		-o ${CMAKE_CURRENT_SOURCE_DIR}/source/pdex.elf
	)

	add_custom_command(
		TARGET ${PLAYDATE_GAME_DEVICE} POST_BUILD
		COMMAND ${PDC} source playdate.pdx
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	)

	set_property(
		TARGET ${PLAYDATE_GAME_DEVICE} PROPERTY ADDITIONAL_CLEAN_FILES
		${CMAKE_CURRENT_SOURCE_DIR}/playdate.pdx
	)

else ()
	if (MSVC)
		# MSVC not supported
		message(FATAL_ERROR "MSVC is not supported! Use MinGW.")

	elseif(MINGW)
		target_compile_definitions(${PLAYDATE_GAME_NAME} PUBLIC _WINDLL=1)
		set(DYLIB_EXT "dll")

	elseif(APPLE)
		target_sources(${PLAYDATE_GAME_NAME} PRIVATE ${SDK}/C_API/buildsupport/setup.c)
		set(DYLIB_EXT "dylib")

	elseif(UNIX)
		target_sources(${PLAYDATE_GAME_NAME} PRIVATE ${SDK}/C_API/buildsupport/setup.c)
		set(DYLIB_EXT "so")

	else()
		message(FATAL_ERROR "Platform not supported!")
	endif()

	add_custom_command(
		TARGET ${PLAYDATE_GAME_NAME} POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy
		${CMAKE_CURRENT_BINARY_DIR}/${BUILD_SUB_DIR}lib${PLAYDATE_GAME_NAME}.${DYLIB_EXT}
		${CMAKE_CURRENT_SOURCE_DIR}/source/pdex.${DYLIB_EXT})

	set_property(
		TARGET ${PLAYDATE_GAME_NAME} PROPERTY ADDITIONAL_CLEAN_FILES
		${CMAKE_CURRENT_SOURCE_DIR}/playdate.pdx
	)

	add_custom_command(
		TARGET ${PLAYDATE_GAME_NAME} POST_BUILD
		COMMAND ${PDC} ${CMAKE_CURRENT_SOURCE_DIR}/source
		${CMAKE_CURRENT_SOURCE_DIR}/playdate.pdx)

endif ()
