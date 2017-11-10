//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   swig-dev/bare_function/bare.hh
 * \author Seth R Johnson
 * \date   Fri Jan 16 21:19:07 2015
 * \brief  bare declaration
 * \note   Copyright (c) 2015 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#ifndef swig_dev_bare_function_foo_hh
#define swig_dev_bare_function_foo_hh

#include <cstddef>
#include <utility>

//---------------------------------------------------------------------------//

void set_something(int x, double y);
double get_something(int x);
void get_something_ref(int x, double& y);
void get_something_ptr(int x, double* y);

double* get_something_rptr(int x);
const double* get_something_rcptr(int x);
double& get_something_rref(int x);
const double& get_something_rcref(int x);

void print_array(std::pair<const double*, size_t> arr);

//---------------------------------------------------------------------------//

//! An enumeration declared using external C variables
// (since it has complicated values that must be evaluated by the C compiler)
enum MyEnum {
    RED = 0,
    GREEN = 0x4,
    BLUE,
};

//! An enumeration that uses native wrapping
enum NativeEnum {
    CYAN = 0,
    MAGENTA,
    YELLOW,
    BLACK = -1
};

//! A const integer
const int param_int = 4;

const int wrapped_int = 0x1337;

//! A global constant wrapped as a native parameter
const double approx_pi = 3.1416;

//! A global constant wrapped as a protected external variable
const double approx_twopi = 2 * approx_pi;

//! A global variable
namespace foo
{
extern int global_counter;
}

// Get a color name
void print_color(MyEnum color);

//---------------------------------------------------------------------------//
#endif // swig_dev_bare_function_foo_hh

//---------------------------------------------------------------------------//
// end of swig-dev/bare_function/bare.hh
//---------------------------------------------------------------------------//
