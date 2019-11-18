set(NRF52_CMAKE_DIR ${CMAKE_CURRENT_LIST_DIR})

#-- GCC toolchain --------------------------------------------------------------
macro(nrf52_toolchain_setup)
    # include toolchain file
    include(${NRF52_CMAKE_DIR}/gcc_nrf52.cmake)
endmacro()

#-- NRF52 basic setup ----------------------------------------------------------
macro(nrf52_setup NRF52_CHIP)
    # toolchain should be configured
    if(NOT DEFINED GCC_TOOLCHAIN)
        message(FATAL_ERROR "The toolchain must be configured before calling this macro!")
    endif()

    # prepare SDK path
    if(NOT NRF5_SDK_PATH)
        message(STATUS "NRF5_SDK_PATH variable is not set. Try to check if environment variable NRF5SDKPATH is defined.")
        set(NRF5_SDK_PATH $ENV{NRF5SDKPATH})
        if(NOT NRF5_SDK_PATH)
            message(FATAL_ERROR "NRF5 SDK path not found!")
        else()
            message(STATUS "NRF5 SDK path: ${NRF5_SDK_PATH}")
        endif()
    else()
        message(STATUS "NRF5 SDK path: ${NRF5_SDK_PATH}")
    endif()

    # check nrfjprog
    if(NOT NRFJPROG)
        message(STATUS "NRFJPROG variable is not set. Will use global PATH.")
        set(NRFJPROG nrfjprog)
    endif()

    # add nrf52 generic defines
    add_definitions(-DNRF52 -D${NRF52_CHIP} -DNRF52_PAN_74 -DNRF52_PAN_64 -DNRF52_PAN_12 -DNRF52_PAN_58 -DNRF52_PAN_54 -DNRF52_PAN_31 -DNRF52_PAN_51 -DNRF52_PAN_36 -DNRF52_PAN_15 -DNRF52_PAN_20 -DNRF52_PAN_55)
    add_definitions(-DFLOAT_ABI_HARD)
    add_definitions(-D__HEAP_SIZE=${NRF52_HEAP_SIZE} -D__STACK_SIZE=${NRF52_STACK_SIZE})

    # add nrf52 generic system files
    list(APPEND SDK_SOURCE_FILES
        ${NRF5_SDK_PATH}/modules/nrfx/mdk/system_nrf52.c
        ${NRF5_SDK_PATH}/modules/nrfx/mdk/gcc_startup_nrf52.S)

    # add nrf52 generic includes
    include_directories(${NRF5_SDK_PATH}/modules/nrfx/mdk)
    include_directories(${NRF5_SDK_PATH}/components)
    include_directories(${NRF5_SDK_PATH}/components/toolchain/cmsis/include)

    # prepare linker script
    if(NOT NRF52_LINKER_SCRIPT)
        message(STATUS "NRF52_LINKER_SCRIPT variable is not set. Will use ./gcc_nrf52.ld")
        set(NRF52_LINKER_SCRIPT ${CMAKE_SOURCE_DIR}/gcc_nrf52.ld)
    else()
        message(STATUS "NRF52_LINKER_SCRIPT used: ${NRF52_LINKER_SCRIPT}")
    endif()

    # add nrf52 linker script
    link_directories(${NRF5_SDK_PATH}/modules/nrfx/mdk)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -T${NRF52_LINKER_SCRIPT} -Wl,-Map=${CMAKE_BINARY_DIR}/${PROJECT_NAME}.map -Wl,--print-memory-usage")
endmacro()

#-- NRF52 executable -----------------------------------------------------------
macro(nrf52_add_exec SOURCE_FILES)
    # create project executable
    add_executable(${PROJECT_NAME}.elf ${SDK_SOURCE_FILES} ${SOURCE_FILES})
    target_link_libraries(${PROJECT_NAME}.elf)

    # add post-build comand to calculate section size and create .hex, .bin and disasm files
    add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} "-Oihex" ${PROJECT_NAME}.elf ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.hex
        COMMAND ${CMAKE_OBJCOPY} "-Obinary" ${PROJECT_NAME}.elf ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.bin
        COMMAND ${CMAKE_OBJDUMP} "-DS" ${PROJECT_NAME}.elf > ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.dasm
        COMMAND ${CMAKE_SIZE} ${PROJECT_NAME}.elf)

    # add target to erase all flash with nrfjprog
    add_custom_target("NRFJPROG_ERASE_ALL"
                COMMAND ${NRFJPROG} --eraseall
                COMMAND sleep 0.5s
                COMMAND ${NRFJPROG} --reset -f nrf52
                COMMENT "All flash erasing")

    # add target to program executable with nrfjprog
    add_custom_target("NRFJPROG_PROGRAM_HEX"
                DEPENDS ${PROJECT_NAME}.elf
                COMMAND ${NRFJPROG} --program ${PROJECT_NAME}.hex -f nrf52 --sectorerase
                COMMAND sleep 0.5s
                COMMAND ${NRFJPROG} --reset -f nrf52
                COMMENT "Programming ${PROJECT_NAME}.hex")
