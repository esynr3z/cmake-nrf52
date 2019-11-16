#-- System ---------------------------------------------------------------------
# Check if already run. Changing the compiler var can cause reconfigure so don't want to do it again.
if(DEFINED GCC_TOOLCHAIN)
    return()
endif()
set(GCC_TOOLCHAIN TRUE)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

#-- Toolchain ------------------------------------------------------------------
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
if(WIN32)
    set(TOOLCHAIN_EXECUTABLE_SUFFIX ".exe")
else()
    set(TOOLCHAIN_EXECUTABLE_SUFFIX "")
endif()

set(TOOLCHAIN_TRIPLET_PREFIX "arm-none-eabi-")

if (NOT DEFINED GCC_TOOLCHAIN_BIN_PATH)
    message(STATUS "GCC_TOOLCHAIN_BIN_PATH variable is not set. Will use global PATH.")
    set(GCC_TOOLCHAIN_BIN_PATH "")
else()
    set(GCC_TOOLCHAIN_BIN_PATH "${GCC_TOOLCHAIN_BIN_PATH}/")
endif ()

set(CMAKE_C_COMPILER "${GCC_TOOLCHAIN_BIN_PATH}${TOOLCHAIN_TRIPLET_PREFIX}gcc${TOOLCHAIN_EXECUTABLE_SUFFIX}")
set(CMAKE_CXX_COMPILER "${GCC_TOOLCHAIN_BIN_PATH}${TOOLCHAIN_TRIPLET_PREFIX}g++${TOOLCHAIN_EXECUTABLE_SUFFIX}")
set(CMAKE_ASM_COMPILER "${GCC_TOOLCHAIN_BIN_PATH}${TOOLCHAIN_TRIPLET_PREFIX}gcc${TOOLCHAIN_EXECUTABLE_SUFFIX}")
set(CMAKE_OBJCOPY "${GCC_TOOLCHAIN_BIN_PATH}${TOOLCHAIN_TRIPLET_PREFIX}objcopy${TOOLCHAIN_EXECUTABLE_SUFFIX}" CACHE STRING "objcopy tool")
set(CMAKE_OBJDUMP "${GCC_TOOLCHAIN_BIN_PATH}${TOOLCHAIN_TRIPLET_PREFIX}objdump${TOOLCHAIN_EXECUTABLE_SUFFIX}" CACHE STRING "objdump tool")
set(CMAKE_SIZE "${GCC_TOOLCHAIN_BIN_PATH}${TOOLCHAIN_TRIPLET_PREFIX}size${TOOLCHAIN_EXECUTABLE_SUFFIX}" CACHE STRING "size tool")

#-- Common flags ---------------------------------------------------------------
set(COMPILER_COMMON_FLAGS "-mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 -Wall -Wextra -ffunction-sections -fdata-sections -mlong-calls")
set(CMAKE_C_FLAGS "${COMPILER_COMMON_FLAGS} -std=gnu99" CACHE STRING "c compiler flags")
set(CMAKE_CXX_FLAGS "${COMPILER_COMMON_FLAGS} -std=c++11" CACHE STRING "c++ compiler flags")
set(CMAKE_ASM_FLAGS "-mthumb -mcpu=cortex-m4" CACHE STRING "assembler compiler flags")
set(CMAKE_EXE_LINKER_FLAGS "-mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 -mlong-calls -Wl,--gc-sections  -specs=nosys.specs -specs=nano.specs -lgcc -lc" CACHE STRING "executable linker flags")
set(CMAKE_MODULE_LINKER_FLAGS "-mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16" CACHE STRING "module linker flags")
set(CMAKE_SHARED_LINKER_FLAGS "-mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16" CACHE STRING "shared linker flags")

#-- Debug flags ----------------------------------------------------------------
set(CMAKE_C_FLAGS_DEBUG "-g -Og -DDEBUG" CACHE STRING "c compiler flags debug")
set(CMAKE_CXX_FLAGS_DEBUG "-g -Og -DDEBUG" CACHE STRING "c++ compiler flags debug")
set(CMAKE_ASM_FLAGS_DEBUG "-g" CACHE STRING "assembler compiler flags debug")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "" CACHE STRING "linker flags debug")

#-- Release flags --------------------------------------------------------------
set(CMAKE_C_FLAGS_RELEASE "-O2 " CACHE STRING "c compiler flags release")
set(CMAKE_CXX_FLAGS_RELEASE "-O2" CACHE STRING "c++ compiler flags release")
set(CMAKE_ASM_FLAGS_RELEASE "" CACHE STRING "assembler compiler flags release")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "" CACHE STRING "linker flags release")

#-- Release with debug info flags ----------------------------------------------
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-g -O2" CACHE STRING "c compiler flags release with debug info")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-g -O2" CACHE STRING "c++ compiler flags release with debug info")
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO "" CACHE STRING "assembler compiler flags release with debug info")
set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "" CACHE STRING "linker flags release with debug info")

#-- Minimum size release flags -------------------------------------------------
set(CMAKE_C_FLAGS_MINSIZEREL "-Os -flto -ffat-lto-objects" CACHE STRING "c compiler flags minimum size release")
set(CMAKE_CXX_FLAGS_MINSIZEREL "-Os -flto -ffat-lto-objects" CACHE STRING "c++ compiler flags minimum size release")
set(CMAKE_ASM_FLAGS_MINSIZEREL "" CACHE STRING "assembler compiler flags minimum size release")
set(CMAKE_EXE_LINKER_FLAGS_MINSIZEREL "-flto" CACHE STRING "linker flags minimum size release")
