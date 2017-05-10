//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fortrantypemaps.swg
 * \author Seth R Johnson
 * \date   Sat Dec 03 09:10:31 2016
 * \brief  Fortran typemap code
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

//---------------------------------------------------------------------------//
/*! CUSTOM TYPEMAP DESCRIPTIONS.
 *
 * ctype      : type in C wrapper code (input parameter, default return value)
 * ctype:out  : *return* type (overrides ctype)
 * imtype     : Fortran type in interface code (equivalent to C argument type)
 * imtype:out : Fortran return type in interface code (overrides imtype)
 * ftype      : Fortran proxy (shadow) code type
 * fin        : Fortran proxy code used to translate a Fortan argument to a
 *              wrapper argument
 * fin:pre    : Proxy code inserted before the wrapper call
 * fin:post   : Proxy code inserted after the wrapper call
 * fdata      : Proxy code for member data inserted into fortran code
 */

/*! SPECIAL TYPEMAP VARIABLES.
 *
 * $imcall    : in the proxy class, the function call into the interface wrapper
 * $fclassname: the fortran proxy class name
 */

 /*! PSEUDO CODE USING TYPEMAPS
  *
  * C WRAPPER PSEUDOCODE
  * --------------------
  * /ctype:out/ swigc_hello(/ctype/ farg) {
  *   /ctype:out/ fresult;
  *   /in/        arg;
  *   /out/       result;
  *   arg = farg;
  *   result = hello(arg);
  *   fresult = result;
  * }
  *
  * FORTRAN BINDINGS PSEUDOCODE
  * ---------------------------
  * interface
  *  function swigc_hello(farg) &
  *      bind(C, name="swigc_function") &
  *      result(fresult)
  *    use, intrinsic ::ISO_C_BINDING
  *    /imtype:out/   :: fresult
  *    /imtype/       :: farg
  *  end function
  * end interface
  *
  * FORTRAN PROXY PSEUDOCODE
  * ------------------------
  * contains
  *   function hello(x) &
  *      result(fresult)
  *    use, intrinsic :: ISO_C_BINDING
  *    /ftype:out ($proxy_name) / :: fresult
  *    /ftype/                    :: arg
  *    /fin:pre/
  *    /fout (result)/ = $imcall  ! swigc_hello
  *    /fin:post/
  *   end function
  *  /fcreate/
  *  /frelease/
  * end module
  *
  * FORTRAN INTERFACE PSEUDOCODE
  * ----------------------------
  * type :: ClassName
  *  /fdata/
  * contains
  * end type
  */

//---------------------------------------------------------------------------//
// FUNDAMENTAL TYPES
//---------------------------------------------------------------------------//
/*!
 * \def FORT_BUILTIN_TYPEMAP
 * \brief Add a typemap for a fundamental built-in type.
 *
 * Return types are passed by value. Argument types in Fortran must be pointers
 * (so \c ctype is a pointer, and we use a \c typemap(in) to dereference the
 * argument).
 *
 * - We can't return mutable references to fundamental types; you'll get a
 *   build-time error in your wrapper code if you try. Const references will
 *   get converted into values for fundamental types.
 * - Returning by const reference is automatically turned into return-by-value.
 *   (this is the 'out=CTYPE' argument)
 */
