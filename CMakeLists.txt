cmake_minimum_required(VERSION 3.16)

project(mwrap LANGUAGES C CXX)

include(CTest)

set(MWRAP_PROFILE "USER" CACHE STRING "Select the mwrap build profile (USER or DEVELOPER)")
set_property(CACHE MWRAP_PROFILE PROPERTY STRINGS USER DEVELOPER)

option(MWRAP_ENABLE_MATLAB_CLASSDEF "Enable MATLAB classdef support (adds -DR2008OO)" OFF)
option(MWRAP_ENABLE_C99_COMPLEX "Enable C99 complex support helpers" OFF)
option(MWRAP_ENABLE_CPP_COMPLEX "Enable C++ complex support helpers" OFF)
option(MWRAP_BUILD_EXAMPLES "Build the MATLAB/Octave examples" OFF)
option(MWRAP_COMPILE_MEX "Compile generated wrappers into MEX binaries" OFF)
set(MWRAP_MEX_BACKEND "MATLAB" CACHE STRING "Select the MEX backend to use (MATLAB, OCTAVE, or ALL)")
set_property(CACHE MWRAP_MEX_BACKEND PROPERTY STRINGS MATLAB OCTAVE ALL)

set(MWRAP_MEX_BACKENDS "" CACHE INTERNAL "Resolved list of MEX backends to configure" FORCE)

unset(MWRAP_OCTAVE_MKOCTFILE_EXECUTABLE CACHE)

if(MWRAP_COMPILE_MEX)
  string(TOUPPER "${MWRAP_MEX_BACKEND}" _mwrap_mex_backend_upper)

  if(_mwrap_mex_backend_upper STREQUAL "ALL")
    set(_mwrap_resolved_backends MATLAB OCTAVE)
  elseif(_mwrap_mex_backend_upper STREQUAL "MATLAB")
    set(_mwrap_resolved_backends MATLAB)
  elseif(_mwrap_mex_backend_upper STREQUAL "OCTAVE")
    set(_mwrap_resolved_backends OCTAVE)
  else()
    message(FATAL_ERROR
      "Invalid MWRAP_MEX_BACKEND value '${MWRAP_MEX_BACKEND}'. "
      "Allowed values are MATLAB, OCTAVE, or ALL.")
  endif()

  set(MWRAP_MEX_BACKENDS "${_mwrap_resolved_backends}" CACHE INTERNAL
    "Resolved list of MEX backends to configure" FORCE)

  set(_mwrap_enable_matlab OFF)
  set(_mwrap_enable_octave OFF)
  foreach(_mwrap_backend IN LISTS _mwrap_resolved_backends)
    if(_mwrap_backend STREQUAL "MATLAB")
      set(_mwrap_enable_matlab ON)
    elseif(_mwrap_backend STREQUAL "OCTAVE")
      set(_mwrap_enable_octave ON)
    endif()
  endforeach()

  if(_mwrap_enable_matlab)
    find_package(Matlab COMPONENTS MEX_COMPILER MX_LIBRARY REQUIRED)
  endif()

  if(_mwrap_enable_octave)
    set(_mwrap_octave_mkoctfile "")

    find_package(Octave QUIET COMPONENTS Octave_MKOCTFILE)
    if(Octave_FOUND)
      foreach(_mwrap_candidate_var IN ITEMS
          Octave_OCTAVE_MKOCTFILE_EXECUTABLE
          Octave_MKOCTFILE_EXECUTABLE
          Octave_MKOCTFILE)
        if(NOT _mwrap_octave_mkoctfile AND DEFINED ${_mwrap_candidate_var}
            AND ${_mwrap_candidate_var})
          set(_mwrap_octave_mkoctfile "${${_mwrap_candidate_var}}")
        endif()
      endforeach()
    endif()

    if(NOT _mwrap_octave_mkoctfile)
      find_program(_mwrap_octave_mkoctfile mkoctfile)
    endif()

    if(NOT _mwrap_octave_mkoctfile)
      message(FATAL_ERROR
        "MWRAP_MEX_BACKEND requested Octave support but 'mkoctfile' was not found.")
    endif()

    set(MWRAP_OCTAVE_MKOCTFILE_EXECUTABLE "${_mwrap_octave_mkoctfile}" CACHE FILEPATH
      "Path to the Octave mkoctfile executable" FORCE)
  else()
    unset(MWRAP_OCTAVE_MKOCTFILE_EXECUTABLE CACHE)
  endif()
else()
  set(MWRAP_MEX_BACKENDS "" CACHE INTERNAL
    "Resolved list of MEX backends to configure" FORCE)
  unset(MWRAP_OCTAVE_MKOCTFILE_EXECUTABLE CACHE)
endif()

add_subdirectory(src)

if(MWRAP_BUILD_EXAMPLES)
  add_subdirectory(example)
endif()

if(BUILD_TESTING)
  add_subdirectory(testing)
endif()
