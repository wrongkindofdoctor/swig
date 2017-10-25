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

%include <typemaps.i>

%define TEMPLATE_ALGORITHMS(TYPE)
    // Instantiate std::pair mapping
    %fortran_view(TYPE)

    %template(sort)        sort< TYPE >;
    %template(reverse)     reverse< TYPE >;
    %template(find_sorted) find_sorted< TYPE >;
    %template(get_view)    get_view< TYPE >;
%enddef

%include "algorithm.hh"

TEMPLATE_ALGORITHMS(int)
TEMPLATE_ALGORITHMS(float)
TEMPLATE_ALGORITHMS(double)

//---------------------------------------------------------------------------//
// end of algorithms/algorithm.i
//---------------------------------------------------------------------------//
