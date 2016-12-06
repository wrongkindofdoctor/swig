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

%define TEMPLATE_ALGORITHMS(EXT, TYPE)
    %apply (SWIGTYPE* ARRAY, int SIZE) { (TYPE* ARRAY, TYPE SIZE),
                                         (const TYPE* ARRAY, int SIZE) }

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
