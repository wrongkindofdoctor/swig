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
 * ctype:null : null value to return for exceptions, etc. (must be convertible
 *              to type ctype or ctype:out)
 * imtype     : Fortran type returned from "BIND" interface (must be Fortran
 *              equivalent of ctype:out)
 * imtype:in  : Fortran dummy argument type for "BIND" interface (must be
 *              Fortran equivalent of ctype)
 * imtype:import : Import this fortran type into the interface declaration
 * ftype      : Fortran proxy type
 * fin        : Fortran proxy code used to translate a Fortran argument to a
 *              wrapper argument
 * fout       : Fortran proxy code to translate return value
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
// VOID TYPES
//---------------------------------------------------------------------------//

%typemap(ctype, null="")  void
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

//---------------------------------------------------------------------------//
// FUNDAMENTAL TYPES
//---------------------------------------------------------------------------//
/*!
 * \def FORT_COPY_TYPEMAPS
 * \brief Assign our special typemaps to one or more types from an original.
 *
 * This is basically like %apply but doesn't touch anything else SWIG has
 * set up, i.e. globalin
 */
%define FORT_COPY_TYPEMAPS(SRC_TYPE, DST_TYPE...)
  %typemap(ctype)  DST_TYPE = SRC_TYPE;
  %typemap(in)     DST_TYPE = SRC_TYPE;
  %typemap(out)    DST_TYPE = SRC_TYPE;
  %typemap(imtype) DST_TYPE = SRC_TYPE;
  %typemap(ftype)  DST_TYPE = SRC_TYPE;
  %typemap(fin)    DST_TYPE = SRC_TYPE;
  %typemap(fout)   DST_TYPE = SRC_TYPE;
%enddef
  
//---------------------------------------------------------------------------//
// FUNDAMENTAL TYPES
//---------------------------------------------------------------------------//
/*!
 * \def FORT_SIMPLE_TYPEMAP
 * \brief Add typemaps where the C++ and C types are convertible, and
 * the intermediate Fortran typemaps are also directly convertible.
 *
 * - Arguments in Fortran are passed by pointer reference, and return
 * types are passed by value.
 * - Returning by const reference is automatically turned into return-by-value
 *  (this is the 'out=CTYPE' argument).
 * - Mutable references that are arguments get the 'inout' qualifier in Fortran,
 *  whereas values and const references are simply 'in'.
 * - Mutable references that are *return* values are passed as pointers, and on
 * the Fortan side these become 'pointer' types.
 * - Fixed-size arrays are passed as known-size array pointers, but otherwise
 *   they are treated as pointers to scalar data.
 */
