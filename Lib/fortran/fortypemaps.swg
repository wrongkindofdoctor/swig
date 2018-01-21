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

%typemap(imbindc) void
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
  %typemap(ctype)     DST_TYPE = SRC_TYPE;
  %typemap(in)        DST_TYPE = SRC_TYPE;
  %typemap(out)       DST_TYPE = SRC_TYPE;
  %typemap(imtype)    DST_TYPE = SRC_TYPE;
  %typemap(ftype)     DST_TYPE = SRC_TYPE;
  %typemap(fin)       DST_TYPE = SRC_TYPE;
  %typemap(fout)      DST_TYPE = SRC_TYPE;
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
  %typemap(imtype, in="type(C_PTR), value", bindc=FTYPE) CPPTYPE*
    "type(C_PTR)"
  %typemap(ftype, out=FTYPE ", pointer") CPPTYPE*
    FTYPE ", target, intent(inout)"
  %typemap(fin)  CPPTYPE*
    "$1 = c_loc($input)"
  %typemap(fout) CPPTYPE*
    "call c_f_pointer($1, $result)"
  FORT_COPY_TYPEMAPS(CPPTYPE*, CPPTYPE* const);

  // Mutable references and arrays are treated just like pointers
  FORT_COPY_TYPEMAPS(CPPTYPE*,
                     CPPTYPE&, CPPTYPE*&, CPPTYPE[], CPPTYPE[ANY]);
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
  %typemap(imtype, in="type(C_PTR), value")
        const CPPTYPE*
    "type(C_PTR)"
  %typemap(ftype)  const CPPTYPE*    = CPPTYPE*;
  %typemap(fin)    const CPPTYPE*    = CPPTYPE*;
  %typemap(fout)   const CPPTYPE*    = CPPTYPE*;
  FORT_COPY_TYPEMAPS(const CPPTYPE*, const CPPTYPE* const);

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

  // References to pointers
  FORT_COPY_TYPEMAPS(CPPTYPE*,
                     CPPTYPE*&, const CPPTYPE* const&);
  FORT_COPY_TYPEMAPS(const CPPTYPE*,
                     const CPPTYPE*&, const CPPTYPE* const&);

  // Const arrays are basically like const pointers
  FORT_COPY_TYPEMAPS(const CPPTYPE*,
                     const CPPTYPE[], const CPPTYPE[ANY]);
  // ...except that fixed-sized arrays can be treated natively
  %typemap(ftype, out=FTYPE ", dimension(:), pointer") const CPPTYPE[ANY]
    FTYPE ", dimension($1_dim0), target, intent(in)"
  %typemap(fout) const CPPTYPE[ANY] = CPPTYPE[ANY];

  FORT_COPY_TYPEMAPS(CPPTYPE*,
                     CPPTYPE const [], CPPTYPE const [ANY]);
%enddef

//---------------------------------------------------------------------------//
// FUNDAMENTAL ISO C TYPES
//---------------------------------------------------------------------------//
/*!
 * \def FORT_FUND_TYPEMAP
 * \brief Add a typemap for a fundamental built-in type.
 *
 * The C++ and C types for standard argument wrapping are the same in this
 * case.
 *
 * For fundamental types we also define the "bindc" typemap, for mapping
 * member data of a "BIND(C)" struct from CTYPE to the equivalent Fortran type.
 * Usually this is the same as imtype, but since not all types are BIND(C)
 * compatible, this typemap is more restrictrive than "imtype".
 *
 * Finally, the fundamental type enables *declaring* C functions as pure
 * Fortran interface functions (using the '%bindc' feature) as opposed to
 * generating C wrapper code for them. This uses the 'imbindc' typemap.
 */
