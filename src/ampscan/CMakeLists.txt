# ampscan_core: the runner without any amplitudes (SLHA reader, scan files, CSV writer, evaluation, command line).
# Every workspace links it with ITS OWN registry (cmake/AmpflowWorkspace.cmake).
add_library(ampscan_core STATIC runner.cpp cli.cpp)
target_include_directories(ampscan_core PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}" "${AMPFLOW_ROOT}/include")
target_link_libraries(ampscan_core PUBLIC ampflow::backend)
ampflow_enable_warnings(ampscan_core)
