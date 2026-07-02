# bindings/CMakeLists.txt

add_library(gen_bindings_sources STATIC
  gen_bindings.cc
)

target_include_directories(gen_bindings_sources PUBLIC
  ${CMAKE_SOURCE_DIR}
)

target_link_libraries(gen_bindings_sources PUBLIC
  ast
)

add_executable(api_header_generator
  api_header_generator_main.cc
  api_header_generator.cc
)

target_include_directories(api_header_generator PUBLIC
  ${CMAKE_SOURCE_DIR}
)

target_link_libraries(api_header_generator PRIVATE
  ast
  parser
)

if(EMSCRIPTEN)
  target_link_options(api_header_generator PRIVATE "--no-wasm-opt")
endif()

if(WIN32)
  target_include_directories(api_header_generator PRIVATE
    ${CMAKE_SOURCE_DIR}/third_party/getopt
  )
endif()
