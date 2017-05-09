//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fortranruntime.swg
 * \author Seth R Johnson
 * \date   Tue May 02 12:24:27 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

// Needs to be in a .swg file to allow downstream modules to use definitions
// such as SWIG_RuntimeError
%insert(runtime) "swigerrors.swg";

%insert(runtime) %{
/* Contract support */
#define SWIG_contract_assert(nullreturn, expr, msg) if (!(expr)) { \
swig::fortran_store_exception(SWIG_ValueError, msg); return nullreturn; }
%}

//---------------------------------------------------------------------------//
// end of fortran/fortranruntime.swg
//---------------------------------------------------------------------------//
