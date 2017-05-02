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

#define SWIG_exception(code, msg)\
{ swig::fortran_store_exception(code, msg); return $null; }

// Insert the fortran integer definition (only if %included)
%insert("fortranspec") {
 public :: SWIG_FORTRAN_ERROR_INT
 integer(C_INT), bind(C) :: SWIG_FORTRAN_ERROR_INT = 0
}

// Define SWIG integer error codes

#ifndef SWIGIMPORTED
%fragment("fortran_exception_impl", "header",
          fragment="<algorithm>", fragment="<string>", fragment="<stdexcept>")
{
// External fortran-owned data that we save to
#ifdef __cplusplus
extern "C" {
#endif
extern int SWIG_FORTRAN_ERROR_INT;
#ifdef __cplusplus
};
#endif

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
};
#else
%fragment("fortran_exception_impl", "header") {
namespace swig
{
// Functions are defined in an imported module
void fortran_check_unhandled_exception();
void fortran_store_exception(int code, const char *msg);
} // end namespace swig
};
#endif

//---------------------------------------------------------------------------//

#ifndef SWIGIMPORTED
%fragment("fortran_exception_impl");
%fragment("<algorithm>");

%inline %{

void get_error_string(char* STRING, int SIZE)
{
    int minsize = std::min<int>(SIZE, swig::fortran_exception_str.size());

    char* dst = STRING;
    dst = std::copy(swig::fortran_exception_str.begin(),
                    swig::fortran_exception_str.begin() + minsize,
                    dst);
    std::fill(dst, STRING + SIZE, ' ');
}

%}
#else
%fragment("fortran_exception", "header",
          fragment="fortran_exception_impl") {};
#endif

// Insert exception code
%fragment("fortran_exception");

//---------------------------------------------------------------------------//
// end of fortran/exception.i
//---------------------------------------------------------------------------//
