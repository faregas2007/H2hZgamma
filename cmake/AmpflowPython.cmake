# Is python3 with numpy + matplotlib available? That decides whether the 'plots' targets exist. Nothing here is
# required to build the C++ tools.
#   AMPFLOW_HAVE_PLOTTING   python3 + numpy + matplotlib
#   AMPFLOW_PYTHONPATH      where the `ampflow` Python package lives
include_guard(GLOBAL)

set(AMPFLOW_PYTHONPATH "${AMPFLOW_ROOT}/python" CACHE INTERNAL "")
set(AMPFLOW_HAVE_PLOTTING OFF)

find_package(Python3 COMPONENTS Interpreter)
if(Python3_FOUND)
  execute_process(COMMAND "${Python3_EXECUTABLE}" -c "import numpy, matplotlib"
                  RESULT_VARIABLE rc OUTPUT_QUIET ERROR_QUIET)
  if(rc EQUAL 0)
    set(AMPFLOW_HAVE_PLOTTING ON)
  endif()
endif()
if(NOT AMPFLOW_HAVE_PLOTTING)
  message(STATUS "ampflow: python3 with numpy + matplotlib not found -> no 'plots' targets")
endif()
