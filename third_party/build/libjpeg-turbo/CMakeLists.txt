# third_party/build/libjpeg-turbo/CMakeLists.txt

set(LIBJPEG_DIR "${CMAKE_SOURCE_DIR}/third_party/libjpeg-turbo")

configure_file("${LIBJPEG_DIR}/jversion.h.in" "${CMAKE_CURRENT_BINARY_DIR}/jversion.h" COPYONLY)

add_library(libjpeg-turbo STATIC
  ${LIBJPEG_DIR}/jaricom.c
  ${LIBJPEG_DIR}/jcapimin.c
  ${LIBJPEG_DIR}/jcarith.c
  ${LIBJPEG_DIR}/jccoefct.c
  ${LIBJPEG_DIR}/jccolor.c
  ${LIBJPEG_DIR}/jcdctmgr.c
  ${LIBJPEG_DIR}/jchuff.c
  ${LIBJPEG_DIR}/jcicc.c
  ${LIBJPEG_DIR}/jcinit.c
  ${LIBJPEG_DIR}/jcmainct.c
  ${LIBJPEG_DIR}/jcmarker.c
  ${LIBJPEG_DIR}/jcmaster.c
  ${LIBJPEG_DIR}/jcomapi.c
  ${LIBJPEG_DIR}/jcparam.c
  ${LIBJPEG_DIR}/jcphuff.c
  ${LIBJPEG_DIR}/jcprepct.c
  ${LIBJPEG_DIR}/jcsample.c
  ${LIBJPEG_DIR}/jctrans.c
  ${LIBJPEG_DIR}/jdapimin.c
  ${LIBJPEG_DIR}/jdapistd.c
  ${LIBJPEG_DIR}/jdarith.c
  ${LIBJPEG_DIR}/jdatadst.c
  ${LIBJPEG_DIR}/jdatasrc.c
  ${LIBJPEG_DIR}/jdcoefct.c
  ${LIBJPEG_DIR}/jdcolor.c
  ${LIBJPEG_DIR}/jddctmgr.c
  ${LIBJPEG_DIR}/jdhuff.c
  ${LIBJPEG_DIR}/jdicc.c
  ${LIBJPEG_DIR}/jdinput.c
  ${LIBJPEG_DIR}/jdmainct.c
  ${LIBJPEG_DIR}/jdmarker.c
  ${LIBJPEG_DIR}/jdmaster.c
  ${LIBJPEG_DIR}/jdmerge.c
  ${LIBJPEG_DIR}/jdphuff.c
  ${LIBJPEG_DIR}/jdpostct.c
  ${LIBJPEG_DIR}/jdsample.c
  ${LIBJPEG_DIR}/jdtrans.c
  ${LIBJPEG_DIR}/jerror.c
  ${LIBJPEG_DIR}/jfdctflt.c
  ${LIBJPEG_DIR}/jfdctfst.c
  ${LIBJPEG_DIR}/jfdctint.c
  ${LIBJPEG_DIR}/jidctflt.c
  ${LIBJPEG_DIR}/jidctfst.c
  ${LIBJPEG_DIR}/jidctint.c
  ${LIBJPEG_DIR}/jidctred.c
  ${LIBJPEG_DIR}/jquant1.c
  ${LIBJPEG_DIR}/jquant2.c
  ${LIBJPEG_DIR}/jutils.c
  ${LIBJPEG_DIR}/jmemmgr.c
  ${LIBJPEG_DIR}/jmemnobs.c
  ${LIBJPEG_DIR}/jsimd_none.c
)

target_include_directories(libjpeg-turbo PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${LIBJPEG_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
)
