//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   std_vector/stdvec.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 09:05:31 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%module stdvec

%{
#include <utility>
#include "stdvec.hh"
%}

//---------------------------------------------------------------------------//
// Include double
//---------------------------------------------------------------------------//

%include <std_vector.i>
%template(VecDbl) std::vector<double>;

//---------------------------------------------------------------------------//
// Instantiate a view template and add a "view" method.
//---------------------------------------------------------------------------//

%include "stdvec.hh"

//---------------------------------------------------------------------------//

%template(make_viewdbl) make_view<double>;
%template(make_const_viewdbl) make_const_view<double>;
%template(print_viewdbl) print_view<double>;

//---------------------------------------------------------------------------//
// end of std_vector/stdvec.i
//---------------------------------------------------------------------------//
