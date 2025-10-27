set(_mwrap_log_test_driver "${CMAKE_CURRENT_BINARY_DIR}/mwrap_log_test.cmake")
set(_mwrap_log_test_script [[
if(NOT DEFINED MWRAP_EXECUTABLE)
  message(FATAL_ERROR "MWRAP_EXECUTABLE is required")
endif()

foreach(var OUTPUT_FILE REFERENCE_FILE)
  if(NOT DEFINED ${var})
    message(FATAL_ERROR "${var} is required")
  endif()
endforeach()

if(NOT DEFINED TEST_NAME)
  set(TEST_NAME "mwrap_test")
endif()

set(_args)
if(DEFINED ARGC AND ARGC GREATER 0)
  math(EXPR _last_index "${ARGC} - 1")
  foreach(_arg_index RANGE 0 ${_last_index})
    set(_var_name ARG${_arg_index})
    if(NOT DEFINED ${_var_name})
      message(FATAL_ERROR "${TEST_NAME}: missing argument ${_var_name}")
    endif()
    list(APPEND _args "${${_var_name}}")
  endforeach()
endif()

set(_working_directory "${CMAKE_CURRENT_LIST_DIR}")
if(DEFINED WORKING_DIRECTORY)
  set(_working_directory "${WORKING_DIRECTORY}")
endif()

file(MAKE_DIRECTORY "${_working_directory}")

set(stdout_file "${OUTPUT_FILE}.stdout")
execute_process(
  COMMAND ${MWRAP_EXECUTABLE} ${_args}
  RESULT_VARIABLE run_result
  OUTPUT_FILE "${stdout_file}"
  ERROR_FILE "${OUTPUT_FILE}"
  WORKING_DIRECTORY "${_working_directory}"
)

set(expect_nonzero FALSE)
if(DEFINED EXPECT_NONZERO AND EXPECT_NONZERO)
  set(expect_nonzero TRUE)
endif()

if(expect_nonzero AND run_result EQUAL 0)
  message(FATAL_ERROR "${TEST_NAME}: expected failure but command succeeded")
endif()

if(NOT expect_nonzero AND NOT run_result EQUAL 0)
  message(FATAL_ERROR "${TEST_NAME}: command failed with exit code ${run_result}")
endif()

if(NOT EXISTS "${REFERENCE_FILE}")
  message(FATAL_ERROR "${TEST_NAME}: reference file '${REFERENCE_FILE}' not found")
endif()

file(READ "${OUTPUT_FILE}" output_contents)
string(REPLACE "end of file" "$end" normalized_output "${output_contents}")
if(NOT normalized_output STREQUAL output_contents)
  file(WRITE "${OUTPUT_FILE}" "${normalized_output}")
endif()

execute_process(
  COMMAND ${CMAKE_COMMAND} -E compare_files "${OUTPUT_FILE}" "${REFERENCE_FILE}"
  RESULT_VARIABLE diff_result
)

if(NOT diff_result EQUAL 0)
  file(READ "${OUTPUT_FILE}" normalized_output)
  message(FATAL_ERROR "${TEST_NAME}: output does not match reference.\n--- Actual stderr ---\n${normalized_output}")
endif()
]])
file(WRITE "${_mwrap_log_test_driver}" "${_mwrap_log_test_script}")

function(_mwrap_add_log_test name)
  set(options EXPECT_NONZERO)
  set(oneValueArgs REFERENCE)
  set(multiValueArgs ARGS)
  cmake_parse_arguments(_MWRAP_TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT _MWRAP_TEST_REFERENCE)
    message(FATAL_ERROR "_mwrap_add_log_test requires REFERENCE for test '${name}'")
  endif()

  set(log_file "${CMAKE_CURRENT_BINARY_DIR}/${name}.log")
  list(LENGTH _MWRAP_TEST_ARGS arg_count)
  set(arg_definitions -DARGC=${arg_count})
  if(arg_count GREATER 0)
    math(EXPR arg_max "${arg_count} - 1")
    foreach(arg_index RANGE 0 ${arg_max})
      list(GET _MWRAP_TEST_ARGS ${arg_index} arg_value)
      list(APPEND arg_definitions -DARG${arg_index}=${arg_value})
    endforeach()
  endif()

  add_test(
    NAME ${name}
    COMMAND ${CMAKE_COMMAND}
            -DMWRAP_EXECUTABLE=$<TARGET_FILE:mwrap>
            -DOUTPUT_FILE=${log_file}
            -DREFERENCE_FILE=${_MWRAP_TEST_REFERENCE}
            -DEXPECT_NONZERO=${_MWRAP_TEST_EXPECT_NONZERO}
            -DTEST_NAME=${name}
            -DWORKING_DIRECTORY=${CMAKE_CURRENT_SOURCE_DIR}
            ${arg_definitions}
            -P ${_mwrap_log_test_driver}
  )

  set_tests_properties(${name} PROPERTIES WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endfunction()

_mwrap_add_log_test(
  mwrap.test_syntax
  EXPECT_NONZERO
  REFERENCE ${CMAKE_CURRENT_SOURCE_DIR}/test_syntax.ref
  ARGS -cppcomplex test_syntax.mw
)

_mwrap_add_log_test(
  mwrap.test_typecheck
  EXPECT_NONZERO
  REFERENCE ${CMAKE_CURRENT_SOURCE_DIR}/test_typecheck.ref
  ARGS -cppcomplex test_typecheck.mw
)

if(CMAKE_CONFIGURATION_TYPES)
  add_custom_target(mwrap_tests
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure -C $<CONFIG>
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
  )
else()
  add_custom_target(mwrap_tests
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
  )
endif()

add_dependencies(mwrap_tests mwrap)
set_property(TARGET mwrap_tests PROPERTY FOLDER "tests")