%define FORT_SIMPLE_TYPEMAP(CPPTYPE, CTYPE, FTYPE)
  // Regular values are passed as pointers and returned by value
  %typemap(ctype, out="CTYPE") CPPTYPE
    "const CTYPE*"
  %typemap(in) CPPTYPE
    "$1 = *$input;"
  %typemap(out) CPPTYPE
    "$result = $1;"
  %typemap(imtype, in=FTYPE ", intent(in)") CPPTYPE
    FTYPE
  %typemap(ftype, out=FTYPE) CPPTYPE
    FTYPE ", intent(in)"
  %typemap(fin)  CPPTYPE
    "$1 = $input"
  %typemap(fout) CPPTYPE
    "$result = $1"

  // Mutable references are passed by pointers as arguments, but they're
  // *returned* as actual pointers (becoming Fortran pointers). Again we face
  // problems when these typemaps are "applied" to a different type. Ideally we
  // could check *at least* that the types are the same size...
  %typemap(ctype, out="CTYPE*") CPPTYPE*
    "CTYPE*"
  %typemap(in, noblock=1) CPPTYPE*
    {$1 = %reinterpret_cast($input, $1_ltype);}
  %typemap(out, noblock=1) CPPTYPE*
    {$result = %reinterpret_cast($1, CTYPE*);}
  %typemap(imtype, in="type(C_PTR), value") CPPTYPE*
    "type(C_PTR)"
  %typemap(ftype, out=FTYPE ", pointer") CPPTYPE*
    FTYPE ", target, intent(inout)"
  %typemap(fin)  CPPTYPE*
    "$1 = c_loc($input)"
  %typemap(fout) CPPTYPE*
    "call c_f_pointer($1, $result)"

  // Mutable references and arrays are treated just like pointers
  FORT_COPY_TYPEMAPS(CPPTYPE*,
                     CPPTYPE&, CPPTYPE[], CPPTYPE[ANY]);
  // ...except that fixed-sized arrays can be treated natively
  %typemap(ftype, out=FTYPE ", dimension(:), pointer") CPPTYPE[ANY]
    FTYPE ", dimension($1_dim0), target, intent(inout)"
  %typemap(fout) CPPTYPE[ANY]
  %{
      call c_f_pointer($1, $result, [$1_dim0])
  %}

  // Const pointers also are treated like raw pointers for the most part,
  // except for some constness issues
  %typemap(ctype, out="const CTYPE*") const CPPTYPE*
    "const CTYPE*"
  %typemap(in, noblock=1) const CPPTYPE*
    {$1 = %reinterpret_cast(%const_cast($input, CTYPE*), $1_ltype);}
  %typemap(out, noblock=1) const CPPTYPE*
    {$result = %const_cast(%reinterpret_cast($1, const CTYPE*), CTYPE*);}
  %typemap(imtype) const CPPTYPE*    = CPPTYPE*;
  %typemap(ftype)  const CPPTYPE*    = CPPTYPE*;
  %typemap(fin)    const CPPTYPE*    = CPPTYPE*;
  %typemap(fout)   const CPPTYPE*    = CPPTYPE*;

  // We treat const references like value types for fundamental types.
  %typemap(ctype) const CPPTYPE& = CPPTYPE;
  // ...although we need to process input values as pointer
  %typemap(in, noblock=1) const CPPTYPE& = const CPPTYPE*;
  // ...and output values have to be dereferenced to turn into values
  %typemap(out) const CPPTYPE&
    "$result = *$1;"
  %typemap(imtype) const CPPTYPE& = CPPTYPE;
  %typemap(ftype)  const CPPTYPE& = CPPTYPE;
  %typemap(fin)    const CPPTYPE& = CPPTYPE;
  %typemap(fout)   const CPPTYPE& = CPPTYPE;

  
  // Const arrays are basically like const pointers
  FORT_COPY_TYPEMAPS(const CPPTYPE*,
                     const CPPTYPE[], const CPPTYPE[ANY]);
  // ...except that fixed-sized arrays can be treated natively
  %typemap(ftype, out=FTYPE ", dimension(:), pointer") const CPPTYPE[ANY]
    FTYPE ", dimension($1_dim0), target, intent(in)"
  %typemap(fout) const CPPTYPE[ANY] = CPPTYPE[ANY];
%enddef

//---------------------------------------------------------------------------//
// FUNDAMENTAL ISO C TYPES
//---------------------------------------------------------------------------//
/*!
 * \def FORT_FUND_TYPEMAP
 * \brief Add a typemap for a fundamental built-in type.
 *
 * The C++ and C types are the same in this case.
 */
%define FORT_FUND_TYPEMAP(CTYPE, FTYPE)
  FORT_SIMPLE_TYPEMAP(CTYPE, CTYPE, FTYPE)
%enddef

FORT_FUND_TYPEMAP(bool       , "logical(C_BOOL)"     )
FORT_FUND_TYPEMAP(signed char, "integer(C_SIGNED_CHAR)")
FORT_FUND_TYPEMAP(short      , "integer(C_SHORT)"    )
FORT_FUND_TYPEMAP(int        , "integer(C_INT)"      )
FORT_FUND_TYPEMAP(long       , "integer(C_LONG)"     )
FORT_FUND_TYPEMAP(long long  , "integer(C_LONG_LONG)")
FORT_FUND_TYPEMAP(size_t     , "integer(C_SIZE_T)"   )
FORT_FUND_TYPEMAP(float      , "real(C_FLOAT)"       )
FORT_FUND_TYPEMAP(double     , "real(C_DOUBLE)"      )
FORT_FUND_TYPEMAP(char       , "integer(C_SIGNED_CHAR)")

//---------------------------------------------------------------------------//
// UNSIGNED INTEGER TYPES
//---------------------------------------------------------------------------//
/*!
 * \def FORT_UNSIGNED_TYPEMAP
 * \brief Add typemaps for unsigned values.
 *
 * Since Fortran does not have unsigned types, we might want to validate that
 * the values being passed back and forth don't exceed the range of the signed
 * values (or ensure that values being passed to C++ aren't negative). However,
 * since some sentinel values are deliberately defined as e.g.
 * \code static_cast<unsigned int> foo(-1); \endcode we don't want to do this
 * by default.
 */
