# Copyright 2026 The Toucan Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.20)

if(CMAKE_GENERATOR STREQUAL "Ninja")
  set(CMAKE_MAKE_PROGRAM ${CMAKE_SOURCE_DIR}/third_party/ninja/ninja CACHE FILEPATH "" FORCE)
endif()

project(Toucan CXX C)

# Build all executables and dynamic libs in the root output directory.
# This matches the GN build.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

if(WIN32)
  set(FLEX_EXECUTABLE ${CMAKE_SOURCE_DIR}/third_party/winflexbison/win_flex.exe)
  set(BISON_EXECUTABLE ${CMAKE_SOURCE_DIR}/third_party/winflexbison/win_bison.exe)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_POLICY_VERSION_MINIMUM "3.5")
# CMake 3.31+ reserves "codegen" as a built-in target name. Set CMP0171 to OLD
# to permit Toucan's target library named "codegen".
if(POLICY CMP0171)
  cmake_policy(SET CMP0171 OLD)
endif()

option(BUILD_SAMPLES "Build Toucan samples" ON)
option(BUILD_TESTS "Build Toucan tests" ON)

add_compile_definitions("STACK_SIZE=4194304")
if(MSVC)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /STACK:4194304")
endif()

find_package(JPEG QUIET)
if(JPEG_FOUND)
  message(STATUS "Found system JPEG: ${JPEG_LIBRARIES}")
else()
  message(STATUS "JPEG not found on system. Building libjpeg-turbo via ExternalProject.")

  include(ExternalProject)

  set(JPEG_TURBO_PREFIX "${CMAKE_BINARY_DIR}/third_party/libjpeg-turbo")
  set(JPEG_TURBO_INSTALL "${JPEG_TURBO_PREFIX}/install")

  if(WIN32)
    set(JPEG_LIB_NAME jpeg-static.lib)
  else()
    set(JPEG_LIB_NAME libjpeg.a)
  endif()
  set(JPEG_LIBRARY "${JPEG_TURBO_INSTALL}/lib/${JPEG_LIB_NAME}")

  set(TOUCAN_CMAKE_ARGS
      -D CMAKE_INSTALL_PREFIX=${JPEG_TURBO_INSTALL}
      -D ENABLE_SHARED=OFF
      -D ENABLE_STATIC=ON
      -D WITH_TURBOJPEG=OFF
      -D WITH_JPEG8=ON
      -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -D CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
      -D CMAKE_POLICY_VERSION_MINIMUM=${CMAKE_POLICY_VERSION_MINIMUM}
      -G ${CMAKE_GENERATOR}
  )
  if (DEFINED CMAKE_TOOLCHAIN_FILE)
    list(APPEND TOUCAN_CMAKE_ARGS -D CMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
  endif()
  if(ANDROID)
    list(APPEND TOUCAN_CMAKE_ARGS
      -D ANDROID_PLATFORM=${ANDROID_PLATFORM}
      -D ANDROID_ABI=${ANDROID_ABI}
    )
  elseif(IOS)
    list(APPEND TOUCAN_CMAKE_ARGS
      -D CMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
      -D CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
      -D CMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}
    )
  endif()

  ExternalProject_Add(jpeg_turbo
    SOURCE_DIR  ${CMAKE_SOURCE_DIR}/third_party/libjpeg-turbo
    BUILD_BYPRODUCTS ${JPEG_LIBRARY}
    CMAKE_ARGS ${TOUCAN_CMAKE_ARGS}
    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD TRUE
  )

  list(APPEND CMAKE_PREFIX_PATH "${JPEG_TURBO_INSTALL}")
  set(JPEG_INCLUDE_DIR "${JPEG_TURBO_INSTALL}/include")
  set(JPEG_FOUND TRUE)

  file(MAKE_DIRECTORY ${JPEG_INCLUDE_DIR})

  add_library(JPEG::JPEG STATIC IMPORTED GLOBAL)

  set_target_properties(JPEG::JPEG PROPERTIES
    IMPORTED_LOCATION             "${JPEG_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${JPEG_INCLUDE_DIR}"
  )
endif()

set(DAWN_FETCH_DEPENDENCIES ON)
set(DAWN_BUILD_MONOLITHIC_LIBRARY SHARED)
set(DAWN_SUPPORTS_CXX_MODULES False)
set(DAWN_BUILD_PROTOBUF False)
set(DAWN_BUILD_TESTS OFF)
set(DAWN_BUILD_SAMPLES OFF)
set(DAWN_USE_GLFW OFF)
set(DAWN_FORCE_SYSTEM_COMPONENT_LOAD ON)

