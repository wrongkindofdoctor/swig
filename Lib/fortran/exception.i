//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/exception.i
 * \author Seth R Johnson
 * \date   Fri Apr 28 18:33:31 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 *
 * This file is automatically included when the user loads <std_except.i>.
 *
 * Example use: \code

%include <std_except.i>

%exception {
    // Make sure no unhandled exceptions exist before performing a new action
    swig::fortran_check_unhandled_exception();
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
#endif

// Insert the fortran integer definition
%insert("fortranspec") {
 public :: SWIG_FORTRAN_ERROR_INT
 integer(C_INT), bind(C) :: SWIG_FORTRAN_ERROR_INT
}

// Declare the integer externally for C/C++ when stdexcept is included
%insert("header") {
#ifdef __cplusplus
extern "C" {
#endif
extern int SWIG_FORTRAN_ERROR_INT;
#ifdef __cplusplus
}
#endif
}

%fragment("<stdexcept>");
%fragment("<algorithm>");
%fragment("<string>");

// Define SWIG integer error codes
%insert("runtime") "../swigerrors.swg"

// Add SWIG wrapping functions for managing exceptions
%insert("header") {
namespace swig
{
// Message thrown by last unhandled exception
std::string fortran_exception_str;

// Call this function before any new action
void fortran_check_unhandled_exception()
{
    if (::SWIG_FORTRAN_ERROR_INT != 0)
        throw std::runtime_error("An unhandled exception occurred: "
                                 + fortran_exception_str);
}

void fortran_store_exception(int code, const char *msg)
{
    ::SWIG_FORTRAN_ERROR_INT = code;
    fortran_exception_str = msg;
}
} // end namespace swig
}

#define SWIG_exception(code, msg)\
{ swig::fortran_store_exception(code, msg); return $null; }

//---------------------------------------------------------------------------//
// FORTRAN ERROR ACCESSORS
//---------------------------------------------------------------------------//

%inline {

void get_error_string(char* STRING, int SIZE)
{
    int minsize = std::min<int>(SIZE, swig::fortran_exception_str.size());

    char* dst = STRING;
    dst = std::copy(swig::fortran_exception_str.begin(),
                    swig::fortran_exception_str.begin() + minsize,
                    dst);
    std::fill(dst, STRING + SIZE, ' ');
}

}

//---------------------------------------------------------------------------//
// end of fortran/exception.i
//---------------------------------------------------------------------------//