// Note: ssize_t is defined in <sys/types.h> and isn't part of the standard
FORT_FUND_TYPEMAP(unsigned char     , "integer(C_SIGNED_CHAR)"); // Copied from char     
FORT_FUND_TYPEMAP(unsigned short    , "integer(C_SHORT)"); // Copied from short    
FORT_FUND_TYPEMAP(unsigned int      , "integer(C_INT)"); // Copied from int      
FORT_FUND_TYPEMAP(unsigned long     , "integer(C_LONG)"); // Copied from long     
FORT_FUND_TYPEMAP(unsigned long long, "integer(C_LONG_LONG)"); // Copied from long long
FORT_FUND_TYPEMAP(sssize_t          , "integer(C_SIZE_T)"); // Copied from size_t   

//---------------------------------------------------------------------------//
// ENUMS
//---------------------------------------------------------------------------//

// Most of the opertions are like integers, but replace the fortran wrapper
// with the kind of enum. Don't worry about pointer types (leave those as
// integer pointers)
FORT_SIMPLE_TYPEMAP(enum SWIGTYPE, int, "integer(C_INT)"); // Copied from int      
// Fortran input types look like enums
%typemap(in, noblock=1) enum SWIGTYPE, const enum SWIGTYPE&
    {$1 = %static_cast(*$input, $1_ltype);}
%typemap(out, noblock=1) enum SWIGTYPE, const enum SWIGTYPE&
    {$result = %static_cast($1, int);}
%typemap(ftype, out="integer(kind($fenumname))")
    enum SWIGTYPE, const enum SWIGTYPE&
   "integer(kind($fenumname)), intent(in)"

//---------------------------------------------------------------------------//
// CLASS DEFINITION
//---------------------------------------------------------------------------//

// Data owned by the base class instance
%typemap(fdata, fragment="SwigfClassWrapper") SWIGTYPE
  "type(SwigfClassWrapper), public :: swigdata"
// Whether the data on class $input is valid
%typemap(fassociated) SWIGTYPE
  "$input%swigdata%flag == SWIGF_UNINIT"
// Reset the pointer
%typemap(fdisassociate, noblock=1) SWIGTYPE
 %{$input%swigdata%flag = SWIGF_UNINIT
   $input%swigdata%ptr  = C_NULL_PTR%}

//---------------------------------------------------------------------------//
// CLASS TYPEMAPS
//---------------------------------------------------------------------------//
// By value:
//  Fortran -> C -> C++
//   type   -> const ptr -> value
//
//  C++ -> C -> Fortran -> C -> C++
//   value  -> new ptr -> type
//
// By pointer and reference:
//
// - Both are pointers on Fortran side and passed as class pointers, with the
//   correct constness
// - Const pointers/references must be const_cast to the temporary variable $1
//   because of how SWIG wraps the argument variables
//   
//---------------------------------------------------------------------------//

// Classes accepted by value are passed as const reference.
// They're copy-assigned when they're passed
// Returning a class by value is copy-constructed as a new'd pointer
%typemap(ctype, out="SwigfClassWrapper",
         null="SwigfClassWrapper_uninitialized()", noblock=1,
         fragment="SwigfClassWrapper_wrap")
SWIGTYPE
  {const SwigfClassWrapper *}
%typemap(in, noblock=1) SWIGTYPE
  {$1 = *%static_cast($input->ptr, $&1_ltype);}
%typemap(out, noblock=1) SWIGTYPE
  {$result.ptr  = %new_copy($1, $1_ltype);
   $result.flag = SWIGF_MOVING;}

// These remaining types apply to ALL generic class pointers.
%typemap(imtype, import="SwigfClassWrapper", fragment="SwigfClassWrapper")
    SWIGTYPE
  "type(SwigfClassWrapper)"
%typemap(ftype) SWIGTYPE
  "type($fclassname)"
%typemap(fin) SWIGTYPE
  "$1 = $input%swigdata"
%typemap(fout) SWIGTYPE
  "$result%swigdata = $1"