%define FORT_FUND_TYPEMAP(CTYPE, FTYPE)
  FORT_SIMPLE_TYPEMAP(CTYPE, CTYPE, FTYPE)

  %typemap(bindc) CTYPE
    FTYPE
  %typemap(bindc) CTYPE*
    "type(C_PTR)"
  %typemap(bindc) CTYPE[ANY]
    FTYPE ", dimension($1_dim0)"
  %typemap(bindc) CTYPE[] = CTYPE*;

  %typemap(imbindc, in=FTYPE ", value") CTYPE
    FTYPE
  %typemap(imbindc, in=FTYPE) CTYPE*
     "type(C_PTR)"
  %typemap(imbindc, in=FTYPE ", dimension($1_dim0)") CTYPE[ANY]
     "type(C_PTR)"
  %typemap(imbindc, in=FTYPE ", dimension(*)") CTYPE[]
     "type(C_PTR)"

  %typemap(imbindc, in=FTYPE", intent(in)") const CTYPE*
     "type(C_PTR)"
  %typemap(imbindc, in=FTYPE", dimension($1_dim0), intent(in)") const CTYPE[ANY]
     "type(C_PTR)"
  %typemap(imbindc, in=FTYPE ", dimension(*), intent(in)") const CTYPE[]
     "type(C_PTR)"
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
FORT_FUND_TYPEMAP(unsigned char     , "integer(C_SIGNED_CHAR)");
FORT_FUND_TYPEMAP(unsigned short    , "integer(C_SHORT)");
FORT_FUND_TYPEMAP(unsigned int      , "integer(C_INT)");
FORT_FUND_TYPEMAP(unsigned long     , "integer(C_LONG)");
FORT_FUND_TYPEMAP(unsigned long long, "integer(C_LONG_LONG)");
FORT_FUND_TYPEMAP(sssize_t          , "integer(C_SIZE_T)");

//---------------------------------------------------------------------------//
// ENUMS
//---------------------------------------------------------------------------//

// Most of the opertions are like integers, but replace the fortran wrapper
// with the kind of enum. Don't worry about pointer types (leave those as
// integer pointers)
FORT_SIMPLE_TYPEMAP(enum SWIGTYPE, int, "integer(C_INT)");

// Fortran input types look like enums
%typemap(in, noblock=1) enum SWIGTYPE
    {$1 = %static_cast(*$input, $1_ltype);}
%typemap(out, noblock=1) enum SWIGTYPE
    {$result = %static_cast($1, int);}
%typemap(ftype, out="integer(kind($fenumname))") enum SWIGTYPE
   "integer(kind($fenumname)), intent(in)"

%typemap(in, noblock=1) const enum SWIGTYPE& ($*1_ltype temp)
    {temp = %static_cast(*$input, $*1_ltype);
     $1 = &temp;}
%typemap(out, noblock=1) const enum SWIGTYPE&
    {$result = %static_cast(*$1, int);}
%typemap(ftype) const enum SWIGTYPE& = enum SWIGTYPE;
   
%typemap(bindc) enum SWIGTYPE
  "integer(kind($fenumname))"
%typemap(bindc) enum SWIGTYPE*
  "type(C_PTR)"

%typemap(imbindc, in="integer(kind($fenumname)), value") enum SWIGTYPE
  "integer(kind($fenumname))"
%typemap(imbindc, in="integer(kind($fenumname))") enum SWIGTYPE*
  "type(C_PTR)"

//---------------------------------------------------------------------------//
// CLASS DEFINITION
//---------------------------------------------------------------------------//

// Data owned by the base class instance
%typemap(fdata, fragment="SwigfClassWrapper") SWIGTYPE
  "type(SwigfClassWrapper), public :: swigdata"
// Whether the data on class $input is valid
%typemap(fassociated) SWIGTYPE
  "$input%swigdata%mem /= SWIGF_NULL"
// Reset the pointer
%typemap(fdisassociate, noblock=1) SWIGTYPE
 %{$input%swigdata%ptr = C_NULL_PTR
   $input%swigdata%mem = SWIGF_NULL%}

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
%typemap(in, noblock=1,
         fragment="SwigfCheckNonnull") SWIGTYPE
  {SWIGF_check_nonnull(*$input, "$1_ltype", "$fclassname", "$decl", return $null);
   $1 = *%static_cast($input->ptr, $&1_ltype);}
%typemap(out, noblock=1) SWIGTYPE
  {$result.ptr = %new_copy($1, $1_ltype);
   $result.mem = SWIGF_MOVE;}

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
%typemap(in, noblock=1, fragment="SwigfCheckMutable") SWIGTYPE*
  {SWIGF_check_mutable(*$input, "$1_ltype", "$fclassname", "$decl", return $null);
  $1 = %static_cast($input->ptr, $1_ltype);}
%typemap(out, noblock=1) SWIGTYPE*
  {$result.ptr = $1;
   $result.mem = ($owner ? SWIGF_MOVE : SWIGF_REF);}
%typemap(imtype) SWIGTYPE* = SWIGTYPE;
%typemap(ftype, out="type($fclassname)") SWIGTYPE*
  "class($fclassname), intent(inout)"
%typemap(fin)    SWIGTYPE* = SWIGTYPE;
%typemap(fout)   SWIGTYPE* = SWIGTYPE;
  
