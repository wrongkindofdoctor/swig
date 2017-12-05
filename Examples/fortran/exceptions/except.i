//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   exceptions/except.i
 * \author Seth R Johnson
 * \date   Thu Mar 02 10:54:30 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%module except;

//---------------------------------------------------------------------------//
// Define exception handler
%include <std_except.i>

%exception {
    swig::fortran_check_unhandled_exception();
    try
    {
        $action
    }
    catch (const std::exception& e)
    {
        SWIG_exception(SWIG_RuntimeError, e.what());
    }
    catch (const char* errstr)
    {
        SWIG_exception(SWIG_UnknownError, errstr);
    }
}

//---------------------------------------------------------------------------//
// Add support for views
%include <typemaps.i>
%fortran_view(int)

//---------------------------------------------------------------------------//
%{
#include "except.hh"
%}

%include "except.hh"

//---------------------------------------------------------------------------//
// end of exceptions/except.i
//---------------------------------------------------------------------------//
