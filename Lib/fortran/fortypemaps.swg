//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fortrantypemaps.swg
 * \author Seth R Johnson
 * \date   Sat Dec 03 09:10:31 2016
 * \brief  Fortran typemap code
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include <typemaps/swigmacros.swg>

//---------------------------------------------------------------------------//
/*! CUSTOM TYPEMAP DESCRIPTIONS.
 *
 * ctype      : type in C wrapper code (input parameter, default return value)
 * ctype:out  : *return* type (overrides ctype)
 * imtype     : Fortran type to pass to "BIND" interface (must be Fortran
 *              equivalent of ctype)
 * imtype:bind : Fortran type to pass to "BIND" interface (must be Fortran
 *              equivalent of ctype)
 * imtype:out : Fortran return type for "BIND" interface (overrides imtype;
 *              must be Fortran equivalent of ctype:out)
 * ftype      : Fortran proxy (shadow) type
 * fin        : Fortran proxy code used to translate a Fortan argument to a
 *              wrapper argument
 * fin:pre    : Proxy code inserted before the wrapper call
 * fin:post   : Proxy code inserted after the wrapper call
 * fdata      : Proxy code for member data inserted into fortran code
 */

/*! SPECIAL TYPEMAP VARIABLES.
 *
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
  *    /imtype/   :: fresult
  *    /imtype:in/       :: farg
  *  end function
  * end interface
  *
  * FORTRAN PROXY PSEUDOCODE
  * ------------------------
  * contains
  *   function hello(arg...) &
  *      result(fresult)
  *    use, intrinsic :: ISO_C_BINDING
  *    /ftype:out / :: $result  ! $fclassname
  *    /imtype/ :: $1
  *    /ftype/ :: $arg
  *    /fin/                    ! imtype$input
  *    $1 = $symname(arg...)
  *    /fout/
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
// TYPEMAP HELPERS
//---------------------------------------------------------------------------//
/*!
 * \def FORT_FUND_VALREF_TYPEMAP
 * \brief Add a typemap for a fundamental built-in type.
 *
 * Arguments in Fortran are typically passed by pointer reference, and return
 * types are typically passed by value.
 *
 * Returning by const reference is automatically turned into return-by-value
 * (this is the 'out=CTYPE' argument).
 *
 * Mutable references that are arguments get the 'inout' qualifier in Fortran,
 * whereas values and const references are simply 'in'.
 *
 * Mutable references that are *return* values are passed as pointers, and on
 * the Fortan side these become 'pointer' types.
 *
 * Note that it's important to use CTYPE instead of $1_ltype in order to keep
 * the pointer types consistent with the given fortran FTYPE.
 */
%define FORT_FUND_VALREF_TYPEMAP(CTYPE, FTYPE)
  // Regular values are passed as pointers and returned by value
  %typemap(in) CTYPE
    "$1 = *$input;"
  %typemap(out) CTYPE
    "$result = $1;"

  // Const references are returned by value
  %typemap(in, noblock=1) const CTYPE&
    {$1 = %const_cast($input, $1_ltype);}
  %typemap(out) const CTYPE&
    "$result = *$1;"

  // All other aspects of const reference vs value are the same
  %typemap(ctype, out="CTYPE") CTYPE, const CTYPE&
    "const CTYPE*"
  %typemap(imtype, in=FTYPE ", intent(in)") CTYPE, const CTYPE&
    FTYPE
  %typemap(ftype, out=FTYPE) CTYPE, const CTYPE&
    FTYPE ", intent(in)"
  %typemap(ftype, out=FTYPE) CTYPE, const CTYPE&
    FTYPE ", intent(in)"
  %typemap(fin)  CTYPE, const CTYPE&
    "$1 = $input"
  %typemap(fout) CTYPE, const CTYPE&
    "$result = $1"

  // Mutable references are passed by pointers as arguments, but they're
  // *returned* as actual pointers (becoming Fortran pointers)
  %typemap(ctype, out="CTYPE*") CTYPE&
    "CTYPE*"
  %typemap(in) CTYPE&
    "$1 = $input;"
  %typemap(out) CTYPE&
    "$result = $1;"
  %typemap(imtype, in="type(C_PTR), value") CTYPE&
    "type(C_PTR)"
  %typemap(ftype, out=FTYPE ", pointer")  CTYPE&
    FTYPE ", target, intent(inout)"
  %typemap(fin)  CTYPE&
    "$1 = c_loc($input)"
  %typemap(fout) CTYPE&
    "call c_f_pointer($1, $result)"
