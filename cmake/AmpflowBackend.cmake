# ampflow::backend -- LoopTools, which provides A0, B0, C0, D0 (and ltini, setdelta, ...) through "clooptools.h".
# Found on the machine (-DLOOPTOOLS_ROOT, $LOOPTOOLS_ROOT, system paths, or the copy in third_party/looptools), or else
# downloaded, built and installed into third_party/looptools at configure time (AmpflowLoopTools.cmake).
include_guard(GLOBAL)

add_library(ampflow_backend INTERFACE)
add_library(ampflow::backend ALIAS ampflow_backend)

set(_lt_hints ${LOOPTOOLS_ROOT} "${AMPFLOW_LOOPTOOLS_DIR}/install/${AMPFLOW_LOOPTOOLS_VERSION}")
find_path(LOOPTOOLS_INCLUDE_DIR clooptools.h
          HINTS ${_lt_hints} ENV LOOPTOOLS_ROOT PATH_SUFFIXES include)
find_library(LOOPTOOLS_LIBRARY NAMES ooptools looptools
             HINTS ${_lt_hints} ENV LOOPTOOLS_ROOT PATH_SUFFIXES lib lib64)

if((NOT LOOPTOOLS_INCLUDE_DIR OR NOT LOOPTOOLS_LIBRARY) AND AMPFLOW_FETCH_LOOPTOOLS)
  message(STATUS "ampflow: LoopTools not found; fetching and building version ${AMPFLOW_LOOPTOOLS_VERSION} into ${AMPFLOW_LOOPTOOLS_DIR}")
  include(AmpflowLoopTools)
  ampflow_fetch_looptools(_lt_prefix)
  unset(LOOPTOOLS_INCLUDE_DIR CACHE)
  unset(LOOPTOOLS_LIBRARY CACHE)
  find_path(LOOPTOOLS_INCLUDE_DIR clooptools.h HINTS "${_lt_prefix}" NO_DEFAULT_PATH PATH_SUFFIXES include)
  find_library(LOOPTOOLS_LIBRARY NAMES ooptools looptools HINTS "${_lt_prefix}" NO_DEFAULT_PATH PATH_SUFFIXES lib lib64)
endif()
if(NOT LOOPTOOLS_INCLUDE_DIR OR NOT LOOPTOOLS_LIBRARY)
  message(FATAL_ERROR
    "LoopTools not found. Pass -DLOOPTOOLS_ROOT=<prefix> (needs include/clooptools.h and lib*/libooptools.a), "
    "or allow the download (-DAMPFLOW_FETCH_LOOPTOOLS=ON, the default; needs network, gfortran, make), "
    "or put LoopTools-<version>.tar.gz into ${AMPFLOW_LOOPTOOLS_DIR}/ by hand (see README.md).")
endif()

target_include_directories(ampflow_backend INTERFACE "${LOOPTOOLS_INCLUDE_DIR}")
# libooptools.a is Fortran: link the Fortran runtime by name (the g++ driver finds -lgfortran itself).
target_link_libraries(ampflow_backend INTERFACE "${LOOPTOOLS_LIBRARY}" gfortran)
target_compile_definitions(ampflow_backend INTERFACE AMPFLOW_BACKEND_NAME=\"LoopTools\")
message(STATUS "ampflow: LoopTools found: ${LOOPTOOLS_LIBRARY}")
