# parser/CMakeLists.txt

find_package(FLEX REQUIRED)
find_package(BISON REQUIRED)

set(BISON_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set(BISON_TAB_CC "${BISON_OUTPUT_DIR}/parser.tab.cc")
set(BISON_TAB_HH "${BISON_OUTPUT_DIR}/parser.tab.hh")
set(FLEX_LEXER_CC "${CMAKE_CURRENT_BINARY_DIR}/lexer.cc")

add_custom_command(
  OUTPUT ${BISON_TAB_CC} ${BISON_TAB_HH}
  COMMAND ${BISON_EXECUTABLE} -v -d -b ${BISON_OUTPUT_DIR}/parser ${CMAKE_CURRENT_SOURCE_DIR}/parser.yy
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/parser.yy
  COMMENT "Generating Bison parser"
)

add_custom_command(
  OUTPUT ${FLEX_LEXER_CC}
  COMMAND ${FLEX_EXECUTABLE} -o${FLEX_LEXER_CC} ${CMAKE_CURRENT_SOURCE_DIR}/lexer.ll
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/lexer.ll
  COMMENT "Generating Flex lexer"
)

add_library(parser STATIC
  ${BISON_TAB_CC}
  ${FLEX_LEXER_CC}
)

target_include_directories(parser PUBLIC
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(parser PRIVATE -Wno-sign-compare -Wno-unused-function)
elseif(MSVC)
  target_compile_options(parser PRIVATE /wd4018 /wd4102)
endif()
