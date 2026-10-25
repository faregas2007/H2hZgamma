add_subdirectory(sm)
add_subdirectory(thdm)

foreach(workspace IN LISTS AMPFLOW_EXTRA_WORKSPACES)
  get_filename_component(workspace_name "${workspace}" NAME)
  add_subdirectory("${workspace}" "${CMAKE_CURRENT_BINARY_DIR}/extra_${workspace_name}")
endforeach()
