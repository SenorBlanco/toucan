cmake_minimum_required(VERSION 3.20)

project(Toucan CXX C)

if(WIN32)
  set(FLEX_EXECUTABLE ${CMAKE_SOURCE_DIR}/third_party/winflexbison/win_flex.exe)
  set(BISON_EXECUTABLE ${CMAKE_SOURCE_DIR}/third_party/winflexbison/win_bison.exe)
  add_compile_definitions(TARGET_OS_IS_WIN=1)
elseif(APPLE)
  if(IOS)
    add_compile_definitions(TARGET_OS_IS_IOS=1)
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    add_compile_definitions(TARGET_OS_IS_MAC=1)
  endif()
elseif(EMSCRIPTEN)
  add_compile_definitions(TARGET_OS_IS_WASM=1)
elseif(IOS)
  add_compile_definitions(TARGET_OS_IS_IOS=1)
elseif(ANDROID)
  add_compile_definitions(TARGET_OS_IS_ANDROID=1)
elseif(UNIX)
  add_compile_definitions(TARGET_OS_IS_LINUX=1)
endif()

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
if(NOT EMSCRIPTEN)
  set(TINT_BUILD_SPV_READER ON)
endif()

if(EMSCRIPTEN)
  set(CMAKE_CXX_FLAGS_RELEASE "-O1" CACHE STRING "Flags used by the C++ compiler during Release builds." FORCE)
  set(CMAKE_C_FLAGS_RELEASE "-O1" CACHE STRING "Flags used by the C compiler during Release builds." FORCE)
endif()

find_package(Python3 REQUIRED COMPONENTS Interpreter)

if(NOT EMSCRIPTEN)
  find_package(LLVM REQUIRED CONFIG COMPONENTS engine mcjit x86codegen armcodegen aarch64codegen webassemblycodegen HINTS
    "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/${CMAKE_BUILD_TYPE}"
  )

  message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
  message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")
  if (NOT WIN32)
    set(LLVM_LIBS LLVM)
  else()
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