// Raw pointers act mostly like value types (with overrides below)
%typemap(ctype)  const SWIGTYPE* = SWIGTYPE*;
%typemap(in, noblock=1) const SWIGTYPE*
  {$1 = %static_cast($input->ptr, $1_ltype);}
%typemap(out, noblock=1) const SWIGTYPE*
  {$result.ptr = (void*)$1;
   $result.mem = SWIGF_CREF;}
%typemap(imtype) const SWIGTYPE* = SWIGTYPE*;
%typemap(ftype, out="type($fclassname)") const SWIGTYPE*
  "class($fclassname), intent(in)"
%typemap(fin)    const SWIGTYPE* = SWIGTYPE*;
%typemap(fout)   const SWIGTYPE* = SWIGTYPE*;

// Use const-correct arguments/return values.
FORT_COPY_TYPEMAPS(SWIGTYPE*,
                   SWIGTYPE* const, SWIGTYPE&, SWIGTYPE[], SWIGTYPE[ANY]);
FORT_COPY_TYPEMAPS(const SWIGTYPE*,
                   const SWIGTYPE* const, const SWIGTYPE&, const SWIGTYPE[],
                   const SWIGTYPE[ANY]);

// Check for non-null reference inputs
%typemap(in, noblock=1,
         fragment="SwigfCheckMutableNonnull") SWIGTYPE&
  {SWIGF_check_mutable_nonnull(*$input, "$1_type", "$fclassname", "$decl", return $null);
  $1 = %static_cast($input->ptr, $1_ltype);}
%typemap(in, noblock=1,
         fragment="SwigfCheckNonnull") const SWIGTYPE&
  {SWIGF_check_nonnull(*$input, "$1_type", "$fclassname", "$decl", return $null);
  $1 = %static_cast($input->ptr, $1_ltype);}

// Check for non-null, mutable class input "self"
%typemap(in, noblock=1,
         fragment="SwigfCheckMutableNonnull") SWIGTYPE* self
  {SWIGF_check_mutable_nonnull(*$input, "$1_type", "$fclassname", "$decl", return $null);
  $1 = %static_cast($input->ptr, $1_ltype);}
// Check for non-null class input "self"
%typemap(in, noblock=1,
         fragment="SwigfCheckNonnull") const SWIGTYPE* self
  {SWIGF_check_nonnull(*$input, "$1_type", "$fclassname", "$decl", return $null);
  $1 = %static_cast($input->ptr, $1_ltype);}

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

// C binding for opaque classes
%typemap(bindc, fragment="SwigfClassWrapper") SwigfClassWrapper
  "type(SwigfClassWrapper)"

%typemap(imbindc, in="type(SwigfClassWrapper), value",
         import="SwigfClassWrapper", fragment="SwigfClassWrapper")
    SwigfClassWrapper
  "type(SwigfClassWrapper)"
%typemap(imbindc, in="type(SwigfClassWrapper)",
         import="SwigfClassWrapper", fragment="SwigfClassWrapper")
    SwigfClassWrapper*
  "type(C_PTR)"

//---------------------------------------------------------------------------//
// BIND(C) STRUCT TYPES
//---------------------------------------------------------------------------//
/*!
 * \def %fortran_bindc_typedef_struct
 * \brief Wrap a struct as BIND(C).
 *
 * Because SWIG's processing of the feature directive doesn't quite work, if
 * you define a struct as 'typedef struct A {} B;' the features have to apply
 * to A but the typedefs to B.
 *
 * In the typical case that you're wrapping 'struct A {};', then use
 * %fortran_bindc_struct .
 */
%define %fortran_bindc_typedef_struct(CTYPE, TD_CTYPE)
  // Mark the class as being C-bound
  %feature("fortran:bindc") TD_CTYPE;
  // Remove constructors and destructors
  %nodefaultctor TD_CTYPE;
  %nodefaultdtor TD_CTYPE;

  // Bound structs act just like simple types
  FORT_SIMPLE_TYPEMAP(CTYPE, CTYPE, "type($fclassname)")

  // Interface code has to "import' the class type.
  %typemap(imtype, import="$fclassname") CTYPE
    "type($fclassname)"
  %typemap(imtype) const CTYPE, const CTYPE& = CTYPE;

  // Interface code has to "import' the class type.
  %typemap(bindc, import="$fclassname") CTYPE
    "type($fclassname)"
%enddef

%define %fortran_bindc_struct(CTYPE)
    %fortran_bindc_typedef_struct(CTYPE, CTYPE)
%enddef