%enddef

//---------------------------------------------------------------------------//
/*!
 * \def FORT_FUND_PTR_TYPEMAP
 * \brief Add array/pointer typemaps for basic fortran types.
 *
 * This adds pointer and array handling to primitive types.
 * Pointers in return values are returned as Fortran array pointers (constness
 * is ignored!) as though they are poniters to scalar values and not arrays.
 * More advanced application-specific typemaps will need to be generated for
 * that case.
 *
 * Otherwise, pointers and arrays are treated as standard fortran arrays.
 */
%define FORT_FUND_PTR_TYPEMAP(CTYPE, FTYPE)
  // Mutable pointers and arrays are returned as actual pointers
  %typemap(ctype, out="$1_ltype") CTYPE*, CTYPE[], CTYPE[ANY]
    %{$1_ltype%}
  %typemap(in) CTYPE*, CTYPE[], CTYPE[ANY]
    %{$1 = $input;%}
  %typemap(out) CTYPE*, CTYPE[], CTYPE[ANY]
    %{$result = $1;%}
  %typemap(imtype, in="type(C_PTR), value") CTYPE*, CTYPE[], CTYPE[ANY]
    "type(C_PTR)"
  %typemap(ftype, out=FTYPE ", pointer") CTYPE*, CTYPE[], CTYPE[ANY]
    FTYPE ", dimension(:), target, intent(inout)"
  %typemap(fin)  CTYPE*, CTYPE[], CTYPE[ANY]
    %{$1 = c_loc($input);%}
  %typemap(fout) CTYPE*, CTYPE[], CTYPE[ANY]
    %{call c_f_pointer($1, $result)%}

  // Overrides for const Fortran intent
  %typemap(in, noblock=1) const CTYPE*, const CTYPE[], const CTYPE[ANY]
    {$1 = %const_cast($input, $1_ltype);}
  %typemap(ftype, out=FTYPE ", pointer") const CTYPE*, const CTYPE[], CTYPE[ANY]
    FTYPE ", dimension(:), target, intent(in)"
%enddef

//---------------------------------------------------------------------------//
/*!
 * \def FORT_OPAQUE_PTR_TYPEMAP
 *
 * Map the given type to an opaque C pointer.
 */
%define FORT_OPAQUE_PTR_TYPEMAP(CTYPE)
  %typemap(ctype) CTYPE
    "$1_ltype"
  %typemap(in, noblock=1) CTYPE
    {$1 = %const_cast($input, $1_ltype);}
  %typemap(out) CTYPE
    "$result = $1;"
  %typemap(imtype, in="type(C_PTR), value") CTYPE
    "type(C_PTR)"
  %typemap(ftype) CTYPE
    "type(C_PTR)"
  %typemap(fin)  CTYPE
    "$1 = $input"
  %typemap(fout)  CTYPE
    "$result = $1"
%enddef

//---------------------------------------------------------------------------//
// TYPEMAP HELPERS
/*!
 * \def FORT_FUND_TYPEMAP
 * \brief Add a typemap for a fundamental built-in type.
 */
%define FORT_FUND_TYPEMAP(CTYPE, FTYPE)
  // Set up pass-by-value and -reference
  FORT_FUND_VALREF_TYPEMAP(CTYPE, FTYPE)
  FORT_FUND_PTR_TYPEMAP(CTYPE, FTYPE)
%enddef

FORT_FUND_TYPEMAP(bool          , "logical(C_BOOL)"     )
FORT_FUND_TYPEMAP(unsigned char , "integer(C_INT8_T)"   )
FORT_FUND_TYPEMAP(short         , "integer(C_SHORT)"    )
FORT_FUND_TYPEMAP(unsigned short, "integer(C_SHORT)"    )
FORT_FUND_TYPEMAP(int           , "integer(C_INT)"      )
FORT_FUND_TYPEMAP(unsigned int  , "integer(C_INT)"      )
FORT_FUND_TYPEMAP(long          , "integer(C_LONG)"     )
FORT_FUND_TYPEMAP(unsigned long , "integer(C_LONG)"     )
FORT_FUND_TYPEMAP(long long     , "integer(C_LONG_LONG)")
FORT_FUND_TYPEMAP(size_t        , "integer(C_SIZE_T)"   )
FORT_FUND_TYPEMAP(float         , "real(C_FLOAT)"       )
FORT_FUND_TYPEMAP(double        , "real(C_DOUBLE)"      )

