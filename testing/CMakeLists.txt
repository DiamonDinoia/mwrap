cmake_minimum_required(VERSION 3.16)

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
            -P ${CMAKE_CURRENT_SOURCE_DIR}/run_mwrap_log_test.cmake
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