%define FORT_BUILTIN_TYPEMAP(CTYPE, FTYPE, TYPECHECK)
  // Mutable references and pointers are returned as actual pointers
  %typemap(ctype, out="CTYPE*") CTYPE*, CTYPE&, CTYPE[], CTYPE[ANY]
    %{CTYPE*%}
  // Const references and pointers are returned by value
  %typemap(ctype, out="CTYPE") CTYPE, const CTYPE*, const CTYPE&
    %{CTYPE*%}

  %typemap(in) CTYPE
    %{$1 = *$input;%}
  %typemap(in) CTYPE*, CTYPE&, CTYPE[], CTYPE[ANY]
    %{$1 = $input;%}

  // Return original type or pointer
  %typemap(out) CTYPE, CTYPE*, CTYPE&, CTYPE[], CTYPE[ANY]
    %{$result = $1;%}
  // Convert pointer to value
  %typemap(out) const CTYPE&, const CTYPE*
    %{$result = *$1;%}

  // Note: FTYPE is a string, it gets preprocessor-concatenated to the
  // dimension/intent string
  %typemap(imtype, out="type(C_PTR)") CTYPE*, CTYPE[], CTYPE[ANY]
    FTYPE ", dimension(*), intent(inout)"
  %typemap(imtype) const CTYPE*, const CTYPE[], const CTYPE[ANY]
    FTYPE ", dimension(*), intent(in)"
  %typemap(imtype, out=FTYPE) CTYPE&
    FTYPE ", intent(inout)"
  %typemap(imtype, out=FTYPE) CTYPE, const CTYPE&
    FTYPE ", intent(in)"
  %typemap(imtype, out="type(C_PTR)") CTYPE&
    FTYPE ", intent(in)"

  %typemap(ftype, out=FTYPE ", pointer") CTYPE*, CTYPE[], CTYPE[ANY]
    FTYPE ", dimension(:), intent(inout)"
  %typemap(ftype, out="type(C_PTR)")  const CTYPE*, const CTYPE[], CTYPE[ANY]
    FTYPE ", dimension(:), intent(in)"
  %typemap(ftype, out=FTYPE ", pointer" )  CTYPE&
    FTYPE ", intent(inout)"
  %typemap(ftype, out=FTYPE) CTYPE, const CTYPE&
    FTYPE ", intent(in)"

  %typemap(fin)  CTYPE, CTYPE[], CTYPE[ANY], CTYPE*, CTYPE&, const CTYPE*, const CTYPE&
    %{$1_name%}
  %typemap(fout) CTYPE, CTYPE[], CTYPE[ANY], const CTYPE*, const CTYPE&
    %{$result = $imcall%}
  %typemap(fout) CTYPE*
    %{call c_f_pointer($imcall, $result)%}
  %typemap(fout) CTYPE&
    %{call c_f_pointer($imcall, $result)%}

  // Issue warning for overloaded C++ functions
  %typecheck(TYPECHECK) CTYPE, const CTYPE& ""
%enddef

FORT_BUILTIN_TYPEMAP(bool       , "logical(C_BOOL)"     , SWIG_TYPECHECK_BOOL)
FORT_BUILTIN_TYPEMAP(short      , "integer(C_SHORT)"    , SWIG_TYPECHECK_INTEGER)
FORT_BUILTIN_TYPEMAP(int        , "integer(C_INT)"      , SWIG_TYPECHECK_INTEGER)
FORT_BUILTIN_TYPEMAP(long       , "integer(C_LONG)"     , SWIG_TYPECHECK_INTEGER)
FORT_BUILTIN_TYPEMAP(long long  , "integer(C_LONG_LONG)", SWIG_TYPECHECK_INTEGER)
FORT_BUILTIN_TYPEMAP(size_t     , "integer(C_SIZE_T)"   , SWIG_TYPECHECK_INTEGER)
FORT_BUILTIN_TYPEMAP(float      , "real(C_FLOAT)"       , SWIG_TYPECHECK_FLOAT)
FORT_BUILTIN_TYPEMAP(double     , "real(C_DOUBLE)"      , SWIG_TYPECHECK_DOUBLE)

// Apply unsigned equivalent types
%define FORTRAN_EQUIV(CTYPE, CTYPE2)
 %apply       CTYPE  {       CTYPE2  };
 %apply       CTYPE* {       CTYPE2* };
 %apply       CTYPE& {       CTYPE2& };
 %apply const CTYPE* { const CTYPE2* };
 %apply const CTYPE& { const CTYPE2& };
 %typecheck(SWIG_TYPECHECK_INTEGER) CTYPE, CTYPE2 ""
%enddef

FORTRAN_EQUIV(short , unsigned short );
FORTRAN_EQUIV(int   , unsigned int   );
FORTRAN_EQUIV(long  , unsigned long  );
FORTRAN_EQUIV(size_t, unsigned long long);
FORTRAN_EQUIV(size_t, std::size_t);

%typecheck(SWIG_TYPECHECK_POINTER)
    SWIGTYPE, 
    SWIGTYPE *, 
    SWIGTYPE &, 
    SWIGTYPE &&, 
    SWIGTYPE *const&, 
    SWIGTYPE [],
    SWIGTYPE (CLASS::*)
    ""

//---------------------------------------------------------------------------//
// VOID TYPES
//---------------------------------------------------------------------------//

%typemap(ctype)  void %{void%}
%typemap(out)    void %{%}
%typemap(imtype) void ""
%typemap(ftype)  void ""
%typemap(fout)   void %{call $imcall%}

//---------------------------------------------------------------------------//
// VOID POINTER TYPES
//---------------------------------------------------------------------------//
  
// Mutable references and pointers are returned as actual pointers
%typemap(ctype, out="void*") void*
  %{void*%}
%typemap(in) void
  %{$1 = *$input;%}
%typemap(out) void*
  %{ $result = $1; %}