//---------------------------------------------------------------------------//
// OPAQUE POINTERS
//---------------------------------------------------------------------------//

%typemap(ctype) void*
  "$1_ltype"
%typemap(in, noblock=1) void*
  {$1 = %reinterpret_cast($input, $1_ltype);}
%typemap(out) void*
  "$result = $1;"
%typemap(imtype, in="type(C_PTR), value") void*
  "type(C_PTR)"
%typemap(ftype) void*
  "type(C_PTR)"
%typemap(fin)  void*
  "$1 = $input"
%typemap(fout)  void*
  "$result = $1"

// Void pointers are returned as opaque C pointers
FORT_COPY_TYPEMAPS(void*,
                   const void*, void* const, void&, void[], void[ANY]);
// Handles are returned as opaque C pointers
FORT_COPY_TYPEMAPS(void*,
                   SWIGTYPE**, SWIGTYPE* [], SWIGTYPE* [ANY])

// Use const-correct arguments/return values.
%typemap(in, noblock=1) const void*
{$1 = %const_cast($input, $1_ltype);}
FORT_COPY_TYPEMAPS(const void*,
                   const SWIGTYPE**, const SWIGTYPE* [], const SWIGTYPE* [ANY],
                   SWIGTYPE* const *, SWIGTYPE* const [], SWIGTYPE* const [ANY]);


// Generic pointers are treated as C pointers when binding
%typemap(bindc) SWIGTYPE*
  "type(C_PTR)"
%typemap(imbindc, in="type(C_PTR), value") SWIGTYPE*
  "type(C_PTR)"

//---------------------------------------------------------------------------//
// FUNCTION POINTERS
//---------------------------------------------------------------------------//

%typemap(ctype)  SWIGTYPE (*)(ANY)
    %{$1_ltype%}
%typemap(in)     SWIGTYPE (*)(ANY)
    %{$1 = $input;%}
%typemap(out)    SWIGTYPE (*)(ANY)
    %{$result = $1;%}
%typemap(imtype, in="type(C_FUNPTR), value") SWIGTYPE (*)(ANY)
    "type(C_FUNPTR)"
%typemap(ftype, out="type(C_FUNPTR)")  SWIGTYPE (*)(ANY)
    "type(C_FUNPTR), intent(in), value"
%typemap(fin)    SWIGTYPE (*)(ANY)
    "$1 = $input"
%typemap(fout)   SWIGTYPE (*)(ANY)
    "$result = $1"

// Copy to immutable function pointers
FORT_COPY_TYPEMAPS(SWIGTYPE (*)(ANY),
                   SWIGTYPE (*const)(ANY));

%typemap(bindc) SWIGTYPE (*)(ANY)
  "type(C_FUNPTR)"
%typemap(imbindc, in="type(C_FUNPTR), value") SWIGTYPE (*)(ANY)
  "type(C_FUNPTR)"

//---------------------------------------------------------------------------//
// MEMBER FUNCTION POINTERS
//---------------------------------------------------------------------------//
#ifdef __cplusplus

%typemap(ctype, fragment="SwigfOpaqueMemFunPtr_wrap",
         null="SwigfOpaqueMemFunPtr_uninitialized()") SWIGTYPE (CLASS::*)
    %{SwigfOpaqueMemFunPtr%}
%typemap(in, fragment="SwigfBruteCast") SWIGTYPE (CLASS::*)
    %{$1 = brute_cast<$1_ltype>($input);%}
%typemap(out, fragment="SwigfBruteCast") SWIGTYPE (CLASS::*)
    %{$result = brute_cast<SwigfOpaqueMemFunPtr>($1);%}
%typemap(imtype, in="type(SwigfOpaqueMemFunPtr), intent(in), value",
         import="SwigfOpaqueMemFunPtr",
         fragment="SwigfOpaqueMemFunPtr") SWIGTYPE (CLASS::*)
    "type(SwigfOpaqueMemFunPtr)"
%typemap(ftype, out="type(SwigfOpaqueMemFunPtr)",
         fragment="SwigfOpaqueMemFunPtr") SWIGTYPE (CLASS::*)
    "type(SwigfOpaqueMemFunPtr), intent(in), value"
%typemap(fin) SWIGTYPE (CLASS::*)
    "$1 = $input"
%typemap(fout) SWIGTYPE (CLASS::*)
    "$result = $1"

// Copy to immutable member function pointers
FORT_COPY_TYPEMAPS(SWIGTYPE (CLASS::*),
                   SWIGTYPE (CLASS::* const));

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
