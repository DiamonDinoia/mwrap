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
        if(_mex_path MATCHES "\\$<TARGET_FILE:")
          set(_mex_source_path "${_mex_path}")
          set(_mex_dest_name "$<TARGET_FILE_NAME:${_mex_target}>")
        else()
          set(_mex_source_path "${_mex_path}")
          get_filename_component(_mex_dest_name "${_mex_path}" NAME)
        endif()

        add_custom_command(TARGET ${_mex_target} POST_BUILD
          COMMAND ${CMAKE_COMMAND} -E make_directory "${_mex_output_dir}"
          COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${_mex_source_path}"
            "${_mex_output_dir}/${_mex_dest_name}"
        )
      endif()

      math(EXPR _mex_index "${_mex_index} + 1")
    endforeach()
  endforeach()
endif()
