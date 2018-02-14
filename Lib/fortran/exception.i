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
// Fortran variable declaration: used only if %included, not %imported
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
#define SWIG_check_unhandled_exception() \
    SWIG_check_unhandled_exception_impl("$decl");
void SWIG_check_unhandled_exception_impl(const char* decl);
void SWIG_store_exception(const char* decl, int errcode, const char *msg);
}

//---------------------------------------------------------------------------//
// Variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
%fragment("SWIG_exception", "header",
          fragment="SWIG_fortran_error_int",
          fragment="<string>", fragment="<cctype>",
          fragment="<algorithm>", fragment="<stdexcept>")
{
extern "C" {
SWIGEXPORT int SWIG_FORTRAN_ERROR_INT = 0;
}

// Stored exception message
SWIGINTERN std::string* swig_last_exception_msg = NULL;

// Declare %inlined error retrieval function
const std::string& SWIG_FORTRAN_ERROR_STR();

// Call this function before any new action
SWIGEXPORT void SWIG_check_unhandled_exception_impl(const char* decl)
{
    if (SWIG_FORTRAN_ERROR_INT != 0)
    {
        // Construct message; calling the error string function ensures that
        // the string is allocated if the user did something goofy like
        // manually setting the integer. Since this function is not expected to
        // be wrapped by a catch statement, it will probably terminate the
        // program.
        std::string msg("An unhandled exception occurred before a call to ");
        msg += decl;
        msg += "; ";
        std::string prev_msg = SWIG_FORTRAN_ERROR_STR();
        prev_msg.front() = std::tolower(prev_msg.front());
        msg += prev_msg;
        throw std::runtime_error(msg);
    }
}

// Save an exception to the fortran error code and string
SWIGEXPORT void SWIG_store_exception(const char *decl,
                                     int errcode,
                                     const char *msg)
{
    ::SWIG_FORTRAN_ERROR_INT = errcode;

    if (!swig_last_exception_msg)
    {
        swig_last_exception_msg = new std::string;
    }
    // Save the message to a std::string first
    *swig_last_exception_msg = "In ";
    *swig_last_exception_msg += decl;
    *swig_last_exception_msg += ": ";
    *swig_last_exception_msg += msg;
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
#define SWIG_exception_impl(DECL, CODE, MSG, RETURNNULL) \
    SWIG_store_exception(DECL, CODE, MSG); RETURNNULL;
%}

// Note that this replaces wrapper code: the phrase "SWIG_exception" never
// shows up in the .cxx file
#define SWIG_exception(CODE, MSG) \
    SWIG_exception_impl("$decl", CODE, MSG, return $null)

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
%import <std_string.i>

%apply const std::string& NATIVE { const std::string& SWIG_FORTRAN_ERROR_STR};

// Return a wrapped version of the error string
%inline {
const std::string& SWIG_FORTRAN_ERROR_STR()
{
    if (!swig_last_exception_msg || swig_last_exception_msg->empty())
    {
        SWIG_store_exception("UNKNOWN", SWIG_RuntimeError,
                             "no error string was present");

    }
    return *swig_last_exception_msg;
}
}

//---------------------------------------------------------------------------//
// end of fortran/exception.i
//---------------------------------------------------------------------------//