// Raw pointers act mostly like value types (with overrides below)
%typemap(ctype)  SWIGTYPE* = SWIGTYPE;
%typemap(in, noblock=1) SWIGTYPE*
  {$1 = %static_cast($input->ptr, $1_ltype);}
%typemap(out, noblock=1) SWIGTYPE*
  {$result.ptr  = $1;
   $result.flag = ($owner ? SWIGF_MOVING : SWIGF_REFERENCE);}
%typemap(imtype) SWIGTYPE* = SWIGTYPE;
%typemap(ftype, out="type($fclassname)") SWIGTYPE*
  "class($fclassname)"
%typemap(fin)    SWIGTYPE* = SWIGTYPE;
%typemap(fout)   SWIGTYPE* = SWIGTYPE;
  
// Raw pointers act mostly like value types (with overrides below)
%typemap(ctype)  const SWIGTYPE* = SWIGTYPE*;
%typemap(in, noblock=1) const SWIGTYPE*
  {$1 = %static_cast($input->ptr, $1_basetype*);}
%typemap(out, noblock=1) const SWIGTYPE*
  {$result.ptr  = %const_cast($1, $1_basetype*);
   $result.flag = SWIGF_CONST_REFERENCE;}
%typemap(imtype) const SWIGTYPE* = SWIGTYPE*;
%typemap(ftype, out="type($fclassname)") const SWIGTYPE*
  "class($fclassname)"
%typemap(fin)    const SWIGTYPE* = SWIGTYPE*;
%typemap(fout)   const SWIGTYPE* = SWIGTYPE*;

// Use const-correct arguments/return values.
%typemap(ctype)  SWIGTYPE&, SWIGTYPE[], SWIGTYPE[ANY] = SWIGTYPE*;
%typemap(in)     SWIGTYPE&, SWIGTYPE[], SWIGTYPE[ANY] = SWIGTYPE*;
%typemap(out)    SWIGTYPE&, SWIGTYPE[], SWIGTYPE[ANY] = SWIGTYPE*;
%typemap(imtype) SWIGTYPE&, SWIGTYPE[], SWIGTYPE[ANY] = SWIGTYPE*;
%typemap(ftype)  SWIGTYPE&, SWIGTYPE[], SWIGTYPE[ANY] = SWIGTYPE*;
%typemap(fin)    SWIGTYPE&, SWIGTYPE[], SWIGTYPE[ANY] = SWIGTYPE*;
%typemap(fout)   SWIGTYPE&, SWIGTYPE[], SWIGTYPE[ANY] = SWIGTYPE*;

// Use const-correct arguments/return values.
%typemap(ctype)  const SWIGTYPE&, const SWIGTYPE[], const SWIGTYPE[ANY] = const SWIGTYPE*;
%typemap(in)     const SWIGTYPE&, const SWIGTYPE[], const SWIGTYPE[ANY] = const SWIGTYPE*;
%typemap(out)    const SWIGTYPE&, const SWIGTYPE[], const SWIGTYPE[ANY] = const SWIGTYPE*;
%typemap(imtype) const SWIGTYPE&, const SWIGTYPE[], const SWIGTYPE[ANY] = const SWIGTYPE*;
%typemap(ftype)  const SWIGTYPE&, const SWIGTYPE[], const SWIGTYPE[ANY] = const SWIGTYPE*;
%typemap(fin)    const SWIGTYPE&, const SWIGTYPE[], const SWIGTYPE[ANY] = const SWIGTYPE*;
%typemap(fout)   const SWIGTYPE&, const SWIGTYPE[], const SWIGTYPE[ANY] = const SWIGTYPE*;

// Structs will generate free/malloc usage via the %free typemap, but SWIG
// doesn't include <stdlib.h> by default. Override the swigtype usage so that
// downstream code doesn't fail.
#ifndef __cplusplus
%typemap(ctype, fragment="<stdlib.h>")
        SWIGTYPE, SWIGTYPE*, SWIGTYPE&, SWIGTYPE* const
  "void*"
%typemap(ctype, fragment="<stdlib.h>") const SWIGTYPE*, const SWIGTYPE&
  "const void*"
#endif

//---------------------------------------------------------------------------//
// BIND(C) STRUCT TYPES
//---------------------------------------------------------------------------//
/*!
 * \def FORT_BINDC_STRUCT
 * \brief Add a typemap for a fundamental built-in type.
 *
 * The C++ and C types are the same in this case.
 */
