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
#define SWIG_FORTRAN_ERROR_STR get_serr
#endif

//---------------------------------------------------------------------------//
// Fortran variable definitions: used only if %included, not %imported
//---------------------------------------------------------------------------//
#ifndef SWIGIMPORTED
// Fortran error variables
%fragment("SwigfErrorParams", "fparams") {
 integer(C_INT), bind(C) :: SWIG_FORTRAN_ERROR_INT = 0
}

// Declare those variables public
%fragment("SwigfErrorPub", "fpublic") {
 public :: SWIG_FORTRAN_ERROR_INT
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
void fortran_store_exception(int code, const char *)
{
    // Store exception code
    SWIG_FORTRAN_ERROR_INT = code;
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
// Functional interface to swig error string
//
// Note: this is taken from some test code I wrote for std::string. Since it
// only works with returning references, I'm only using it for exception
// handling in the meantime.
//---------------------------------------------------------------------------//

#if defined(__cplusplus)
// Declare typedef for special string conversion typemaps
%inline %{
typedef const std::string& Swig_Err_String;
%}

#define STRING_TYPES Swig_Err_String
#define AW_TYPE swig::SwigfArrayWrapper< const char >

// C wrapper type: pointer to templated array wrapper
%typemap(ctype, noblock=1, out="swig::SwigfArrayWrapper< const char >",
       fragment="SwigfArrayWrapper") STRING_TYPES
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

%typemap(imimport, fragment="SwigfArrayWrapper") STRING_TYPES
"SwigfArrayWrapper"
%typemap(imtype, in="type(SwigfArrayWrapper)") STRING_TYPES
 "type(SwigfArrayWrapper)"

// Fortran proxy code: return allocatable string
%typemap(ftype, out="character(kind=C_CHAR, len=:), allocatable") STRING_TYPES
"character(kind=C_CHAR, len=*), target"

// Fortran proxy translation code: temporary variables for output
%typemap(foutdecl) STRING_TYPES
%{
 integer(kind=C_SIZE_T) :: $1_i
 character(kind=C_CHAR), dimension(:), pointer :: $1_chars
%}

// Fortran proxy translation code: convert from imtype $1 to ftype $result
%typemap(fout) STRING_TYPES
%{
  call c_f_pointer($1%data, $1_chars, [$1%size])
  allocate(character(kind=C_CHAR, len=$1%size) :: $result)
  do $1_i=1,$1%size
    $result($1_i:$1_i) = $1_chars($1_i)
  enddo
%}

#undef STRING_TYPES
#undef AW_TYPE

// Get a pointer to the error string
%inline {
Swig_Err_String SWIG_FORTRAN_ERROR_STR()
{
    return swig::fortran_last_exception_msg;
}
}
#endif

//---------------------------------------------------------------------------//
// end of fortran/exception.i
//---------------------------------------------------------------------------//
