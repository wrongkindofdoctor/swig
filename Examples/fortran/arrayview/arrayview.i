//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   arrayview/arrayview.i
 * \author Seth R Johnson
 * \date   Tue Dec 06 11:21:44 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%module arrayview

%{
#include "arrayview.hh"
%}

%include <typemaps.i>

%define TEMPLATE_ALGORITHMS(TYPE)
    // Instantiate std::pair <-> array pointer mapping
    %fortran_view(TYPE)

    %template(sort)        sort< TYPE >;
    %template(reverse)     reverse< TYPE >;
    %template(find_sorted) find_sorted< TYPE >;
    %template(get_view)    get_view< TYPE >;
    %template(print_array) print_array< TYPE >;
%enddef

%include "arrayview.hh"

TEMPLATE_ALGORITHMS(int)
TEMPLATE_ALGORITHMS(float)
TEMPLATE_ALGORITHMS(double)

//---------------------------------------------------------------------------//
// end of algorithms/algorithm.i
//---------------------------------------------------------------------------//
