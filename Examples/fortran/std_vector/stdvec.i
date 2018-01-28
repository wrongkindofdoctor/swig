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
// EXTEND VECTOR TO HAVE VIEWS
//---------------------------------------------------------------------------//

%include <typemaps.i>

%define ADD_VIEW(TYPE)

// Instantiate view typemap
%fortran_view(double)

// Replace ULL type with fortran standard integer
%apply int { std::vector<TYPE>::size_type };

// Extend vector
%extend std::vector<TYPE> {
    void fill(std::pair<const TYPE*, std::size_t> view)
    {
        $self->assign(view.first, view.first + view.second);
    }

    std::pair<TYPE*, std::size_t> view()
    {
        if ($self->empty())
            return {nullptr, 0};
        return {$self->data(), $self->size()};
    }
} // end extend

%enddef

//---------------------------------------------------------------------------//
// Instantiate the vector-double
//---------------------------------------------------------------------------//

%include <std_vector.i>

ADD_VIEW(double)

%template(VecDbl) std::vector<double>;

//---------------------------------------------------------------------------//
// Parse and instantiate the templated functions
//---------------------------------------------------------------------------//

// Make the single "get_vec_ref" function return a native allocated fortran array
// (This is enabled by the
%apply const std::vector<double>& NATIVE { const std::vector<double>& get_vec_ref<double> };

%include "stdvec.hh"

%template(make_viewdbl) make_view<double>;
%template(make_const_viewdbl) make_const_view<double>;
%template(print_viewdbl) print_view<double>;
%template(get_vec_refdbl) get_vec_ref<double>;

//---------------------------------------------------------------------------//
// end of std_vector/stdvec.i
//---------------------------------------------------------------------------//
