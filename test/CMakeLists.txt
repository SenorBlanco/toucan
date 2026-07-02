# test/CMakeLists.txt

if(BUILD_TESTS)
  toucan_executable(empty SOURCES empty.t)
  toucan_executable(hello SOURCES hello.t)
endif()
