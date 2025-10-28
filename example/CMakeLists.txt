cmake_minimum_required(VERSION 3.16)

include(${CMAKE_SOURCE_DIR}/cmake/MwrapAddMex.cmake)

add_custom_target(mwrap_examples)

set(example_source_dir "${CMAKE_CURRENT_SOURCE_DIR}")

set(_mwrap_example_targets
  foobar
  eventq_plain
  eventq_handle
  eventq_class
  eventq2
  zlib
  fem_interface
)

set(fem_interface_support_sources
  "${example_source_dir}/fem/src/assembler.cc"
  "${example_source_dir}/fem/src/gauss2by2.cc"
  "${example_source_dir}/fem/src/mesh.cc"
  "${example_source_dir}/fem/src/quad2d1.cc"
  "${example_source_dir}/fem/src/scalar1d.cc"
  "${example_source_dir}/fem/src/scalar2d.cc"
  "${example_source_dir}/fem/src/elastic2d1.cc"
)

mwrap_add_mex(foobar
  MEX_NAME fbmex
  CC_FILENAME fbmex.cc
  M_FILENAME foobar.m
  MW_FILES "${example_source_dir}/foobar/foobar.mw"
)

mwrap_add_mex(eventq_plain
  MEX_NAME eventqpmex
  CC_FILENAME eventqpmex.cc
  MW_FILES "${example_source_dir}/eventq/eventq_plain.mw"
  MWRAP_FLAGS -mb
)

mwrap_add_mex(eventq_handle
  MEX_NAME eventqhmex
  CC_FILENAME eventqhmex.cc
  MW_FILES "${example_source_dir}/eventq/eventq_handle.mw"
  MWRAP_FLAGS -mb
  COMPILE_DEFINITIONS R2008OO
)

mwrap_add_mex(eventq_class
  MEX_NAME eventqcmex
  CC_FILENAME eventqcmex.cc
  MW_FILES "${example_source_dir}/eventq/eventq_class.mw"
  MWRAP_FLAGS -mb
  CLASSDEF_NAME eventq
)

mwrap_add_mex(eventq2
  MEX_NAME eventq2mex
  CC_FILENAME eventq2mex.cc
  MW_FILES "${example_source_dir}/eventq2/eventq2.mw"
  MWRAP_FLAGS -mb
)

mwrap_add_mex(zlib
  MEX_NAME gzmex
  CC_FILENAME gzmex.cc
  MW_FILES "${example_source_dir}/zlib/gzfile.mw"
  MWRAP_FLAGS -mb
)

mwrap_add_mex(fem_interface
  MEX_NAME femex
  CC_FILENAME femex.cc
  MW_FILES
    "${example_source_dir}/fem/interface/assembler.mw"
    "${example_source_dir}/fem/interface/mesh.mw"
    "${example_source_dir}/fem/interface/elements.mw"
  MWRAP_FLAGS -mb
  EXTRA_SOURCES ${fem_interface_support_sources}
  INCLUDE_DIRECTORIES "${example_source_dir}/fem/src"
)

foreach(example_target IN LISTS _mwrap_example_targets)
  add_dependencies(mwrap_examples ${example_target})
endforeach()

