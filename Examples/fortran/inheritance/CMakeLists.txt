##---------------------------------------------------------------------------##
## File  : inheritance/CMakeLists.txt
## Author: Mitchell TH Young
## Date  : Mon Jan  2 2017
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

SET(CMAKE_Fortran_FLAGS "-cpp ${CMAKE_Fortran_FLAGS}")
SET(CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS}")

# Build C++ library
INCLUDE_DIRECTORIES(${CMAKE_PROJECT_SOURCE_DIR})
ADD_LIBRARY(classeslib classes.cc)

# Generate SWIG module
MAKE_SWIG(MODULE classes
  DEPLIBS classeslib)

# Create test executable
add_executable(classes_test.exe test.f90)
# It depends on the compiled fortran module
target_link_libraries(classes_test.exe ${SWIG_MODULE_classes_REAL_NAME})

# Create test
ADD_TEST(NAME classes_test COMMAND classes_test.exe)

##---------------------------------------------------------------------------##
## end of inheritance/CMakeLists.txt
##---------------------------------------------------------------------------##
