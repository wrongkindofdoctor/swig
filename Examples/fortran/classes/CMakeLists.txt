##---------------------------------------------------------------------------##
## File  : classes/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Tue Dec 06 14:55:04 2016
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

# Build C++ library
INCLUDE_DIRECTORIES(${CMAKE_PROJECT_SOURCE_DIR})
ADD_LIBRARY(classeslib classes.cc)

# Generate SWIG module
MAKE_SWIG(MODULE classes
  DEPLIBS classeslib)

# Create test executable
ADD_EXECUTABLE(classes_test.exe runme.f90)
# It depends on the compiled fortran module
TARGET_LINK_LIBRARIES(classes_test.exe  ${SWIG_MODULE_classes_REAL_NAME})

# Create test
ADD_TEST(NAME classes_test COMMAND classes_test.exe)

##---------------------------------------------------------------------------##
## end of classes/CMakeLists.txt
##---------------------------------------------------------------------------##
