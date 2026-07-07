add_library(codegen STATIC
  codegen_llvm.cc
  codegen_spirv.cc
)

target_include_directories(codegen PUBLIC
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_BINARY_DIR}/bindings
  ${CMAKE_SOURCE_DIR}/third_party/SPIRV-Headers/include
)

target_include_directories(codegen PUBLIC ${LLVM_INCLUDE_DIRS})

target_link_libraries(codegen PUBLIC ast tint_api)
