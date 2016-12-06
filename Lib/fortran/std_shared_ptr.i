//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_shared_ptr.i
 * \author Seth R Johnson
 * \date   Tue Dec 06 15:42:20 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%{
#include <memory>
%}

#define SWIG_SHARED_PTR_NAMESPACE std
%include <boost_shared_ptr.i>

//---------------------------------------------------------------------------//
// end of fortran/std_shared_ptr.i
//---------------------------------------------------------------------------//
