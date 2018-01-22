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
    swigf_check_unhandled_exception();
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
// DEPRECATED fragments
//---------------------------------------------------------------------------//
%fragment("SwigfExceptionDeprecated", "header") {
// DEPRECATED: use swigf_check_unhandled_exception instead
namespace swig
{
%#ifdef __GNUC__
__attribute__((deprecated))
%#endif
inline void fortran_check_unhandled_exception()
{
    swigf_check_unhandled_exception();
}
} // end namespace swig
}

//---------------------------------------------------------------------------//
// Fortran variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
#ifndef SWIGIMPORTED
// Fortran error variables
%fragment("SwigfErrorParams", "fparams") {
 integer(C_INT), bind(C) :: SWIG_FORTRAN_ERROR_INT
}

// Declare those variables public
%fragment("SwigfErrorPub", "fpublic") {
 public :: SWIG_FORTRAN_ERROR_INT
}
#endif

//---------------------------------------------------------------------------//
// Function declaration: whether imported or not
//---------------------------------------------------------------------------//

%fragment("SwigfExceptionDeclaration", "runtime") {
void swigf_check_unhandled_exception();
void swigf_store_exception(int code, const char *msg);
}

//---------------------------------------------------------------------------//
// C++ Variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
#ifdef __cplusplus
// Insert C++ definition of fortran data
%fragment("SwigfErrorVars_wrap", "header",
          fragment="SwigfErrorPub", fragment="SwigfErrorParams") {
extern "C" {
int SWIG_FORTRAN_ERROR_INT = 0;
}
}

// Exception handling code
%fragment("SwigfExceptionDefinition", "header",
          fragment="SwigfErrorVars_wrap", fragment="<string>",
          fragment="<algorithm>", fragment="<stdexcept>")
{
// Stored exception message
std::string swigf_last_exception_msg;

// Call this function before any new action
void swigf_check_unhandled_exception()
{
    if (::SWIG_FORTRAN_ERROR_INT != 0)
    {
        throw std::runtime_error(
                "An unhandled exception occurred in $decl: "
                + swigf_last_exception_msg);
    }
}

// Save an exception to the fortran error code and string
void swigf_store_exception(int code, const char *msg)
{
    ::SWIG_FORTRAN_ERROR_INT = code;

    // Save the message to a std::string first
    swigf_last_exception_msg = msg;
}

}
//---------------------------------------------------------------------------//
// C variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
#else
// Insert C declaration of fortran data
%fragment("SwigfErrorVars_wrap_c", "header",
          fragment="SwigfErrorPub", fragment="SwigfErrorParams") {
extern int SWIG_FORTRAN_ERROR_INT;
}

// Exception handling code
%fragment("SwigfExceptionDefinition", "header",
          fragment="SwigfErrorVars_wrap_c")
{
// Call this function before any new action
void swigf_check_unhandled_exception()
{
    assert(SWIG_FORTRAN_ERROR_INT == 0);
}

// Save an exception to the fortran error code and string
void swigf_store_exception(int code, const char * msg)
{
    // Store exception code
    SWIG_FORTRAN_ERROR_INT = code;
    // Print the message immediately
    printf(stderr, "An error of type %d occurred: %s\n", code, msg, NULL);
}
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
#define SWIG_exception_impl(CODE, MSG, RETURNNULL) \
    swigf_store_exception(CODE, MSG); RETURNNULL;
%}
#else
%fragment("SwigfExceptionMacro", "runtime") %{
#undef SWIG_exception_impl
#define SWIG_exception_impl(CODE, MSG, RETURNNULL) \
    swigf_store_exception(CODE, MSG); RETURNNULL;
%}
#endif

// Note that this replaces wrapper code: the phrase "SWIG_exception" never
// shows up in the .cxx file
#define SWIG_exception(CODE, MSG) \
    SWIG_exception_impl(CODE, MSG, return $null)

//---------------------------------------------------------------------------//
// Insert exception code (will insert different code depending on if C/C++ and
// whether or not this module is being %imported)
%fragment("SwigfExceptionMacro");
%fragment("SwigfExceptionDeclaration");
#ifndef SWIGIMPORTED
%fragment("SwigfExceptionDefinition");
#endif
#ifdef __cplusplus
%fragment("SwigfExceptionDeprecated");
#endif

//---------------------------------------------------------------------------//
// Functional interface to swig error string
//
// Note: this is taken from some test code I wrote for std::string. Since it
// only works with returning references, I'm only using it for exception
// handling in the meantime.
//---------------------------------------------------------------------------//

#ifdef __cplusplus
// Declare typedef for special string conversion typemaps
%inline %{
typedef const std::string& Swig_Err_String;
%}

#define STRING_TYPES Swig_Err_String
#define AW_TYPE SwigfArrayWrapper

// C wrapper type: pointer to templated array wrapper
%typemap(ctype, noblock=1, out="SwigfArrayWrapper",
       fragment="SwigfArrayWrapper_wrap") STRING_TYPES
{AW_TYPE*}

// C output initialization
%typemap(arginit) AW_TYPE
%{$1.data = NULL;
  $1.size = 0;%}

// C output translation typemaps: $1 is string*, $input is AW_TYPE
%typemap(out) const std::string&
%{$result.data = ($1->empty() ? NULL : &(*$1->begin()));
  $result.size = $1->size();
  %}

%typemap(imtype, import="SwigfArrayWrapper") STRING_TYPES
 "type(SwigfArrayWrapper)"

// Fortran proxy code: return allocatable string
%typemap(ftype, out="character(kind=C_CHAR, len=:), allocatable") STRING_TYPES
"character(kind=C_CHAR, len=*), target"

// Fortran proxy translation code: convert from char array to Fortran string
%typemap(fout, fragment="SwigfCharArrayToString") STRING_TYPES
%{
  call swigf_chararray_to_string($1, $result)
%}

#undef STRING_TYPES
#undef AW_TYPE

// Get a pointer to the error string
%inline {
Swig_Err_String SWIG_FORTRAN_ERROR_STR()
{
    return swigf_last_exception_msg;
}
}
#endif

//---------------------------------------------------------------------------//
// end of fortran/exception.i
//---------------------------------------------------------------------------//
