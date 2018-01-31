//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/exception.i
 * \author Seth R Johnson
 * \date   Fri Apr 28 18:33:31 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 *
 * This file is automatically included when the user loads <std_except.i>. It
 * assumes C++.
 *
 * Example use: \code

%include <std_except.i>

%exception {
    // Make sure no unhandled exceptions exist before performing a new action
    SWIG_check_unhandled_exception();
    try
    {
        // Attempt the wrapped function call
        $action
    }
    catch (const std::exception& e)
    {
        // Store a C++ exception
        SWIG_exception(SWIG_RuntimeError, e.what());
    }
    catch (...)
    {
        SWIG_exception(SWIG_UnknownError, "An unknown exception occurred");
    }
}

 * \endcode
 *
 */
//---------------------------------------------------------------------------//

// Allow the user to change the name of the error flag on the fortran side
#ifndef SWIG_FORTRAN_ERROR_INT
#define SWIG_FORTRAN_ERROR_INT ierr
#define SWIG_FORTRAN_ERROR_STR get_serr
#endif

//---------------------------------------------------------------------------//
// Fortran variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
#ifndef SWIGIMPORTED

// Declare a public variable
%fragment("SWIG_fortran_error_public", "fpublic") {
 public :: SWIG_FORTRAN_ERROR_INT
}
// Fortran error variables
%fragment("SWIG_fortran_error_int", "fparams",
          fragment="SWIG_fortran_error_public") {
 integer(C_INT), bind(C) :: SWIG_FORTRAN_ERROR_INT
}

#endif

//---------------------------------------------------------------------------//
// Function declaration: whether imported or not
//---------------------------------------------------------------------------//

%fragment("SWIG_exception_decl", "runtime") {
void SWIG_check_unhandled_exception();
void SWIG_store_exception(int code, const char *msg);
}

//---------------------------------------------------------------------------//
// Variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
%fragment("SWIG_exception", "header",
          fragment="SWIG_fortran_error_int",
          fragment="<string>",
          fragment="<algorithm>", fragment="<stdexcept>")
{
extern "C" {
SWIGEXPORT int SWIG_FORTRAN_ERROR_INT = 0;
}

// Stored exception message
SWIGINTERN std::string swig_last_exception_msg;

// Call this function before any new action
SWIGEXPORT void SWIG_check_unhandled_exception()
{
    if (::SWIG_FORTRAN_ERROR_INT != 0)
    {
        throw std::runtime_error(
                "An unhandled exception occurred in a previous call: "
                + swig_last_exception_msg);
    }
}

// Save an exception to the fortran error code and string
SWIGEXPORT void SWIG_store_exception(int code, const char *msg)
{
    ::SWIG_FORTRAN_ERROR_INT = code;

    // Save the message to a std::string first
    swig_last_exception_msg = msg;
}

}

//---------------------------------------------------------------------------//
// Runtime code (always added)
//---------------------------------------------------------------------------//
// Override the default exception handler from fortranruntime.swg
// Note that SWIG_exception_impl is used by SWIG_contract_assert, so the
// *_impl* is the one that changes.
%fragment("SWIG_exception_impl", "runtime") %{
#undef SWIG_exception_impl
#define SWIG_exception_impl(CODE, MSG, RETURNNULL) \
    SWIG_store_exception(CODE, MSG); RETURNNULL;
%}

// Note that this replaces wrapper code: the phrase "SWIG_exception" never
// shows up in the .cxx file
#define SWIG_exception(CODE, MSG) \
    SWIG_exception_impl(CODE, MSG, return $null)

//---------------------------------------------------------------------------//
// Insert exception code (will insert different code depending on if C/C++ and
// whether or not this module is being %imported)
%fragment("SWIG_exception_impl");
%fragment("SWIG_exception_decl");
#ifndef SWIGIMPORTED
%fragment("SWIG_exception");
#endif

//---------------------------------------------------------------------------//
// Functional interface to swig error string
//---------------------------------------------------------------------------//
%include <typemaps.i>

// Declare typedef for special string conversion typemaps
%inline %{
typedef std::string Swig_Err_String;
%}

%apply const std::string& NATIVE { const Swig_Err_String& };

// Get a pointer to the error string
%inline {
const Swig_Err_String& SWIG_FORTRAN_ERROR_STR()
{
    return swig_last_exception_msg;
}
}

//---------------------------------------------------------------------------//
// end of fortran/exception.i
//---------------------------------------------------------------------------//
