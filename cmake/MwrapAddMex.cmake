# mwrap_add_mex.cmake - helper to generate MATLAB/Octave wrapper sources with mwrap
#
# Usage:
#   mwrap_add_mex(<target>
#     MW_FILES <file> [...]
#     [MEX_NAME <name>]
#     [CC_FILENAME <filename>]
#     [M_FILENAME <filename>]
#     [CLASSDEF_NAME <name>]
#     [MWRAP_FLAGS <flag> [...]]
#     [WORK_DIR <directory>]
#     [EXTRA_DEPENDS <dep> [...]]
#     [OUTPUT_VAR <variable>]
#   )
#
# The function wraps the mwrap executable produced by the current build to
# generate a C/C++ source file (and optional MATLAB scaffolding).  It creates a
# custom target named after <target> that depends on the generated source file.
# Downstream projects can request the absolute path to the generated source via
# OUTPUT_VAR and add it to their own targets.

set(_MWRAP_ADD_MEX_MODULE_DIR ${CMAKE_CURRENT_LIST_DIR})

function(mwrap_add_mex target_name)
  if(NOT target_name)
    message(FATAL_ERROR "mwrap_add_mex requires a target name")
  endif()

  set(options)
  set(oneValueArgs MEX_NAME CC_FILENAME M_FILENAME CLASSDEF_NAME WORK_DIR OUTPUT_VAR)
  set(multiValueArgs MW_FILES MWRAP_FLAGS EXTRA_DEPENDS)
  cmake_parse_arguments(MAM "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT MAM_MW_FILES)
    message(FATAL_ERROR "mwrap_add_mex(${target_name}) requires MW_FILES to be specified")
  endif()

  if(NOT TARGET mwrap)
    message(FATAL_ERROR "mwrap_add_mex requires the mwrap executable target to exist")
  endif()

  if(NOT MAM_MEX_NAME)
    set(MAM_MEX_NAME "${target_name}")
  endif()

  if(NOT MAM_CC_FILENAME)
    if(MAM_MEX_NAME MATCHES "\\.(c|cc|cpp)$")
      set(MAM_CC_FILENAME "${MAM_MEX_NAME}")
    else()
      set(MAM_CC_FILENAME "${MAM_MEX_NAME}.cc")
    endif()
  endif()

  if(MAM_WORK_DIR)
    set(mwrap_binary_dir "${MAM_WORK_DIR}")
  else()
    set(mwrap_binary_dir "${CMAKE_CURRENT_BINARY_DIR}/${target_name}")
  endif()

  file(MAKE_DIRECTORY "${mwrap_binary_dir}")

  set(cc_output "${mwrap_binary_dir}/${MAM_CC_FILENAME}")
  get_filename_component(cc_basename "${cc_output}" NAME)

  set(mwrap_command $<TARGET_FILE:mwrap> -mex ${MAM_MEX_NAME} -c "${cc_output}")

  set(mwrap_depends ${MAM_EXTRA_DEPENDS})

  set(mwrap_working_dir "${mwrap_binary_dir}")
  set(mwrap_inputs)
  set(mw_absolute_inputs)
  set(mw_parent_dirs)
  set(mwrap_stage_commands)
  foreach(mw IN LISTS MAM_MW_FILES)
    if(IS_ABSOLUTE "${mw}")
      set(mw_abs "${mw}")
    else()
      set(mw_abs "${CMAKE_CURRENT_SOURCE_DIR}/${mw}")
    endif()
    list(APPEND mw_absolute_inputs "${mw_abs}")
    get_filename_component(mw_parent "${mw_abs}" DIRECTORY)
    list(APPEND mw_parent_dirs "${mw_parent}")
  endforeach()

  list(REMOVE_DUPLICATES mw_parent_dirs)
  if(mw_parent_dirs)
    list(LENGTH mw_parent_dirs mw_parent_dir_count)
    if(mw_parent_dir_count EQUAL 1)
      foreach(mw_abs IN LISTS mw_absolute_inputs)
        get_filename_component(mw_basename "${mw_abs}" NAME)
        list(APPEND mwrap_inputs "${mw_basename}")
        list(APPEND mwrap_stage_commands
          COMMAND ${CMAKE_COMMAND} -E copy_if_different "${mw_abs}" "${mwrap_binary_dir}/${mw_basename}")
      endforeach()
    else()
      foreach(mw_abs IN LISTS mw_absolute_inputs)
        file(RELATIVE_PATH mw_rel "${mwrap_binary_dir}" "${mw_abs}")
        list(APPEND mwrap_inputs "${mw_rel}")
      endforeach()
    endif()
  endif()

  if(MAM_CLASSDEF_NAME)
    set(classdef_dir "${mwrap_binary_dir}/@${MAM_CLASSDEF_NAME}")
  endif()

  if(NOT mwrap_inputs)
    set(mwrap_inputs ${MAM_MW_FILES})
  endif()

  if(MAM_M_FILENAME)
    list(APPEND mwrap_command -m "${mwrap_binary_dir}/${MAM_M_FILENAME}")
  endif()
  if(MAM_MWRAP_FLAGS)
    list(APPEND mwrap_command ${MAM_MWRAP_FLAGS})
  endif()
  foreach(mw IN LISTS mwrap_inputs)
    list(APPEND mwrap_command "${mw}")
  endforeach()

  list(APPEND mwrap_depends ${mw_absolute_inputs})
  list(APPEND mwrap_depends mwrap)

  set(pre_commands COMMAND ${CMAKE_COMMAND} -E make_directory "${mwrap_binary_dir}")
  if(classdef_dir)
    list(APPEND pre_commands COMMAND ${CMAKE_COMMAND} -E make_directory "${classdef_dir}")
  endif()
  list(APPEND pre_commands ${mwrap_stage_commands})

  add_custom_command(
    OUTPUT "${cc_output}"
    ${pre_commands}
    COMMAND ${mwrap_command}
    WORKING_DIRECTORY "${mwrap_working_dir}"
    DEPENDS ${mwrap_depends}
    COMMENT "Generating ${cc_basename} with mwrap"
    VERBATIM COMMAND_EXPAND_LISTS
  )

  set_source_files_properties("${cc_output}" PROPERTIES GENERATED TRUE)

  add_custom_target(${target_name} DEPENDS "${cc_output}")
  add_dependencies(${target_name} mwrap)

  if(MAM_OUTPUT_VAR)
    set(${MAM_OUTPUT_VAR} "${cc_output}" PARENT_SCOPE)
  endif()

  set_property(TARGET ${target_name} PROPERTY MWRAP_OUTPUT_SOURCE "${cc_output}")
  set_property(TARGET ${target_name} PROPERTY MWRAP_OUTPUT_DIRECTORY "${mwrap_binary_dir}")
  set_property(TARGET ${target_name} PROPERTY MWRAP_MEX_NAME "${MAM_MEX_NAME}")
  if(MAM_M_FILENAME)
    set_property(TARGET ${target_name} PROPERTY MWRAP_OUTPUT_M_FILE "${mwrap_binary_dir}/${MAM_M_FILENAME}")
  endif()
  if(classdef_dir)
    set_property(TARGET ${target_name} PROPERTY MWRAP_OUTPUT_CLASSDEF_DIR "${classdef_dir}")
  endif()
endfunction()

function(_mwrap_compile_mex target_name)
  set(options)
  set(oneValueArgs OUTPUT_VAR)
  set(multiValueArgs)
  cmake_parse_arguments(MCC "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT TARGET ${target_name})
    message(FATAL_ERROR "_mwrap_compile_mex was asked to process unknown target '${target_name}'")
  endif()

  if(NOT COMMAND matlab_add_mex)
    message(FATAL_ERROR "_mwrap_compile_mex requires matlab_add_mex(), but it is unavailable")
  endif()

  get_target_property(cc_output ${target_name} MWRAP_OUTPUT_SOURCE)
  if(NOT cc_output)
    message(FATAL_ERROR "Target '${target_name}' does not have generated source metadata")
  endif()

  get_target_property(mex_name ${target_name} MWRAP_MEX_NAME)
  if(NOT mex_name)
    set(mex_name ${target_name})
  endif()

  set(mex_target "${target_name}_mex")
  matlab_add_mex(NAME ${mex_target} SRC "${cc_output}" OUTPUT_NAME "${mex_name}")
  add_dependencies(${mex_target} ${target_name})

  set_property(TARGET ${target_name} PROPERTY MWRAP_OUTPUT_MEX_TARGET "${mex_target}")
  set_property(TARGET ${target_name} PROPERTY MWRAP_OUTPUT_MEX_PATH $<TARGET_FILE:${mex_target}>)

  if(MCC_OUTPUT_VAR)
    set(${MCC_OUTPUT_VAR} "${mex_target}" PARENT_SCOPE)
  endif()
endfunction()
