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
    include_directories(${NRF5_SDK_PATH}/components/toolchain/cmsis/include)

    # prepare linker script
    if(NOT NRF52_LINKER_SCRIPT)
        message(STATUS "NRF52_LINKER_SCRIPT variable is not set. Will use ./gcc_nrf52.ld")
        set(NRF52_LDSCRIPT ${CMAKE_SOURCE_DIR}/gcc_nrf52.ld)
    else()
        message(STATUS "NRF52_LINKER_SCRIPT used: ${NRF52_LINKER_SCRIPT}")
    endif()

    # add nrf52 linker script
    link_directories(${NRF5_SDK_PATH}/modules/nrfx/mdk)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -T${NRF52_LDSCRIPT} -Wl,-Map=${CMAKE_BINARY_DIR}/${PROJECT_NAME}.map -Wl,--print-memory-usage")
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
