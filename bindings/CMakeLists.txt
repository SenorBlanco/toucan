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

if(EMSCRIPTEN)
  set(API_HEADER_GEN_BINARY "${CMAKE_CURRENT_BINARY_DIR}/api_header_generator")
  set(PARSER_SOURCES
    "${CMAKE_BINARY_DIR}/parser/parser.tab.cc"
    "${CMAKE_BINARY_DIR}/parser/lexer.cc"
  )
  add_custom_command(
    OUTPUT ${API_HEADER_GEN_BINARY}
    COMMAND /usr/bin/c++ -std=c++20
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_BINARY_DIR}/parser
            ${CMAKE_CURRENT_SOURCE_DIR}/api_header_generator_main.cc
            ${CMAKE_CURRENT_SOURCE_DIR}/api_header_generator.cc
            ${AST_SOURCES}
            ${PARSER_SOURCES}
            -o ${API_HEADER_GEN_BINARY}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/api_header_generator_main.cc
            ${CMAKE_CURRENT_SOURCE_DIR}/api_header_generator.cc
            ${AST_SOURCES}
            ${PARSER_SOURCES}
            parser
    COMMENT "Building host executable api_header_generator for WASM build"
  )
  add_custom_target(api_header_generator DEPENDS ${API_HEADER_GEN_BINARY})
else()
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

  if(WIN32)
    target_include_directories(api_header_generator PRIVATE
      ${CMAKE_SOURCE_DIR}/third_party/getopt
    )
  endif()
endif()
