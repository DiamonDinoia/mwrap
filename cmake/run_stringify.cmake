if(NOT DEFINED STRINGIFY)
  message(FATAL_ERROR "STRINGIFY executable location is required")
endif()
if(NOT DEFINED INPUT)
  message(FATAL_ERROR "INPUT file is required")
endif()
if(NOT DEFINED OUTPUT)
  message(FATAL_ERROR "OUTPUT file is required")
endif()
if(NOT DEFINED NAME)
  message(FATAL_ERROR "String symbol NAME is required")
endif()

execute_process(
  COMMAND "${STRINGIFY}" "${NAME}"
  INPUT_FILE "${INPUT}"
  OUTPUT_FILE "${OUTPUT}"
  RESULT_VARIABLE _stringify_result
)
if(NOT _stringify_result EQUAL 0)
  message(FATAL_ERROR "stringify failed with exit code ${_stringify_result}")
endif()
