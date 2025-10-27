cmake_minimum_required(VERSION 3.16)

include(${CMAKE_SOURCE_DIR}/cmake/MwrapAddMex.cmake)

add_custom_target(mwrap_examples)

set(example_source_dir "${CMAKE_CURRENT_SOURCE_DIR}")

set(_mwrap_example_targets
  foobar_example
  eventq_plain_example
  eventq_handle_example
  eventq_class_example
  eventq2_example
  zlib_example
  fem_interface_example
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

mwrap_add_mex(foobar_example
  MEX_NAME fbmex
  CC_FILENAME fbmex.cc
  M_FILENAME foobar.m
  MW_FILES "${example_source_dir}/foobar/foobar.mw"
)

mwrap_add_mex(eventq_plain_example
  MEX_NAME eventqpmex
  CC_FILENAME eventqpmex.cc
  MW_FILES "${example_source_dir}/eventq/eventq_plain.mw"
  MWRAP_FLAGS -mb
)

mwrap_add_mex(eventq_handle_example
  MEX_NAME eventqhmex
  CC_FILENAME eventqhmex.cc
  MW_FILES "${example_source_dir}/eventq/eventq_handle.mw"
  MWRAP_FLAGS -mb
)

mwrap_add_mex(eventq_class_example
  MEX_NAME eventqcmex
  CC_FILENAME eventqcmex.cc
  MW_FILES "${example_source_dir}/eventq/eventq_class.mw"
  MWRAP_FLAGS -mb
  CLASSDEF_NAME eventq
)

mwrap_add_mex(eventq2_example
  MEX_NAME eventq2mex
  CC_FILENAME eventq2mex.cc
  MW_FILES "${example_source_dir}/eventq2/eventq2.mw"
  MWRAP_FLAGS -mb
)

mwrap_add_mex(zlib_example
  MEX_NAME gzmex
  CC_FILENAME gzmex.cc
  MW_FILES "${example_source_dir}/zlib/gzfile.mw"
  MWRAP_FLAGS -mb
)

mwrap_add_mex(fem_interface_example
  WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/fem/interface"
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

if(MWRAP_COMPILE_MEX)
  foreach(example_target IN LISTS _mwrap_example_targets)
    _mwrap_compile_mex(${example_target} OUTPUT_VAR _mwrap_mex_target)
    if(_mwrap_mex_target)
      add_dependencies(mwrap_examples ${_mwrap_mex_target})
    endif()
  endforeach()
endif()
