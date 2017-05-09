//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   thinvec/ThinVec.i
 * \author Seth R Johnson
 * \date   Mon Jan 19 08:59:42 2015
 * \note   Copyright (c) 2015 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%{
#include "ThinVec.hh"
%}

%module thinvec

#ifdef SWIGFORTRAN

%include <typemaps.i>

// Handle constructor overloading
%rename(create_count)  ThinVec::ThinVec(size_type);
//%ignore   ThinVec::ThinVec(size_type, value_type);
%rename(create_fill)   ThinVec::ThinVec(size_type, value_type);

// Rename a function that's the same as a Fortran keyword
%rename(ass) ThinVec::assign;

// Works with void obtain(double* p, size_type count)
// and (T* p, size_type count)
// but not (pointer p, size_type count)
// see https://github.com/swig/swig/issues/846
%apply (SWIGTYPE* ARRAY, int SIZE) {
       (double* p, unsigned int count),
       (const double* p, unsigned int count),
       (int* p, unsigned int count),
       (const int* p, unsigned int count) };

#endif

// Handle the case of operator overloading
%rename(resize_fill) ThinVec::resize(size_type, value_type);

// Ignore return of types we don't understand
%ignore ThinVec::data() const;

// Load the thinvec class definition
%include "ThinVec.hh"

// Instantiate
%template(ThinVecDbl) ThinVec<double>;
%template(obtain_free_d) obtain_free_t<double>;

%template(ThinVecInt) ThinVec<int>;
%template(obtain_free_i) obtain_free_t<int>;

//---------------------------------------------------------------------------//
// end of swig-dev/thinvec/ThinVec.i
//---------------------------------------------------------------------------//
