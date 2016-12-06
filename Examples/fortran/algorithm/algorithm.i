//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   algorithms/algorithm.i
 * \author Seth R Johnson
 * \date   Tue Dec 06 11:21:44 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%module algorithm

%{
#include "algorithm.hh"
%}

%apply (SWIGTYPE* ARRAY, int SIZE) { (      int* ARRAY, int SIZE),
                                     (const int* ARRAY, int SIZE),
                                     (      float* ARRAY, int SIZE),
                                     (const float* ARRAY, int SIZE),
                                     (      double* ARRAY, int SIZE),
                                     (const double* ARRAY, int SIZE) }

%define TEMPLATE_ALGORITHMS(EXT, TYPE)
    %apply (SWIGTYPE* ARRAY, int SIZE) { (TYPE* ARRAY, int SIZE),
                                         (const TYPE* ARRAY, int SIZE) }

    %template(sort_ ## EXT)        sort< TYPE >;
    %template(reverse_ ## EXT)     reverse< TYPE >;
    %template(find_sorted_ ## EXT) find_sorted< TYPE >;
%enddef

%include "algorithm.hh"

TEMPLATE_ALGORITHMS(integer, int)
TEMPLATE_ALGORITHMS(real4,   float)
TEMPLATE_ALGORITHMS(real8,   double)

//---------------------------------------------------------------------------//
// end of algorithms/algorithm.i
//---------------------------------------------------------------------------//
