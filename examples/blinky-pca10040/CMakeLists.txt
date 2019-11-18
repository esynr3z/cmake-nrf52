#-- Global configuration -------------------------------------------------------
cmake_minimum_required(VERSION 3.8.0)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# By default env var NRF5SDKPATH used, uncomment to set your path
set(NRF5_SDK_PATH /opt/nrf5/nRF5_SDK_15.3.0_59ac345)

# By default global PATH used, uncomment to set your path
#set(NRFJPROG /opt/nrf5/nrfjprog/nrfjprog)

# By default global PATH used, uncomment to set your path
#set(GCC_TOOLCHAIN_BIN_PATH /opt/gcc-arm-none-eabi-7-2017-q4-major/bin)

# Will be "./cmake-nrf52/nrf52.cmake" in typical project
include("../../nrf52.cmake")

# By default gcc_nrf52.ld in project root used, uncomment to set your script
set(NRF52_LINKER_SCRIPT ${NRF5_SDK_PATH}/examples/peripheral/blinky/pca10040/blank/armgcc/blinky_gcc_nrf52.ld)

#-- NRF52 setup ----------------------------------------------------------------
# Change parameters if needed
set(NRF52_HEAP_SIZE 8192)
set(NRF52_STACK_SIZE 8192)

# Prepare NRF52 generic things
nrf52_toolchain_setup()
nrf52_setup("NRF52832_XXAA")

# Add NRF52 libraries
nrf52_add_utils()
nrf52_add_boards()
nrf52_add_nrfx()
nrf52_add_lib_delay()
nrf52_add_lib_log()
nrf52_add_lib_strerror()
nrf52_add_lib_expsvars()

#-- Project init ---------------------------------------------------------------
project(blinky-pca10040 C ASM)

#-- Project defines ------------------------------------------------------------
add_definitions(-DCONFIG_GPIO_AS_PINRESET)
add_definitions(-DBOARD_PCA10040)
add_definitions(-DBSP_DEFINES_ONLY)

#-- Project paths --------------------------------------------------------------
set(PROJ_SRC_PATH ${NRF5_SDK_PATH}/examples/peripheral/blinky)

#-- Project includes -----------------------------------------------------------
include_directories(${PROJ_SRC_PATH})
include_directories(${PROJ_SRC_PATH}/pca10040/blank/config)

#-- Project sources ------------------------------------------------------------
FILE(GLOB PROJ_SRC ${PROJ_SRC_PATH}/*.c)

#-- Project executable ---------------------------------------------------------
nrf52_add_exec("${PROJ_SRC}")