%typecheck(SWIG_TYPECHECK_BOOL)
    bool,
    const bool &
    ""

%typecheck(SWIG_TYPECHECK_CHAR)
    char,
    const char &
    ""

%typecheck(SWIG_TYPECHECK_INT8)
    unsigned char,
    const unsigned char &
    ""

%typecheck(SWIG_TYPECHECK_INT16)
    short,
    unsigned short,
    const short &,
    const unsigned short &
    ""

%typecheck(SWIG_TYPECHECK_INT32)
    int,
    unsigned int,
    const int &,
    const unsigned int &
    ""

%typecheck(SWIG_TYPECHECK_INT64)
    long,
    long long,
    unsigned long,
    unsigned long long,
    const long &,
    const long long &,
    const unsigned long &,
    const unsigned long long &
    ""

%typecheck(SWIG_TYPECHECK_FLOAT)
    float,
    const float &
    ""

%typecheck(SWIG_TYPECHECK_DOUBLE)
    double,
    const double &
    ""

%typecheck(SWIG_TYPECHECK_STRING)
    char *,
    char *&,
    char[ANY],
    char []
    ""

%typecheck(SWIG_TYPECHECK_POINTER)
    SWIGTYPE,
    SWIGTYPE *,
    SWIGTYPE &,
    SWIGTYPE &&,
    SWIGTYPE *const&,
    SWIGTYPE [],
    SWIGTYPE (*)(ANY),
    SWIGTYPE (CLASS::*)
    ""

//---------------------------------------------------------------------------//
// VOID TYPES
//---------------------------------------------------------------------------//

%typemap(ctype)  void
  "void"
%typemap(out)    void
  ""
%typemap(imtype) void
  ""
%typemap(ftype)  void
  ""
%typemap(fin)    void
  ""
%typemap(fout)   void
  ""

// Void pointers are returned as opaque C pointers
FORT_OPAQUE_PTR_TYPEMAP(void*)

//---------------------------------------------------------------------------//
// CLASSES BY VALUE
//---------------------------------------------------------------------------//

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered.
%fragment("SwigfUnknownClass", "fpublic", noblock=1) %{
type :: SwigfUnknownClass
  type(C_PTR), public :: swigptr
end type
%}

// Classes accepted by value are still passed by reference by fortran
%typemap(ctype)  SWIGTYPE
  %{void*%}
// They're copy-assigned when they're passed
%typemap(in, noblock=1)     SWIGTYPE
  {$1 = *%static_cast($input, $&1_type);}
// Returning a class by value is copy-constructed as a new'd pointer
%typemap(out, noblock=1)    SWIGTYPE
  {$result = %new_copy($1, $1_ltype); }

// Wrapper type is void*
%typemap(imtype, in="type(C_PTR), value") SWIGTYPE
  "type(C_PTR)"
%typemap(ftype)  SWIGTYPE
  "type($fclassname)"
%typemap(fin)    SWIGTYPE
  "$1 = $input%swigptr"
%typemap(fout)   SWIGTYPE
  "$result%swigptr = $1"

//---------------------------------------------------------------------------//
// CLASSES BY REFERENCE/POINTER
//---------------------------------------------------------------------------//
// Mutable pointer, mutable reference, and const pointer to mutable reference

%typemap(ctype) SWIGTYPE*, SWIGTYPE&, SWIGTYPE* const
  "void*"
%typemap(in, noblock=1) SWIGTYPE*, SWIGTYPE&
  {$1 = %static_cast($input, $1_ltype);}
%typemap(out) SWIGTYPE*, SWIGTYPE&, SWIGTYPE* const
  "$result = $1;"
%typemap(imtype, in="type(C_PTR), value") SWIGTYPE*, SWIGTYPE&, SWIGTYPE* const
  "type(C_PTR)"
%typemap(ftype, out="type($fclassname)") SWIGTYPE*, SWIGTYPE&, SWIGTYPE* const
  "class($fclassname)"
%typemap(fin) SWIGTYPE*, SWIGTYPE&, SWIGTYPE* const
  "$1 = $input%swigptr"
%typemap(fout) SWIGTYPE*, SWIGTYPE&, SWIGTYPE* const
  "$result%swigptr = $1"

%typemap(ctype) const SWIGTYPE*, const SWIGTYPE&
  "const void*"
%typemap(in, noblock=1) const SWIGTYPE*, const SWIGTYPE&
  {$1 = %static_cast(%const_cast($input, void*), $1_ltype);}

