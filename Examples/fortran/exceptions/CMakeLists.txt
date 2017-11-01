##---------------------------------------------------------------------------##
## File  : exceptions/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Thu Mar 02 10:54:30 2017
## Brief : TriBITS package file for exceptions/
## Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

SET(CMAKE_Fortran_FLAGS "-cpp ${CMAKE_Fortran_FLAGS}")

# Build C++ library
INCLUDE_DIRECTORIES(${CMAKE_PROJECT_SOURCE_DIR})
ADD_LIBRARY(exceptlib except.cc)

# Generate SWIG module
MAKE_SWIG(MODULE except
  DEPLIBS exceptlib)

# Generate second SWIG module that imports the first
MAKE_SWIG(MODULE downstream
  DEPLIBS ${SWIG_MODULE_except_REAL_NAME})

# Create test executable
ADD_EXECUTABLE(exceptions_test.exe test.f90)
# It depends on the compiled fortran module
TARGET_LINK_LIBRARIES(exceptions_test.exe
    ${SWIG_MODULE_except_REAL_NAME}
    ${SWIG_MODULE_downstream_REAL_NAME})

# Create test
ADD_TEST(NAME exceptions_test COMMAND exceptions_test.exe)

##---------------------------------------------------------------------------##
## end of exceptions/CMakeLists.txt
##---------------------------------------------------------------------------##
