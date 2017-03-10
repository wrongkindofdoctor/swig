//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   exceptions/except.i
 * \author Seth R Johnson
 * \date   Thu Mar 02 10:54:30 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%module except;

//%include <std_except>

%exception {
    swig::fortran_delayed_exception_check();
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

%{
#include "except.hh"
%}

%include "except.hh"

//---------------------------------------------------------------------------//
// end of exceptions/except.i
//---------------------------------------------------------------------------//