//---------------------------------------------------------------------------//
// MORE POINTERS
//---------------------------------------------------------------------------//

// NOTE: handles are untested

// Handles are returned as opaque C pointers
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE**)
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE* const*)
// Pointer references are returned as opaque C pointers
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE*&)
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE* const&)

//---------------------------------------------------------------------------//
// STRING TYPES
//
// Note that currently strings can be passed as character arrays, but returning
// a C string gives just an opaque C pointer
//---------------------------------------------------------------------------//

%define FORT_CHARPTR_TYPEMAP(CTYPE, FTYPE)
  %typemap(ctype)  CTYPE*, CTYPE[], CTYPE[ANY]
    %{CTYPE*%}
  %typemap(in)     CTYPE*, CTYPE[], CTYPE[ANY]
    %{$1 = $input;%}
  %typemap(out)    CTYPE*, CTYPE[], CTYPE[ANY]
    %{$result = $1;%}
  %typemap(imtype, out="type(C_PTR)") CTYPE*, CTYPE[], CTYPE[ANY]
    "character(" FTYPE ")"
  %typemap(ftype, out="type(C_PTR)") CTYPE*, CTYPE[], CTYPE[ANY]
    "character(kind=" FTYPE ", len=*)"
  %typemap(fin)    CTYPE*, CTYPE[], CTYPE[ANY]
    "$1 = $input"
  %typemap(fout)   CTYPE*, CTYPE[], CTYPE[ANY]
    "$result = $1"

  %typemap(ctype)  const CTYPE*, const CTYPE[], const CTYPE[ANY]
    %{const CTYPE*%}
  %typemap(in, noblock=1) const CTYPE*, const CTYPE[], const CTYPE[ANY]
    {$1 = %const_cast($input, $1_ltype);}
  %typemap(out, noblock=1) const CTYPE*, const CTYPE[], const CTYPE[ANY]
    {$result = %const_cast($1, $1_ltype);}
%enddef


FORT_FUND_VALREF_TYPEMAP(char, "integer(C_SIGNED_CHAR)")
FORT_CHARPTR_TYPEMAP(char, "C_CHAR")

#undef FORT_CHARPTR_TYPEMAP

//---------------------------------------------------------------------------//
// ENUMS
//---------------------------------------------------------------------------//

// Values and references
FORT_FUND_VALREF_TYPEMAP(enum SWIGTYPE, "integer(C_INT)")

// Override the default value treatment
%typemap(ctype, out="int") enum SWIGTYPE
    %{int*%}
%typemap(in, noblock=1) enum SWIGTYPE
    {$1 = %static_cast(*$input, $1_ltype);}

// Override references
%typemap(ctype, out="int*") enum SWIGTYPE&, const enum SWIGTYPE&
  "int*"
%typemap(in, noblock=1) enum SWIGTYPE&, const enum SWIGTYPE&
    {$1 = %reinterpret_cast($input, $1_ltype);}
%typemap(out, noblock=1) enum SWIGTYPE&, const enum SWIGTYPE&
    {$result = %reinterpret_cast($1, int*);}

// Override pointers
%typemap(ctype, out="int*") enum SWIGTYPE*
    %{int*%}
%typemap(in, noblock=1) enum SWIGTYPE*
    {$1 = %reinterpret_cast($input, $1_ltype);}
%typemap(out, noblock=1) enum SWIGTYPE*
    {$result = %reinterpret_cast($1, int*);}

// Override fortran type
%typemap(ftype) enum SWIGTYPE, enum SWIGTYPE&, enum SWIGTYPE*
    "integer(kind($fclassname))"

//---------------------------------------------------------------------------//
// FUNCTION POINTERS
//---------------------------------------------------------------------------//

%typemap(ctype)  SWIGTYPE (*)(ANY)
    %{$1_ltype%}
%typemap(in)     SWIGTYPE (*)(ANY)
    %{$1 = $input;%}
%typemap(out)    SWIGTYPE (*)(ANY)
    %{$result = $1;%}
%typemap(imtype, in="type(C_FUNPTR), intent(in), value") SWIGTYPE (*)(ANY)
    "type(C_FUNPTR)"
%typemap(ftype, out="type(C_FUNPTR)")  SWIGTYPE (*)(ANY)
    "type(C_FUNPTR), intent(in), value"
%typemap(fin)    SWIGTYPE (*)(ANY)
    "$1 = $input"
%typemap(fout)   SWIGTYPE (*)(ANY)
%{
   $result = $1
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
