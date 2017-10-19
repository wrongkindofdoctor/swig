##---------------------------------------------------------------------------##
## File  : algorithm/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Tue Dec 06 11:46:55 2016
## Brief : TriBITS package file for algorithm/
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

# Build C++ library
INCLUDE_DIRECTORIES(${CMAKE_PROJECT_SOURCE_DIR})

# Generate SWIG module
MAKE_SWIG(MODULE algorithm)

# Create test executable
ADD_EXECUTABLE(algorithm_test.exe test.f90)
# It depends on the compiled fortran module
TARGET_LINK_LIBRARIES(algorithm_test.exe ${SWIG_MODULE_algorithm_REAL_NAME})

# Create test
ADD_TEST(NAME algorithm_test COMMAND algorithm_test.exe)

##---------------------------------------------------------------------------##
## end of algorithm/CMakeLists.txt
##---------------------------------------------------------------------------##
