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
enum RgbEnum {
    RED = 0,
    GREEN = 0x4,
    BLUE = (1 << 10),
};

//! An enumeration that uses native wrapping
enum CmykEnum {
    CYAN = 0,
    MAGENTA,
    YELLOW,
    BLACK = -1
};

//! An integer that is only known at link time
extern const int linked_const_int;

//! A simple integer
const int simple_int = 4;

// A more complicated integer
const int weird_int = (0x1337 | 0x10000);

//! A global constant wrapped as a native parameter
const double approx_pi = 3.14160000001;

//! A global constant wrapped as a protected external variable
const double approx_twopi = 2 * approx_pi;

//! A global variable
namespace foo
{
extern int global_counter;
}

// Get a color name
void print_rgb(RgbEnum color);
void print_cmyk(CmykEnum color);

//---------------------------------------------------------------------------//
#endif // swig_dev_bare_function_foo_hh

//---------------------------------------------------------------------------//
// end of swig-dev/bare_function/bare.hh
//---------------------------------------------------------------------------//
