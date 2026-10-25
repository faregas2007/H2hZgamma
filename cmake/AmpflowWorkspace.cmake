# ampflow_add_workspace(<name> [DIR <folder>])
#
# A workspace is a folder with
#     amplitudes/*.m     FeynCalc exports (the file name is the amplitude name)
#     models/*.model     meaning of the symbols; applied after the library models, in file-name order
#     cards/*.slha       parameter cards (read at run time, not by CMake)
#     scans/*.scan       scan descriptions
#
# The function
#   1. translates every amplitude with fc2lt against the models -> generated/amp_<name>.h
#   2. builds the registry of those amplitudes and links it with the runner:   <build dir>/ampscan
#   3. creates the targets  scan_<workspace>_<run>  and  plots_<workspace>_<run>  for every scan file,
#      and hooks them into the global targets  scan  and  plots
#
# Adding or removing a file in amplitudes/ models/ scans/ is noticed at the next build: the folders are globbed with CONFIGURE_DEPENDS.
include_guard(GLOBAL)

if(NOT TARGET scan)
  add_custom_target(scan COMMENT "run every scan of every workspace")
endif()
if(NOT TARGET plots)
  add_custom_target(plots COMMENT "plot every scan of every workspace")
endif()

# --- the models of a workspace: <args for fc2lt> and <name(hash) ...> ---------------------------------------------------------------
function(_ampflow_collect_models DIR OUT_ARGS OUT_FILES OUT_INFO)
  file(GLOB workspace_models CONFIGURE_DEPENDS "${DIR}/models/*.model")
  list(SORT workspace_models)
  set(files ${AMPFLOW_LIBRARY_MODELS} ${workspace_models})
  set(args "")
  set(info "")
  foreach(model IN LISTS files)
    if(NOT EXISTS "${model}")
      message(FATAL_ERROR "ampflow: model file not found: ${model}  (see AMPFLOW_LIBRARY_MODELS)")
    endif()
    file(SHA256 "${model}" hash)
    string(SUBSTRING "${hash}" 0 8 hash)
    get_filename_component(model_name "${model}" NAME)
    list(APPEND args --model "${model}")
    string(APPEND info "${model_name}(${hash}) ")
    # a changed model file must re-run CMake so the hash recorded in the CSVs stays current
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${model}")
  endforeach()
  string(STRIP "${info}" info)
  set(${OUT_ARGS} "${args}" PARENT_SCOPE)
  set(${OUT_FILES} "${files}" PARENT_SCOPE)
  set(${OUT_INFO} "${info}" PARENT_SCOPE)
endfunction()

# --- scans: targets to run and plot them ---------------------------------------------------------------------------------------------
function(_ampflow_add_scan_targets NAME DIR)
  file(GLOB scan_files CONFIGURE_DEPENDS "${DIR}/scans/*.scan")
  foreach(scan IN LISTS scan_files)
    get_filename_component(run "${scan}" NAME_WLE)
    add_custom_target(scan_${NAME}_${run}
      COMMAND ampscan_${NAME} -o "${AMPFLOW_DATA_DIR}/${NAME}" "${scan}"
      DEPENDS ampscan_${NAME}
      COMMENT "ampscan: ${NAME}/${run} -> ${AMPFLOW_DATA_DIR}/${NAME}/${run}"
      VERBATIM)
    add_dependencies(scan scan_${NAME}_${run})
    if(AMPFLOW_HAVE_PLOTTING)
      add_custom_target(plots_${NAME}_${run}
        COMMAND "${CMAKE_COMMAND}" -E env "PYTHONPATH=${AMPFLOW_PYTHONPATH}"
                "${Python3_EXECUTABLE}" -m ampflow.plot "${AMPFLOW_DATA_DIR}/${NAME}/${run}" -o "${AMPFLOW_PLOT_DIR}/${NAME}/${run}"
        DEPENDS scan_${NAME}_${run}
        COMMENT "plots: ${NAME}/${run} -> ${AMPFLOW_PLOT_DIR}/${NAME}/${run}"
        VERBATIM)
      add_dependencies(plots plots_${NAME}_${run})
    endif()
  endforeach()
endfunction()

# --- the workspace ----------------------------------------------------------------------------------------------------------------------
function(ampflow_add_workspace NAME)
  cmake_parse_arguments(ARG "" "DIR" "" ${ARGN})
  if(NOT ARG_DIR)
    set(ARG_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()
  set(gen "${CMAKE_CURRENT_BINARY_DIR}/generated")

  _ampflow_collect_models("${ARG_DIR}" model_args model_files AMP_MODEL_INFO)

  # 1. translate the amplitudes
  file(GLOB amp_files CONFIGURE_DEPENDS "${ARG_DIR}/amplitudes/*.m")
  list(SORT amp_files)
  set(AMP_INCLUDES "")
  set(AMP_ENTRIES "")
  set(amp_names "")
  set(amp_headers "")
  foreach(amp_file IN LISTS amp_files)
    get_filename_component(amp_name "${amp_file}" NAME_WLE)
    if(NOT amp_name MATCHES "^[A-Za-z_][A-Za-z0-9_]*$")
      message(WARNING "ampflow: skipping '${amp_file}': the file name must be a valid C++ identifier")
      continue()
    endif()
    set(amp_header "${gen}/amp_${amp_name}.h")
    add_custom_command(
      OUTPUT "${amp_header}"
      COMMAND "${CMAKE_COMMAND}" -E make_directory "${gen}"
      COMMAND fc2lt --registry ${model_args} -f "${amp_name}" -o "${amp_header}" "${amp_file}"
      DEPENDS fc2lt "${amp_file}" ${model_files}
      COMMENT "fc2lt: ${NAME}/${amp_name}.m -> amp_${amp_name}.h"
      VERBATIM)
    list(APPEND amp_names "${amp_name}")
    list(APPEND amp_headers "${amp_header}")
    string(APPEND AMP_INCLUDES "#include \"amp_${amp_name}.h\"\n")
    string(APPEND AMP_ENTRIES "        ampgen::${amp_name}::descriptor(),\n")
  endforeach()
  if(amp_names)
    string(REPLACE ";" " " pretty "${amp_names}")
    message(STATUS "ampflow: ${NAME}: amplitudes: ${pretty}")
  else()
    message(WARNING "ampflow: ${NAME}: no usable amplitudes in ${ARG_DIR}/amplitudes")
  endif()

  # 2. registry + runner
  configure_file("${AMPFLOW_ROOT}/src/ampscan/registry.cpp.in" "${gen}/registry.cpp" @ONLY)
  add_library(ampflow_amps_${NAME} STATIC "${gen}/registry.cpp" ${amp_headers})
  target_include_directories(ampflow_amps_${NAME} PUBLIC "${AMPFLOW_ROOT}/include" "${gen}")
  target_link_libraries(ampflow_amps_${NAME} PUBLIC ampflow::backend)

  add_executable(ampscan_${NAME} "${AMPFLOW_ROOT}/src/ampscan/main.cpp")
  target_link_libraries(ampscan_${NAME} PRIVATE ampscan_core ampflow_amps_${NAME})
  set_target_properties(ampscan_${NAME} PROPERTIES
    OUTPUT_NAME ampscan
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    AMPFLOW_AMPLITUDES "${amp_names}")
  ampflow_enable_warnings(ampscan_${NAME})

  # 3. scans
  _ampflow_add_scan_targets(${NAME} "${ARG_DIR}")
endfunction()
