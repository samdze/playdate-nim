HEAP_SIZE      = 8388208
STACK_SIZE     = 61800

PRODUCT = HelloWorld.pdx

# Locate the SDK
SDK = ${PLAYDATE_SDK_PATH}
ifeq ($(SDK),)
	SDK = $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
endif

ifeq ($(SDK),)
$(error SDK path not found; set ENV value PLAYDATE_SDK_PATH)
endif

######
# IMPORTANT: You must add your source folders to VPATH for make to find them
# ex: VPATH += src1:src2
######

VPATH += .nim

# List C source files here
SRC = $(wildcard .nim/*.nim.c)

# List all user directories here
UINCDIR = src/playdate/include

# List user asm files
UASRC = 

# List all user C define here, like -D_DEBUG=1
UDEFS = -Wno-strict-aliasing -Wno-parentheses -fsingle-precision-constant

# Define ASM defines here
UADEFS = 

# List the user directory to look for the libraries here
ULIBDIR =

# List all user libraries here
ULIBS = -lrdimon -lc -lm -lgcc -lnosys

include $(SDK)/C_API/buildsupport/common.mk