%typemap(imtype) void*
  "type(C_PTR)"
%typemap(ftype) void*
  "type(C_PTR)"
%typemap(fin)  void*
  %{$1_name%}
%typemap(fout) void*
  %{$result = $imcall%}

//---------------------------------------------------------------------------//
// PROXY CLASS DEFINITIONS
//---------------------------------------------------------------------------//

%typemap(fdata) SWIGTYPE %{
  type(C_PTR), public :: ptr = C_NULL_PTR
  logical, private :: own = .false.
%}

%typemap(fcreate) SWIGTYPE
%{
   if (c_associated(self%ptr)) call self%release()
   self%ptr = $imcall
   self%own = .true.
%}

%typemap(frelease) SWIGTYPE %{
   if (self%own) then
    call $imcall
    self%own = .false.
   end if
   self%ptr = C_NULL_PTR
%}

//---------------------------------------------------------------------------//
// CLASSES BY VALUE
//---------------------------------------------------------------------------//

#ifdef __cplusplus
%fragment ("utility_header", "header") %{
#if __cplusplus >= 201103L
#include <utility>
#endif
%}
#else
%fragment ("utility_header", "header") %{%}
#endif

%typemap(ctype)  SWIGTYPE %{void*%}
%typemap(in)     SWIGTYPE %{$1 = *($&1_ltype)($input);%}
%typemap(out, fragment="utility_header")    SWIGTYPE
#ifdef __cplusplus
%{
#if __cplusplus >= 201103L
    $result = new $1_ltype(std::move($1));
#else
    $result = new $1_ltype($1);
#endif
%}
#else
{
  $&1_ltype $1ptr = ($&1_ltype) malloc(sizeof($1_ltype));
  memmove($1ptr, &$1, sizeof($1_type));
  $result = $1ptr;
}
#endif

%typemap(imtype, out="type(C_PTR)") SWIGTYPE "type(C_PTR), value"
%typemap(ftype)  SWIGTYPE "type($fclassname)"
%typemap(fin)    SWIGTYPE "$1_name%ptr"
%typemap(fout)   SWIGTYPE %{
   $result%ptr = $imcall
   $result%own = .true.
%}

//---------------------------------------------------------------------------//
// CLASSES BY REFERENCE/POINTER
//---------------------------------------------------------------------------//

%typemap(ctype)  SWIGTYPE*, SWIGTYPE& %{void*%}
%typemap(in)     SWIGTYPE*, SWIGTYPE& %{ $1 = ($1_ltype)($input); %}
%typemap(out)    SWIGTYPE*, SWIGTYPE& %{ $result = $1; %}
%typemap(imtype, out="type(C_PTR)") SWIGTYPE*, SWIGTYPE& "type(C_PTR), value"
%typemap(ftype, out="type($fclassname)") SWIGTYPE*, SWIGTYPE&
    "class($fclassname)"
%typemap(fin)    SWIGTYPE*, SWIGTYPE& "$1_name%ptr"
%typemap(fout)   SWIGTYPE*, SWIGTYPE& %{
   $result%ptr = $imcall
   $result%own = $owner
%}

//---------------------------------------------------------------------------//
// CHARACTER TYPES
//---------------------------------------------------------------------------//
// Single characters: differentiate from char pointers by using value semantics

%define FORT_CHAR_TYPEMAP(CTYPE, FTYPE)
    %typemap(ctype) CTYPE, const CTYPE&
      %{CTYPE%}
    %typemap(in)    CTYPE
      %{$1 = $input;%}
    %typemap(in)    const CTYPE&
      %{$1 = &$input;%}
    %typemap(out)   CTYPE
      %{$result = $1;%}
    %typemap(out)   CTYPE&
      %{$result = $1;%}
    %typemap(out)   const CTYPE&
      %{$result = *$1;%}
    %typemap(imtype, out="character(" FTYPE ")") CTYPE, CTYPE&
      "character(" FTYPE "), value"
    %typemap(ftype,  out="character(" FTYPE ")") CTYPE, CTYPE&, const CTYPE&
      "character(" FTYPE "), value"
    %typemap(fin) CTYPE, CTYPE&, const CTYPE&
      "$1_name"
    %typemap(fout) CTYPE, CTYPE&, const CTYPE&
      %{$result = $imcall%}
    %typemap(ftype, out="character(" FTYPE "), pointer" )  CTYPE&
      "character(" FTYPE "), intent(inout)"
    %typemap(fout) CTYPE&
      %{call c_f_pointer($imcall, $result)%}
%enddef

