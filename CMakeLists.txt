cmake_minimum_required(VERSION 3.20)

project(Toucan CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# CMake 3.31+ reserves "codegen" as a built-in target name. Set CMP0171 to OLD
# to permit Toucan's target library named "codegen".
if(POLICY CMP0171)
  cmake_policy(SET CMP0171 OLD)
endif()

option(BUILD_SAMPLES "Build Toucan samples" ON)
option(BUILD_TESTS "Build Toucan tests" OFF)

set(DAWN_BUILD_TESTS OFF)
set(DAWN_BUILD_SAMPLES OFF)
set(DAWN_USE_GLFW OFF)

set(TINT_BUILD_CMD_TOOLS OFF)
set(TINT_BUILD_TESTS OFF)

if(EMSCRIPTEN)
  set(CMAKE_CXX_FLAGS_RELEASE "-O1" CACHE STRING "Flags used by the C++ compiler during Release builds." FORCE)
  set(CMAKE_C_FLAGS_RELEASE "-O1" CACHE STRING "Flags used by the C compiler during Release builds." FORCE)
endif()

find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Locate LLVM
find_package(LLVM CONFIG HINTS
  "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/Debug"
  "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/Release"
  "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out"
  QUIET
)

if(LLVM_FOUND)
  message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
  message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")
  if(TARGET LLVM)
    set(LLVM_LIBRARIES LLVM)
  elseif(TARGET LLVM-dynamic)
    set(LLVM_LIBRARIES LLVM-dynamic)
  else()
    list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
    include(AddLLVM)
    llvm_map_components_to_libnames(LLVM_LIBRARIES
      core
      support
      executionengine
      mcjit
      target
      native
      webassemblycodegen
      webassemblydesc
      webassemblyinfo
    )
  endif()
else()
  message(STATUS "System/Prebuilt LLVM config not found directly via find_package. Setting fallback include paths.")
  set(LLVM_INCLUDE_DIRS
    "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/include"
    "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/Debug/include"
    "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/Release/include"
  )
  set(LLVM_LIBRARIES LLVM)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(ToucanMacros)

# CMAKE_INSTALL_DOCDIR is set to satisfy libjpeg-turbo's configure-time
# install() syntax check without requiring full GNUInstallDirs. Note that
# libjpeg-turbo does not actually build docs during compilation.
set(CMAKE_INSTALL_DOCDIR "doc")
set(ENABLE_SHARED OFF CACHE BOOL "Build shared libraries" FORCE)
set(ENABLE_STATIC ON CACHE BOOL "Build static libraries" FORCE)
set(WITH_SIMD OFF CACHE BOOL "Include SIMD extensions" FORCE)
set(WITH_TURBOJPEG OFF CACHE BOOL "Include TurboJPEG API" FORCE)
set(CMAKE_POLICY_VERSION_MINIMUM "3.5" CACHE STRING "Minimum policy version" FORCE)
add_subdirectory(third_party/dawn)
add_subdirectory(third_party/libjpeg-turbo EXCLUDE_FROM_ALL)
add_subdirectory(parser)
add_subdirectory(ast)
add_subdirectory(bindings)
add_subdirectory(api)
add_subdirectory(codegen)
add_subdirectory(compilers)
add_subdirectory(samples)
add_subdirectory(test)