if(WIN32)
  set(DAWN_ENABLE_VULKAN OFF)
endif()

set(TINT_BUILD_CMD_TOOLS OFF)
set(TINT_BUILD_TESTS OFF)
if(NOT EMSCRIPTEN)
  set(TINT_BUILD_SPV_READER ON)
endif()
set(TINT_BUILD_IR_BINARY False)

find_package(Python3 REQUIRED COMPONENTS Interpreter)

if(NOT CMAKE_CROSSCOMPILING)
  if (NOT WIN32)
    set(LLVM_DIR "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/${CMAKE_BUILD_TYPE}")
  else()
    set(LLVM_DIR "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/lib/cmake")
  endif()

  find_package(LLVM REQUIRED CONFIG
               COMPONENTS engine mcjit x86codegen armcodegen aarch64codegen webassemblycodegen
               HINTS ${LLVM_DIR})

  set(LLVM_LIBS LLVM)
  if(WIN32)
    set(LLVM_LIBS
      LLVMWebAssemblyCodeGen
      LLVMWebAssemblyUtils
      LLVMWebAssemblyDesc
      LLVMWebAssemblyInfo
      LLVMAArch64CodeGen
      LLVMPasses
      LLVMHipStdPar
      LLVMCoroutines
      LLVMAArch64Desc
      LLVMAArch64Utils
      LLVMAArch64Info
      LLVMARMCodeGen
      LLVMipo
      LLVMVectorize
      LLVMSandboxIR
      LLVMLinker
      LLVMFrontendOpenMP
      LLVMFrontendDirective
      LLVMFrontendAtomic
      LLVMFrontendOffloading
      LLVMObjectYAML
      LLVMARMDesc
      LLVMARMUtils
      LLVMARMInfo
      LLVMX86CodeGen
      LLVMX86Desc
      LLVMX86Info
      LLVMMCDisassembler
      LLVMInstrumentation
      LLVMIRPrinter
      LLVMGlobalISel
      LLVMSelectionDAG
      LLVMCFGuard
      LLVMAsmPrinter
      LLVMMCJIT
      LLVMInterpreter
      LLVMExecutionEngine
      LLVMRuntimeDyld
      LLVMOrcTargetProcess
      LLVMOrcShared
      LLVMCodeGen
      LLVMTarget
      LLVMScalarOpts
      LLVMInstCombine
      LLVMAggressiveInstCombine
      LLVMObjCARCOpts
      LLVMTransformUtils
      LLVMCodeGenTypes
      LLVMCGData
      LLVMBitWriter
      LLVMAnalysis
      LLVMProfileData
      LLVMSymbolize
      LLVMDebugInfoBTF
      LLVMDebugInfoPDB
      LLVMDebugInfoMSF
      LLVMDebugInfoCodeView
      LLVMDebugInfoGSYM
      LLVMDebugInfoDWARF
      LLVMObject
      LLVMTextAPI
      LLVMMCParser
      LLVMIRReader
      LLVMAsmParser
      LLVMMC
      LLVMDebugInfoDWARFLowLevel
      LLVMBitReader
      LLVMFrontendHLSL
      LLVMCore
      LLVMRemarks
      LLVMBitstreamReader
      LLVMBinaryFormat
      LLVMTargetParser
      LLVMSupport
      LLVMDemangle
    )
  endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}")
include(ToucanExecutable)

set(BUILD_SHARED_LIBS OFF)
add_subdirectory(third_party/dawn EXCLUDE_FROM_ALL)
add_subdirectory(parser EXCLUDE_FROM_ALL)
add_subdirectory(ast EXCLUDE_FROM_ALL)
add_subdirectory(bindings EXCLUDE_FROM_ALL)
add_subdirectory(api EXCLUDE_FROM_ALL)
add_subdirectory(codegen EXCLUDE_FROM_ALL)
add_subdirectory(compilers)
add_subdirectory(samples)
add_subdirectory(test)
if(EMSCRIPTEN)
add_subdirectory(emscripten)
endif()
if(ANDROID)
add_subdirectory(third_party/android_native_app_glue EXCLUDE_FROM_ALL)
endif()
