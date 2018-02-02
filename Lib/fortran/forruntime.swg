//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fortranruntime.swg
 * \author Seth R Johnson
 * \date   Tue May 02 12:24:27 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include <typemaps/fragments.swg>

// Needs to be in a .swg file to allow downstream modules to use definitions
// such as SWIG_RuntimeError
%insert(runtime) "swigerrors.swg";

#ifdef __cplusplus
%fragment("<stdexcept>");
%insert(runtime) %{
// Default exception handler
#define SWIG_exception_impl(DECL, CODE, MSG, RETURNNULL) \
    throw std::logic_error("In " DECL ": " MSG); RETURNNULL;
%}
#else
%insert(runtime) %{
#include <assert.h>
/* Default C exception handler */
#define SWIG_exception_impl(DECL, CODE, MSG, RETURNNULL) \
    printf(stderr, "In " DECL ": " MSG, NULL); assert(0); RETURNNULL;
%}
#endif

// Note that RETURNNULL is first because it's inserted via a 'Replaceall' in
// the fortran.cxx file.
%insert(runtime) %{
/* Contract support */
#define SWIG_contract_assert(RETURNNULL, EXPR, MSG) \
    if (!(EXPR)) { SWIG_exception_impl("$decl", SWIG_ValueError, MSG, RETURNNULL); }
%}

//---------------------------------------------------------------------------//
// end of fortran/fortranruntime.swg
//---------------------------------------------------------------------------//