if(MWRAP_COMPILE_MEX AND MWRAP_MEX_BACKENDS)
  foreach(example_target IN LISTS _mwrap_example_targets)
    _mwrap_compile_mex(${example_target} OUTPUT_VAR _mwrap_mex_targets)

    get_target_property(_mex_output_dir ${example_target} MWRAP_OUTPUT_DIRECTORY)
    get_target_property(_mex_target_list ${example_target} MWRAP_OUTPUT_MEX_TARGETS)
    get_target_property(_mex_path_list ${example_target} MWRAP_OUTPUT_MEX_PATHS)

    if(NOT _mex_target_list OR _mex_target_list STREQUAL "NOTFOUND")
      continue()
    endif()

    if(NOT _mex_path_list OR _mex_path_list STREQUAL "NOTFOUND")
      set(_mex_path_list)
    endif()

    list(LENGTH _mex_target_list _mex_target_count)
    list(LENGTH _mex_path_list _mex_path_count)
    if(NOT _mex_target_count EQUAL _mex_path_count)
      message(FATAL_ERROR "Mismatch between recorded MEX targets and paths for ${example_target}")
    endif()

    math(EXPR _mex_index "0")
    foreach(_mex_target IN LISTS _mex_target_list)
      list(GET _mex_path_list ${_mex_index} _mex_path)
      add_dependencies(mwrap_examples ${_mex_target})

      if(_mex_output_dir AND NOT _mex_output_dir STREQUAL "NOTFOUND")
        set(_mex_should_copy TRUE)
        if(_mex_path MATCHES "\\$<TARGET_FILE:")
          set(_mex_source_path "${_mex_path}")
          set(_mex_dest_name "$<TARGET_FILE_NAME:${_mex_target}>")
          set(_mex_dest_path "${_mex_output_dir}/${_mex_dest_name}")
        else()
          set(_mex_source_path "${_mex_path}")
          if(NOT IS_ABSOLUTE "${_mex_source_path}")
            get_filename_component(_mex_source_path "${_mex_source_path}" ABSOLUTE)
          endif()
          get_filename_component(_mex_dest_name "${_mex_path}" NAME)
          set(_mex_dest_path "${_mex_output_dir}/${_mex_dest_name}")
          if(NOT IS_ABSOLUTE "${_mex_dest_path}")
            get_filename_component(_mex_dest_path "${_mex_dest_path}" ABSOLUTE)
          endif()
          if(_mex_source_path STREQUAL _mex_dest_path)
            set(_mex_should_copy FALSE)
          endif()
        endif()

        if(_mex_should_copy)
          add_custom_command(TARGET ${_mex_target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${_mex_output_dir}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "${_mex_source_path}"
              "${_mex_dest_path}"
          )
        endif()
      endif()

      math(EXPR _mex_index "${_mex_index} + 1")
    endforeach()
  endforeach()
endif()

if(BUILD_TESTING AND MWRAP_COMPILE_MEX)
  if(MWRAP_MEX_BACKENDS)
    list(FIND MWRAP_MEX_BACKENDS "OCTAVE" _mwrap_octave_index)
    list(FIND MWRAP_MEX_BACKENDS "MATLAB" _mwrap_matlab_index)
  else()
    set(_mwrap_octave_index -1)
    set(_mwrap_matlab_index -1)
  endif()

  function(_mwrap_prepare_smoke_test_runner target_name runner_var workdir_var script_basename_var runner_escape_var)
    set(options)
    set(oneValueArgs SCRIPT WORKSPACE)
    set(multiValueArgs EXTRA_PATHS)
    cmake_parse_arguments(MTEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT TARGET ${target_name})
      message(FATAL_ERROR "Unknown target '${target_name}' requested for smoke test")
    endif()

    if(NOT MTEST_SCRIPT)
      message(FATAL_ERROR "SCRIPT must be provided for smoke test on target '${target_name}'")
    endif()

    get_target_property(wrapper_dir ${target_name} MWRAP_OUTPUT_DIRECTORY)
    if(NOT wrapper_dir OR wrapper_dir STREQUAL "NOTFOUND")
      message(FATAL_ERROR "Target '${target_name}' is missing wrapper directory metadata")
    endif()

    get_target_property(classdef_dir ${target_name} MWRAP_OUTPUT_CLASSDEF_DIR)
    if(NOT classdef_dir OR classdef_dir STREQUAL "NOTFOUND")
      unset(classdef_dir)
    endif()

    set(test_paths ${MTEST_EXTRA_PATHS} "${wrapper_dir}")
    if(classdef_dir)
      list(APPEND test_paths "${classdef_dir}")
    endif()
    list(REMOVE_DUPLICATES test_paths)

    set(path_commands "")
    foreach(test_path IN LISTS test_paths)
      if(test_path)
        file(TO_CMAKE_PATH "${test_path}" test_path_cmake)
        string(REPLACE "'" "''" test_path_escaped "${test_path_cmake}")
        string(APPEND path_commands "addpath('${test_path_escaped}');\n")
      endif()
    endforeach()
    if(path_commands STREQUAL "")
      set(path_commands "% No additional paths required\n")
    endif()

    if(MTEST_WORKSPACE)
      set(work_dir "${MTEST_WORKSPACE}")
      file(MAKE_DIRECTORY "${work_dir}")
      file(TO_CMAKE_PATH "${work_dir}" work_dir_cmake)
      string(REPLACE "'" "''" work_dir_escaped "${work_dir_cmake}")
      set(work_dir_command "cd('${work_dir_escaped}');\n")
    else()
      set(work_dir "${CMAKE_CURRENT_BINARY_DIR}")
      set(work_dir_command "% No staging directory requested\n")
      file(TO_CMAKE_PATH "${work_dir}" work_dir_cmake)
    endif()

    get_filename_component(script_basename "${MTEST_SCRIPT}" NAME_WE)
    set(runner_file "${CMAKE_CURRENT_BINARY_DIR}/${script_basename}_runner.m")
    file(TO_CMAKE_PATH "${MTEST_SCRIPT}" script_path_cmake)
    string(REPLACE "'" "''" script_path_escaped "${script_path_cmake}")

    set(PATHS "${path_commands}")
    set(WORK_DIR "${work_dir_command}")
    set(CALL "${script_path_escaped}")

    configure_file(
      "${CMAKE_CURRENT_SOURCE_DIR}/run_example.m.in"
      "${runner_file}"
      @ONLY
    )

    unset(PATHS)
    unset(WORK_DIR)
    unset(CALL)

    file(TO_CMAKE_PATH "${runner_file}" runner_path_cmake)
    string(REPLACE "'" "''" runner_path_escaped "${runner_path_cmake}")

    set(${runner_var} "${runner_file}" PARENT_SCOPE)
    set(${workdir_var} "${work_dir}" PARENT_SCOPE)
    set(${script_basename_var} "${script_basename}" PARENT_SCOPE)
    set(${runner_escape_var} "${runner_path_escaped}" PARENT_SCOPE)
  endfunction()

  set(_mwrap_enable_octave_tests FALSE)
  if(_mwrap_octave_index GREATER -1 AND DEFINED MWRAP_OCTAVE_EXECUTABLE AND MWRAP_OCTAVE_EXECUTABLE)
    set(_mwrap_enable_octave_tests TRUE)
    function(_mwrap_add_octave_smoke_test target_name)
      _mwrap_prepare_smoke_test_runner(${target_name} runner_file work_dir script_basename runner_path_escaped ${ARGN})

      set(test_name "octave-${script_basename}")
      add_test(
        NAME ${test_name}
        COMMAND ${MWRAP_OCTAVE_EXECUTABLE} --no-gui --quiet --eval "run('${runner_path_escaped}')"
        WORKING_DIRECTORY "${work_dir}"
      )
    endfunction()
  endif()

  set(_mwrap_enable_matlab_tests FALSE)
  if(_mwrap_matlab_index GREATER -1 AND DEFINED Matlab_MAIN_PROGRAM AND Matlab_MAIN_PROGRAM)
    set(_mwrap_enable_matlab_tests TRUE)
    function(_mwrap_add_matlab_smoke_test target_name)
      _mwrap_prepare_smoke_test_runner(${target_name} runner_file work_dir script_basename runner_path_escaped ${ARGN})

      set(test_name "matlab-${script_basename}")
      add_test(
        NAME ${test_name}
        COMMAND "${Matlab_MAIN_PROGRAM}" -batch "run('${runner_path_escaped}')"
        WORKING_DIRECTORY "${work_dir}"
      )
    endfunction()
  endif()

  if(_mwrap_enable_octave_tests OR _mwrap_enable_matlab_tests)
    set(fem_workspace "${CMAKE_CURRENT_BINARY_DIR}/fem_workspace")
    file(MAKE_DIRECTORY "${fem_workspace}/mwfem")

    macro(_mwrap_register_example_smoke_tests add_func)
      cmake_language(CALL "${add_func}" eventq_plain
        SCRIPT "${example_source_dir}/eventq/testq_plain.m"
        EXTRA_PATHS "${example_source_dir}/eventq"
      )
      cmake_language(CALL "${add_func}" eventq_handle
        SCRIPT "${example_source_dir}/eventq/testq_handle.m"
        EXTRA_PATHS "${example_source_dir}/eventq"
      )
      cmake_language(CALL "${add_func}" eventq_class
        SCRIPT "${example_source_dir}/eventq/testq_class.m"
        EXTRA_PATHS "${example_source_dir}/eventq"
      )
      cmake_language(CALL "${add_func}" eventq2
        SCRIPT "${example_source_dir}/eventq2/testq2.m"
        EXTRA_PATHS "${example_source_dir}/eventq2"
      )
      cmake_language(CALL "${add_func}" zlib
        SCRIPT "${example_source_dir}/zlib/testgz.m"
        EXTRA_PATHS "${example_source_dir}/zlib"
      )
      cmake_language(CALL "${add_func}" fem_interface
        SCRIPT "${example_source_dir}/fem/test_simple.m"
        WORKSPACE "${fem_workspace}"
        EXTRA_PATHS "${example_source_dir}/fem" "${fem_workspace}/mwfem"
      )
      cmake_language(CALL "${add_func}" fem_interface
        SCRIPT "${example_source_dir}/fem/test_patch.m"
        WORKSPACE "${fem_workspace}"
        EXTRA_PATHS "${example_source_dir}/fem" "${fem_workspace}/mwfem"
      )
      cmake_language(CALL "${add_func}" fem_interface
        SCRIPT "${example_source_dir}/fem/test_assembler.m"
        WORKSPACE "${fem_workspace}"
        EXTRA_PATHS "${example_source_dir}/fem" "${fem_workspace}/mwfem"
      )
    endmacro()
  endif()

  if(_mwrap_enable_octave_tests)
    _mwrap_register_example_smoke_tests(_mwrap_add_octave_smoke_test)
  endif()

  if(_mwrap_enable_matlab_tests)
    _mwrap_register_example_smoke_tests(_mwrap_add_matlab_smoke_test)
  endif()
endif()
