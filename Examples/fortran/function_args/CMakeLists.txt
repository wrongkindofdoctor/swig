SET(CMAKE_Fortran_FLAGS "-cpp ${CMAKE_Fortran_FLAGS}")

# Build C++ library
INCLUDE_DIRECTORIES(${CMAKE_PROJECT_SOURCE_DIR})
ADD_LIBRARY(functionargslib function_args.cc)

# Generate SWIG module
MAKE_SWIG(MODULE function_args
  DEPLIBS functionargslib)

# Create test executable
add_executable(function_args_test.exe test.f90)
# It depends on the compiled fortran module
target_link_libraries(function_args_test.exe ${SWIG_MODULE_function_args_REAL_NAME})

# Create test
ADD_TEST(NAME function_args_test COMMAND function_args_test.exe)
