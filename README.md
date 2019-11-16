# cmake-nrf52

Minimalistic CMake script for easy NRF52 projects creation.

Current workflow was inspired by [Polidea/cmake-nRF5x](https://github.com/Polidea/cmake-nRF5x).

# Dependencies

- [Nordic Semiconductor nRF5 SDK](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK) - headers, drivers, libraries, examples
- [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) - compiler targeting Arm Cortex-M chips
- [Segger JLink](https://www.segger.com/downloads/jlink) - interface software for the JLink family of programmers
- [Nordic Semiconductor nRF Command Line Tools](https://www.nordicsemi.com/Software-and-Tools/Development-Tools/nRF-Command-Line-Tools) - nrfjprog used for programming NRF52

_Note_: last two are optional. OpenOCD can be used as alternative.

# Project

1. Clone this repo (or add as submodule) to the root directory of your your project

1. Select an example in ```cmake-nrf52/examples``` to start with.

1. Copy **the contents** of the example folder to project root.

1. Fix paths in ```Global configuration``` section of CMakeLists.txt.

1. Optionally add additional SDK libraries with CMake macros ```nrf52_add_xxx```.

1. Adjust the project - change name, add yours defines, sources and includes

_Note_: you can add `CXX` between `C ASM` to add C++ support

Typical project tree:

```
.
├── CMakeLists.txt
├── cmake-nrf52
│   ├── examples
│   ├── gcc_nrf52.cmake
│   ├── nrf52.cmake
│   └── README.md
├── gcc_nrf52.ld
└── src
    └── main.c
```

# Build

Run from project root to build release configuration:

```bash
mkdir build-release && cd build-release
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
```

_Note_: possible configurations are Debug, Release, RelWithDebIndo and MinSizeRel.

# Flash

To program your apllication:

```bash
cd build-release
cmake --build . --target NRFJPROG_PROGRAM_HEX
```

To full erase NRF52 flash:

```bash
cd build-release
cmake --build . --target NRFJPROG_ERASE_ALL
```
