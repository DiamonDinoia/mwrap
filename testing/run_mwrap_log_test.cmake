if(NOT DEFINED MWRAP_EXECUTABLE)
  message(FATAL_ERROR "MWRAP_EXECUTABLE is required")
endif()

if(NOT DEFINED OUTPUT_FILE)
  message(FATAL_ERROR "OUTPUT_FILE is required")
endif()

if(NOT DEFINED REFERENCE_FILE)
  message(FATAL_ERROR "REFERENCE_FILE is required")
endif()

if(NOT DEFINED TEST_NAME)
  set(TEST_NAME "mwrap_test")
endif()

set(_args "")
if(DEFINED ARGC)
  if(ARGC GREATER 0)
    math(EXPR _last_index "${ARGC} - 1")
    foreach(_arg_index RANGE 0 ${_last_index})
      set(_var_name ARG${_arg_index})
      if(DEFINED ${_var_name})
        list(APPEND _args "${${_var_name}}")
      else()
        message(FATAL_ERROR "${TEST_NAME}: missing argument ${_var_name}")
      endif()
    endforeach()
  endif()
endif()

if(DEFINED WORKING_DIRECTORY)
  set(_working_directory ${WORKING_DIRECTORY})
else()
  set(_working_directory ${CMAKE_CURRENT_BINARY_DIR})
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

set(expect_nonzero OFF)
if(DEFINED EXPECT_NONZERO)
  if(EXPECT_NONZERO)
    set(expect_nonzero ON)
  endif()
endif()

if(expect_nonzero)
  if(run_result EQUAL 0)
    message(FATAL_ERROR "${TEST_NAME}: expected failure but command succeeded")
  endif()
else()
  if(NOT run_result EQUAL 0)
    message(FATAL_ERROR "${TEST_NAME}: command failed with exit code ${run_result}")
  endif()
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
