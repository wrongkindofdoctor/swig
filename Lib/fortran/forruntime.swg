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
#define SWIG_exception_impl(CODE, MSG, NULLRETURN) \
    throw std::logic_error(MSG); return NULLRETURN;
%}
#else
%fragment("<assert.h>");
%insert(runtime %{
/* Default C exception handler */
#define SWIG_exception_impl(CODE, MSG, NULLRETURN) \
    printf(stderr, MSG, NULL); assert(0); return NULLRETURN;
%}
#endif

%insert(runtime) %{
/* Contract support */
#define SWIG_contract_assert(NULLRETURN, EXPR, MSG) \
    if (!(EXPR)) { SWIG_exception_impl(SWIG_ValueError, MSG, NULLRETURN); }
%}

//---------------------------------------------------------------------------//
// end of fortran/fortranruntime.swg
//---------------------------------------------------------------------------//
