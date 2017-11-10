//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   swig-dev/bare_function/bare.i
 * \author Seth R Johnson
 * \date   Fri Jan 16 23:51:44 2015
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%module bare

%{
#include "bare.hh"
%}

//! A const integer
// const int param_int = 4;
// const int wrapped_int = 0x1337;

#define MY_SPECIAL_NUMBERS 5
%constant int param_const = 911;
%constant int octal_const = 0777;
%constant int wrapped_const = 0xdeadbeef;

// Force a constant to be a compile-time native fortran parameter
%parameter approx_pi;

#ifdef SWIGFORTRAN
%include <typemaps.i>

// Instantiate array pointer conversion for doubles from pair<double*,size_t>
%fortran_view(double)
#endif

%include "bare.hh"

//---------------------------------------------------------------------------//
// end of swig-dev/bare_function/bare.i
//---------------------------------------------------------------------------//