endmacro()

#-- SDK: Utils -----------------------------------------------------------------
macro(nrf52_add_utils)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/util)

    file(GLOB SDK_UTIL_SRC ${NRF5_SDK_PATH}/components/libraries/util/*.c)
    list(FILTER SDK_UTIL_SRC EXCLUDE REGEX "(.*_iar.c$|.*_keil.c$)")
    list(APPEND SDK_SOURCE_FILES
        ${SDK_UTIL_SRC})
endmacro()

#-- SDK: Boards ----------------------------------------------------------------
macro(nrf52_add_boards)
    include_directories(
        ${NRF5_SDK_PATH}/components/boards)

    file(GLOB SDK_BOARDS_SRC ${NRF5_SDK_PATH}/components/boards/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_BOARDS_SRC})
endmacro()

#-- SDK: Peripheral drivers NRFX -----------------------------------------------
macro(nrf52_add_nrfx)
    include_directories(
        ${NRF5_SDK_PATH}/components/drivers_nrf/nrf_soc_nosd
        ${NRF5_SDK_PATH}/integration/nrfx
        ${NRF5_SDK_PATH}/modules/nrfx
        ${NRF5_SDK_PATH}/modules/nrfx/drivers
        ${NRF5_SDK_PATH}/modules/nrfx/drivers/src/prs
        ${NRF5_SDK_PATH}/modules/nrfx/drivers/include
        ${NRF5_SDK_PATH}/modules/nrfx/soc
        ${NRF5_SDK_PATH}/modules/nrfx/hal)

    file(GLOB SDK_NRFX_DRIVERS_SRC ${NRF5_SDK_PATH}/modules/nrfx/drivers/src/*.c)
    list(APPEND SDK_NRFX_DRIVERS_SRC
        ${NRF5_SDK_PATH}/modules/nrfx/drivers/src/prs/nrfx_prs.c)
    file(GLOB SDK_NRFX_SOC_SRC ${NRF5_SDK_PATH}/modules/nrfx/soc/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_NRFX_DRIVERS_SRC}
        ${SDK_NRFX_SOC_SRC})
endmacro()

#-- SDK: Peripheral drivers NRFX (legacy) --------------------------------------
macro(nrf52_add_nrfx_legacy)
    include_directories(
        ${NRF5_SDK_PATH}/integration/nrfx/legacy)

    list(APPEND SDK_NRFX_LEGACY_SRC
        ${NRF5_SDK_PATH}/integration/nrfx/legacy/nrf_drv_uart.c
        ${NRF5_SDK_PATH}/integration/nrfx/legacy/nrf_drv_clock.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_NRFX_DRIVERS_SRC})
endmacro()

#-- SDK: Library Delay ---------------------------------------------------------
macro(nrf52_add_lib_delay)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/delay)
endmacro()

#-- SDK: Library Log -----------------------------------------------------------
macro(nrf52_add_lib_log)
    include_directories(rs
        ${NRF5_SDK_PATH}/components/libraries/log
        ${NRF5_SDK_PATH}/components/libraries/log/src)

    file(GLOB SDK_LIB_LOG_SRC ${NRF5_SDK_PATH}/components/libraries/log/src/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_LIB_LOG_SRC})
endmacro()

#-- SDK: Library Experimental Section Vars -------------------------------------
macro(nrf52_add_lib_expsvars)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/experimental_section_vars)

    file(GLOB SDK_LIB_EXPSVARS_SRC ${NRF5_SDK_PATH}/components/libraries/experimental_section_vars/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_LIB_EXPSVARS_SRC})
endmacro()

#-- SDK: Library Strerror ------------------------------------------------------
macro(nrf52_add_lib_strerror)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/strerror)

    file(GLOB SDK_LIB_STRERROR_SRC ${NRF5_SDK_PATH}/components/libraries/strerror/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_LIB_STRERROR_SRC})
endmacro()

#-- SDK: Library BSP -----------------------------------------------------------
macro(nrf52_add_lib_bsp WITH_NFC WITH_BTN_BLE WITH_BTN_ANT)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/bsp)

    list(APPEND SDK_SOURCE_FILES
        ${NRF5_SDK_PATH}/components/libraries/bsp/bsp.c)

    if (${WITH_BTN_BLE})
        list(APPEND SDK_SOURCE_FILES
            ${NRF5_SDK_PATH}/components/libraries/bsp/bsp_btn_ble.c)
    endif ()

    if (${WITH_BTN_ANT})
        list(APPEND SDK_SOURCE_FILES
            ${NRF5_SDK_PATH}/components/libraries/bsp/bsp_btn_ant.c)
    endif ()

    if (${WITH_NFC})
        list(APPEND SDK_SOURCE_FILES
            ${NRF5_SDK_PATH}/components/libraries/bsp/bsp_nfc.c)
    endif ()
endmacro()

#-- SDK: Library Timer ---------------------------------------------------------
macro(nrf52_add_lib_timer WITH_TMR_FREERTOS WITH_TMR_RTX)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/timer)

    list(APPEND SDK_SOURCE_FILES
        ${NRF5_SDK_PATH}/components/libraries/timer/app_timer.c)

    if (${WITH_TMR_FREERTOS})
        list(APPEND SDK_SOURCE_FILES
            ${NRF5_SDK_PATH}/components/libraries/timer/app_timer_freertos.c)
    endif ()

    if (${WITH_TMR_RTX})
        list(APPEND SDK_SOURCE_FILES
            ${NRF5_SDK_PATH}/components/libraries/timer/app_timer_rtx.c)
    endif ()
endmacro()

#-- SDK: Library Button --------------------------------------------------------
macro(nrf52_add_lib_button)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/button)

    file(GLOB SDK_LIB_BUTTON_SRC ${NRF5_SDK_PATH}/components/libraries/button/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_LIB_BUTTON_SRC})
endmacro()

#-- SDK: Library Scheduler -----------------------------------------------------
macro(nrf52_add_lib_scheduler)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/scheduler)

    list(APPEND SDK_SOURCE_FILES
        ${NRF5_SDK_PATH}/components/libraries/scheduler/app_scheduler.c)
endmacro()

#-- SDK: Library FIFO ----------------------------------------------------------
macro(nrf52_add_lib_fifo)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/fifo)

    list(APPEND SDK_SOURCE_FILES
        ${NRF5_SDK_PATH}/components/libraries/fifo/app_fifo.c)
endmacro()

#-- SDK: Library UART ----------------------------------------------------------
macro(nRF5x_addAppUART)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/uart)

    list(APPEND SDK_SOURCE_FILES
        ${NRF5_SDK_PATH}/components/libraries/uart/app_uart_fifo.c)
endmacro()

#-- SDK: Library Memobj --------------------------------------------------------
macro(nrf52_add_lib_memobj)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/memobj)

    file(GLOB SDK_LIB_MEMOBJ_SRC ${NRF5_SDK_PATH}/components/libraries/memobj/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_LIB_MEMOBJ_SRC})
endmacro()

#-- SDK: Library Balloc --------------------------------------------------------
macro(nrf52_add_lib_balloc)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/balloc)

    file(GLOB SDK_LIB_BALLOC_SRC ${NRF5_SDK_PATH}/components/libraries/balloc/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_LIB_BALLOC_SRC})
endmacro()

#-- SDK: Library Atomic --------------------------------------------------------
macro(nrf52_add_lib_atomic)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/atomic)

    file(GLOB SDK_LIB_ATOMIC_SRC ${NRF5_SDK_PATH}/components/libraries/atomic/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_LIB_ATOMIC_SRC})
endmacro()

#-- SDK: Library Ringbuf -------------------------------------------------------
macro(nrf52_add_lib_ringbuf)
    include_directories(
        ${NRF5_SDK_PATH}/components/libraries/ringbuf)

    file(GLOB SDK_LIB_RINGBUF_SRC ${NRF5_SDK_PATH}/components/libraries/ringbuf/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_LIB_RINGBUF_SRC})
endmacro()

#-- SDK: External Fprintf ------------------------------------------------------
macro(nrf52_add_ext_fprintf)
    include_directories(
        ${NRF5_SDK_PATH}/external/fprintf)

    file(GLOB SDK_EXT_FPRINTF_SRC ${NRF5_SDK_PATH}/external/fprintf/*.c)
    list(APPEND SDK_SOURCE_FILES
        ${SDK_EXT_FPRINTF_SRC})
endmacro()

#-- SDK: External SEGGER RTT ---------------------------------------------------
macro(nrf52_add_ext_segger_rtt)
    include_directories(
        ${NRF5_SDK_PATH}/external/segger_rtt)

    list(APPEND SDK_SOURCE_FILES
        ${NRF5_SDK_PATH}/external/segger_rtt/SEGGER_RTT.c
        ${NRF5_SDK_PATH}/external/segger_rtt/SEGGER_RTT_Syscalls_GCC.c
        ${NRF5_SDK_PATH}/external/segger_rtt/SEGGER_RTT_printf.c)
endmacro()