%define %fortran_bindc_struct(CTYPE)
  // Mark the class as being C-bound
  %feature("fortran:bindc") CTYPE;
  // Remove constructors and destructors
  %nodefaultctor CTYPE;
  %nodefaultdtor CTYPE;

  %typemap(imtype, import="$fclassname") CTYPE
    "type($fclassname)"

  // Bound structs act just like simple types
  FORT_SIMPLE_TYPEMAP(CTYPE, CTYPE, "type($fclassname)")

  // Interface code has to "import' the class type.
  %typemap(imtype, import="$fclassname") CTYPE, CTYPE*, CTYPE&, 
          const CTYPE, const CTYPE*, const CTYPE& 
    "type($fclassname)"
%enddef

//---------------------------------------------------------------------------//
// OPAQUE POINTERS
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

// Void pointers are returned as opaque C pointers
FORT_OPAQUE_PTR_TYPEMAP(void*)
FORT_OPAQUE_PTR_TYPEMAP(void[])

// Handles are returned as opaque C pointers
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE**)
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE* [])
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE* [ANY])
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE* const*)
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE* const[])
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE* const[ANY])

// Pointer references are returned as opaque C pointers
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE*&)
FORT_OPAQUE_PTR_TYPEMAP(SWIGTYPE* const&)

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
    "$result = $1"

// Const function pointers need special treatment
%typemap(ctype)  SWIGTYPE (*const)(ANY)
    %{$1_ltype%}
%typemap(in)     SWIGTYPE (*const)(ANY)
    %{$1 = $input;%}
%typemap(out)    SWIGTYPE (*const)(ANY)
    %{$result = $1;%}
%typemap(imtype, in="type(C_FUNPTR), intent(in), value") SWIGTYPE (*const)(ANY)
    "type(C_FUNPTR)"
%typemap(ftype, out="type(C_FUNPTR)")  SWIGTYPE (*const)(ANY)
    "type(C_FUNPTR), intent(in), value"
%typemap(fin)    SWIGTYPE (*const)(ANY)
    "$1 = $input"
%typemap(fout)   SWIGTYPE (*const)(ANY)
    "$result = $1"

//---------------------------------------------------------------------------//
// MEMBER FUNCTION POINTERS
//---------------------------------------------------------------------------//
#ifdef __cplusplus

%typemap(ctype, fragment="SwigfOpaqueMemFunPtr_wrap")
        SWIGTYPE (CLASS::*), SWIGTYPE (CLASS::* const)
    %{SwigfOpaqueMemFunPtr%}
%typemap(in, fragment="SwigfBruteCast")
        SWIGTYPE (CLASS::*), SWIGTYPE (CLASS::* const)
    %{$1 = brute_cast<$1_ltype>($input);%}
%typemap(out, fragment="SwigfBruteCast")
        SWIGTYPE (CLASS::*), SWIGTYPE (CLASS::* const)
    %{$result = brute_cast<SwigfOpaqueMemFunPtr>($1);%}
%typemap(imtype, in="type(SwigfOpaqueMemFunPtr), intent(in), value",
         import="SwigfOpaqueMemFunPtr",
         fragment="SwigfOpaqueMemFunPtr")
        SWIGTYPE (CLASS::*), SWIGTYPE (CLASS::* const)
    "type(SwigfOpaqueMemFunPtr)"
%typemap(ftype, out="type(SwigfOpaqueMemFunPtr)",
         fragment="SwigfOpaqueMemFunPtr")
        SWIGTYPE (CLASS::*), SWIGTYPE (CLASS::* const)
    "type(SwigfOpaqueMemFunPtr), intent(in), value"
%typemap(fin)
        SWIGTYPE (CLASS::*), SWIGTYPE (CLASS::* const)
    "$1 = $input"
%typemap(fout)
        SWIGTYPE (CLASS::*), SWIGTYPE (CLASS::* const)
    "$result = $1"

#endif

//---------------------------------------------------------------------------//
// TYPE CHECKING
//---------------------------------------------------------------------------//

// Type checking isn't used for Fortran but is required for unit tests
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
// end of fortran/fortrantypemaps.swg
//---------------------------------------------------------------------------//
