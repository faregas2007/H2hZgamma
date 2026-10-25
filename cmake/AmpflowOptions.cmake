# Options, cache variables and compiler settings. Everything a user may want to change is here.
include_guard(GLOBAL)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(AMPFLOW_ROOT "${PROJECT_SOURCE_DIR}" CACHE INTERNAL "Root of the ampflow source tree")

# ---- loop-integral library: LoopTools (A0, B0, C0, D0) ---------------------------------------------------------------------------------------------
set(LOOPTOOLS_ROOT "" CACHE PATH "LoopTools prefix (include/clooptools.h, lib*/libooptools.a); /usr for the Debian/Ubuntu package")
option(AMPFLOW_FETCH_LOOPTOOLS "if LoopTools is not found, download it, build it and install it inside the repository (third_party/looptools)" ON)
set(AMPFLOW_LOOPTOOLS_VERSION "2.16" CACHE STRING "LoopTools version to fetch (https://feynarts.de/looptools/)")
set(AMPFLOW_LOOPTOOLS_URL "" CACHE STRING "Download URL; empty = https://feynarts.de/looptools/LoopTools-<version>.tar.gz")
set(AMPFLOW_LOOPTOOLS_MD5 "" CACHE STRING "MD5 of the archive; empty = the one published for the known versions (2.14, 2.15, 2.16)")
set(AMPFLOW_LOOPTOOLS_DIR "${AMPFLOW_ROOT}/third_party/looptools" CACHE PATH "Where the LoopTools archive, source and installation are kept (put a hand-downloaded archive here)")

# ---- models and workspaces -------------------------------------------------------------------------------------------------
set(AMPFLOW_LIBRARY_MODELS
    "${AMPFLOW_ROOT}/models/sm.model"
    "${AMPFLOW_ROOT}/models/feyncalc_smp.model"
    "${AMPFLOW_ROOT}/models/feynarts_sm.model"
    CACHE STRING "Models every workspace starts from, in order (a workspace's own models/*.model come after and may override)")
set(AMPFLOW_EXTRA_WORKSPACES "" CACHE STRING "Folders of your own workspaces to build (each with a CMakeLists.txt, see docs/workspaces.md)")
option(AMPFLOW_BUILD_EXAMPLES "Build the example workspaces (examples/)" ON)

# ---- output folders of the 'scan' and 'plots' targets --------------------------------------------------------------------------
set(AMPFLOW_DATA_DIR "${PROJECT_BINARY_DIR}/data" CACHE PATH "Where 'scan' writes the CSV repository: <dir>/<workspace>/<run>/")
set(AMPFLOW_PLOT_DIR "${PROJECT_BINARY_DIR}/plots" CACHE PATH "Where 'plots' writes the figures: <dir>/<workspace>/<run>/")

# ---- warnings ---------------------------------------------------------------------------------------------------------------------
function(ampflow_enable_warnings target)
  if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(${target} PRIVATE -Wall -Wextra)
  elseif(MSVC)
    target_compile_options(${target} PRIVATE /W4)
  endif()
endfunction()