FORT_CHAR_TYPEMAP(char, "C_CHAR")
FORT_CHAR_TYPEMAP(unsigned char, "C_CHAR")

#undef FORT_CHAR_TYPEMAP
    
//---------------------------------------------------------------------------//
// STRING TYPES
//
// Note that currently strings can be passed as character arrays, but returning
// a C string gives just an opaque C pointer
//---------------------------------------------------------------------------//

%define FORT_STR_TYPEMAP(CTYPE, FTYPE)
    %typemap(ctype)  CTYPE*, CTYPE[], CTYPE[ANY] %{CTYPE*%}
    %typemap(in)     CTYPE*, CTYPE[], CTYPE[ANY] %{$1 = ($1_ltype)$input;%}
    %typemap(out)    CTYPE*, CTYPE[], CTYPE[ANY] %{$result = $1;%}
    %typemap(imtype, out="type(C_PTR)")
        CTYPE*, CTYPE[], CTYPE[ANY] "character(" FTYPE ")"
    %typemap(ftype, out="type(C_PTR)")
        CTYPE*, CTYPE[], CTYPE[ANY] "character(kind=" FTYPE ", len=*)"
    %typemap(fin)    CTYPE*, CTYPE[], CTYPE[ANY] "$1_name"
    %typemap(fout)   CTYPE*, CTYPE[], CTYPE[ANY] "$result = $imcall"

    %typecheck(SWIG_TYPECHECK_POINTER) CTYPE*, CTYPE[], CTYPE[ANY]  ""
%enddef

FORT_STR_TYPEMAP(const char, "C_CHAR")
FORT_STR_TYPEMAP(char, "C_CHAR")
FORT_STR_TYPEMAP(unsigned char, "C_CHAR")
FORT_STR_TYPEMAP(const unsigned char, "C_CHAR")

#undef FORT_STR_TYPEMAP

//---------------------------------------------------------------------------//
// ENUMS
//---------------------------------------------------------------------------//

%typemap(ctype, out="int")  enum SWIGTYPE
    %{int*%}
%typemap(in)     enum SWIGTYPE
    %{$1 = ($1_ltype)(*$input);%}
%typemap(out)    enum SWIGTYPE, const enum SWIGTYPE* 
    %{$result = $1;%}

// Return-by-const-ref becomes return-by-value
#define CTYPE enum SWIGTYPE
#define FTYPE "integer(C_INT)"
  %typemap(out, out="CTYPE") CTYPE, const CTYPE*
    %{$result = $1;%}
  %typemap(out) const CTYPE&
    %{$result = *$1;%}
  %typemap(out) CTYPE&
    %{
    #error "Can't return primitive types by mutable reference in Fortran"
    %}
  %typemap(imtype, out=FTYPE) CTYPE&
    FTYPE ", intent(inout)"
  %typemap(imtype, out=FTYPE) CTYPE, const CTYPE&
    FTYPE ", intent(in)"
  %typecheck(SWIG_TYPECHECK_INTEGER) CTYPE, const CTYPE& ""
#undef CTYPE
#undef FTYPE

%typemap(ftype)  enum SWIGTYPE "integer(kind($fclassname))"
%typemap(fin)    enum SWIGTYPE "$1_name"
%typemap(fout)   enum SWIGTYPE %{ $result = $imcall %}

//---------------------------------------------------------------------------//
// FUNCTION POINTERS
//---------------------------------------------------------------------------//

%typemap(ctype)  SWIGTYPE (*)(ANY) %{ $1_ltype %}
%typemap(in)     SWIGTYPE (*)(ANY) %{ $1 = $input; %}
%typemap(out)    SWIGTYPE (*)(ANY) %{ $result = $1; %}
%typemap(imtype) SWIGTYPE (*)(ANY) "type(C_FUNPTR), intent(in), value"
%typemap(ftype)  SWIGTYPE (*)(ANY) "type(C_FUNPTR), intent(in), value"
%typemap(fin)    SWIGTYPE (*)(ANY) "$1_name"
%typemap(fout)   SWIGTYPE (*)(ANY) %{
   $result = $imcall
%}

// Member function pointers are not available
%apply SWIGTYPE (*)(ANY) { SWIGTYPE (CLASS::*) } ;
%typemap(in) SWIGTYPE (CLASS::*) %{
#error "Member function pointers are not available in Fortran"
%}
%typemap(out) SWIGTYPE (CLASS::*) %{
#error "Member function pointers are not available in Fortran"
%}

//---------------------------------------------------------------------------//
// end of fortran/fortrantypemaps.swg
//---------------------------------------------------------------------------//
