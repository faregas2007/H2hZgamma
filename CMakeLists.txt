cmake_minimum_required(VERSION 3.16)
project(ampflow VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# ---------------------------------------------------------------- options
set(AMPFLOW_BACKEND "builtin" CACHE STRING "Loop-integral backend: builtin (A0,B0 only) or looptools (A0,B0,C0,D0)")
set_property(CACHE AMPFLOW_BACKEND PROPERTY STRINGS builtin looptools)
set(LOOPTOOLS_ROOT "" CACHE PATH "LoopTools install prefix (the folder holding include/ and lib/ or lib64/)")
add_subdirectory(tools/fc2lt)

# ---------------------------------------------------------------- backend
add_library(ampflow_backend INTERFACE)
if(AMPFLOW_BACKEND STREQUAL "builtin")
  target_include_directories(ampflow_backend INTERFACE "${CMAKE_SOURCE_DIR}/backend/builtin")
  target_compile_definitions(ampflow_backend INTERFACE AMPFLOW_BACKEND_NAME=\"builtin\")
elseif(AMPFLOW_BACKEND STREQUAL "looptools")
  find_path(LOOPTOOLS_INCLUDE_DIR clooptools.h
            HINTS "${LOOPTOOLS_ROOT}" ENV LOOPTOOLS_ROOT PATH_SUFFIXES include)
  find_library(LOOPTOOLS_LIBRARY NAMES ooptools looptools
               HINTS "${LOOPTOOLS_ROOT}" ENV LOOPTOOLS_ROOT PATH_SUFFIXES lib lib64)
  if(NOT LOOPTOOLS_INCLUDE_DIR OR NOT LOOPTOOLS_LIBRARY)
    message(FATAL_ERROR "LoopTools not found. Pass -DLOOPTOOLS_ROOT=<prefix> (needs include/clooptools.h and lib*/libooptools.a), "
                        "or use -DAMPFLOW_BACKEND=builtin.")
  endif()
  target_include_directories(ampflow_backend INTERFACE "${LOOPTOOLS_INCLUDE_DIR}")
  # libooptools.a is Fortran: link the Fortran runtime by name (find_library cannot see the compiler's own
  # directory, so a path lookup fails on stock systems; the g++ driver finds -lgfortran itself).
  target_link_libraries(ampflow_backend INTERFACE "${LOOPTOOLS_LIBRARY}" gfortran)
  target_compile_definitions(ampflow_backend INTERFACE AMPFLOW_BACKEND_NAME=\"LoopTools\")
else()
  message(FATAL_ERROR "AMPFLOW_BACKEND must be 'builtin' or 'looptools' (got '${AMPFLOW_BACKEND}')")
endif()
message(STATUS "ampflow: backend = ${AMPFLOW_BACKEND}")
# ---------------------------------------------------------------- tests
add_executable(test_core tests/test_core.cpp)       # deliberately NOT linked to the selected backend:
target_include_directories(test_core PRIVATE src "${CMAKE_SOURCE_DIR}/backend/builtin")   # it tests the builtin one
target_compile_definitions(test_core PRIVATE AMPFLOW_SOURCE_DIR=\"${CMAKE_SOURCE_DIR}\")
add_test(NAME core_unit COMMAND test_core)
