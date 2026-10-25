cmake_minimum_required(VERSION 3.16)
project(ampflow VERSION 0.2.0 LANGUAGES CXX
        DESCRIPTION "FeynCalc amplitudes -> C++ -> scans (SLHA card in, CSV out) -> plots")

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(AmpflowOptions)      # options and compiler settings
include(AmpflowBackend)      # ampflow::backend: the loop-integral library (LoopTools)
include(AmpflowPython)       # is numpy + matplotlib available? decides whether the 'plots' targets exist
include(AmpflowWorkspace)    # ampflow_add_workspace()

add_subdirectory(src/fc2lt)          # the translator
add_subdirectory(src/ampscan)        # the runner (a library; each workspace links it with its own registry)
if(AMPFLOW_BUILD_EXAMPLES)
  add_subdirectory(examples)
endif()
