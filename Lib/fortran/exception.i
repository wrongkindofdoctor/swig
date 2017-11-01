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
#define SWIG_FORTRAN_ERROR_STR serr
#define SWIG_FORTRAN_ERROR_STRLEN 1024
#endif

//---------------------------------------------------------------------------//
// Fortran variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
#ifndef SWIGIMPORTED
// Fortran error variables
%fragment("SwigfErrorParams", "fparams") {
 integer(C_INT), bind(C) :: SWIG_FORTRAN_ERROR_INT = 0
 character(kind=C_CHAR, len=SWIG_FORTRAN_ERROR_STRLEN), bind(C) :: SWIG_FORTRAN_ERROR_STR = ""
}

// Declare those variables public
%fragment("SwigfErrorPub", "fpublic") {
 public :: SWIG_FORTRAN_ERROR_INT
 public :: SWIG_FORTRAN_ERROR_STR
}
#endif

//---------------------------------------------------------------------------//
// C++ Variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
#if defined(__cplusplus) && !defined(SWIGIMPORTED)
// Insert C++ declaration of fortran data
%fragment("SwigfErrorVars_wrap", "header",
          fragment="SwigfErrorPub", fragment="SwigfErrorParams") {
extern "C" {
extern int SWIG_FORTRAN_ERROR_INT;
extern char SWIG_FORTRAN_ERROR_STR[SWIG_FORTRAN_ERROR_STRLEN];
}
}
// Exception handling code
%fragment("SwigfExceptionDefinition", "header",
          fragment="SwigfErrorVars_wrap", fragment="<string>",
          fragment="<algorithm>", fragment="<stdexcept>")
{
namespace swig
{
// Stored exception message
std::string fortran_last_exception_msg;

// Call this function before any new action
void fortran_check_unhandled_exception()
{
    if (::SWIG_FORTRAN_ERROR_INT != 0)
    {
        throw std::runtime_error(
                "An unhandled exception occurred in $symname: "
                + fortran_last_exception_msg);
    }
}

// Save an exception to the fortran error code and string
void fortran_store_exception(int code, const char *msg)
{
    ::SWIG_FORTRAN_ERROR_INT = code;

    // Save the message to a std::string first
    fortran_last_exception_msg = msg;

    std::size_t msg_size = std::min<std::size_t>(
            fortran_last_exception_msg.size(),
            SWIG_FORTRAN_ERROR_STRLEN);

    // Copy to space-padded Fortran string
    char* dst = SWIG_FORTRAN_ERROR_STR;
    dst = std::copy(fortran_last_exception_msg.begin(),
                    fortran_last_exception_msg.begin() + msg_size,
                    dst);
    std::fill(dst, SWIG_FORTRAN_ERROR_STR + SWIG_FORTRAN_ERROR_STRLEN, ' ');
}
} // end namespace swig
}
#endif

//---------------------------------------------------------------------------//
// C variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
#if !defined(__cplusplus) && !defined(SWIGIMPORTED)
// Insert C declaration of fortran data
%fragment("SwigfErrorVars_wrap_c", "header",
          fragment="SwigfErrorPub", fragment="SwigfErrorParams") {
extern int SWIG_FORTRAN_ERROR_INT;
extern char SWIG_FORTRAN_ERROR_STR[SWIG_FORTRAN_ERROR_STRLEN];
}
// Exception handling code
%fragment("SwigfExceptionDefinition", "header",
          fragment="SwigfErrorVars_wrap_c")
{
// Call this function before any new action
void fortran_check_unhandled_exception()
{
    assert(SWIG_FORTRAN_ERROR_INT == 0);
}

// Save an exception to the fortran error code and string
void fortran_store_exception(int code, const char *src)
{
    const char* dst = SWIG_FORTRAN_ERROR_STR;
    const char* end = SWIG_FORTRAN_ERROR_STR + SWIG_FORTRAN_ERROR_STRLEN;

    // Store exception code
    SWIG_FORTRAN_ERROR_INT = code;

    // Copy up to null terminator
    while (dst != end && *src != 0)
    {
        *dst++ = *src++;
    }
    // Space-pad the remainder
    while (dst != end)
    {
        *dst++ = ' ';
    }
}
}
#endif

//---------------------------------------------------------------------------//
// C++ Variable declarations: used only if %imported
//---------------------------------------------------------------------------//
#if defined(__cplusplus) && defined(SWIGIMPORTED)
%fragment("SwigfExceptionDefinition", "header") {
namespace swig
{
// Functions are defined in an imported module
void fortran_check_unhandled_exception();
void fortran_store_exception(int code, const char *msg);
} // end namespace swig
}
#endif

//---------------------------------------------------------------------------//
// C Variable declarations: used only if %imported
//---------------------------------------------------------------------------//
#if !defined(__cplusplus) && defined(SWIGIMPORTED)
%fragment("SwigfExceptionDefinition", "header") {
// Functions are defined in an imported module
void fortran_check_unhandled_exception();
void fortran_store_exception(int code, const char *msg);
}
#endif

//---------------------------------------------------------------------------//
// Runtime code (always added)
//---------------------------------------------------------------------------//
#if defined(__cplusplus)
// Override the default exception handler from fortranruntime.swg
// Note that SWIG_exception_impl is used by SWIG_contract_assert, so the
// *_impl* is the one that changes.
%fragment("SwigfExceptionMacro", "runtime") %{
#undef SWIG_exception_impl
#define SWIG_exception_impl(CODE, MSG, NULLRETURN) \
    swig::fortran_store_exception(CODE, MSG); return NULLRETURN;
%}
#else
%fragment("SwigfExceptionMacro", "runtime") %{
#undef SWIG_exception_impl
#define SWIG_exception_impl(CODE, MSG, NULLRETURN) \
    fortran_store_exception(CODE, MSG); return NULLRETURN;
%}
#endif

// Note that this replaces wrapper code: the phrase "SWIG_exception" never
// shows up in the .cxx file
#define SWIG_exception(CODE, MSG) \
    SWIG_exception_impl(CODE, MSG, $null)

//---------------------------------------------------------------------------//
// Insert exception code (will insert different code depending on if C/C++ and
// whether or not this module is being %imported)
%fragment("SwigfExceptionMacro");
%fragment("SwigfExceptionDefinition");

//---------------------------------------------------------------------------//
// end of fortran/exception.i
//---------------------------------------------------------------------------//
