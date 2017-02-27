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
 * \def FORTRAN_TYPEMAP
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
%define FORTRAN_TYPEMAP(CTYPE, FTYPE)
  %typemap(ctype, out="CTYPE") CTYPE, CTYPE*, CTYPE&, CTYPE[]
    %{CTYPE*%}

  %typemap(in) CTYPE
    %{$1 = *$input;%}
  %typemap(in) CTYPE*, CTYPE&, CTYPE[]
    %{$1 = $input;%}

  %typemap(out) CTYPE, const CTYPE*
    %{$result = $1;%}
  %typemap(out) const CTYPE&
    %{$result = *$1;%}
  %typemap(out) CTYPE&, CTYPE*
    %{
    #error "Can't return primitive types by mutable reference in Fortran"
    %}

  // Note: FTYPE is a string, it gets preprocessor-concatenated to the
  // dimension/intent string
  %typemap(imtype)       CTYPE*, CTYPE[]
    FTYPE ", dimension(*), intent(inout)"
  %typemap(imtype) const CTYPE*, const CTYPE[]
    FTYPE ", dimension(*), intent(in)"
  %typemap(imtype, out=FTYPE) CTYPE&
    FTYPE ", intent(inout)"
  %typemap(imtype, out=FTYPE) CTYPE, const CTYPE&
    FTYPE ", intent(in)"

  %typemap(ftype, out="type(C_PTR)")        CTYPE*, CTYPE[]
    FTYPE ", dimension(:), intent(inout)"
  %typemap(ftype, out="type(C_PTR)")  const CTYPE*, const CTYPE[]
    FTYPE ", dimension(:), intent(in)"
  %typemap(ftype, out=FTYPE)              CTYPE&
    FTYPE ", intent(inout)"
  %typemap(ftype, out=FTYPE) CTYPE, const CTYPE&
    FTYPE ", intent(in)"

  %typemap(fin)  CTYPE, CTYPE[], CTYPE*, CTYPE&, const CTYPE*, const CTYPE&
    %{$1_name%}
  %typemap(fout) CTYPE, CTYPE[], CTYPE*, CTYPE&, const CTYPE*, const CTYPE&
    %{ $result = $imcall %}
%enddef

FORTRAN_TYPEMAP(bool       , "logical(C_BOOL)"     )
FORTRAN_TYPEMAP(short      , "integer(C_SHORT)"    )
FORTRAN_TYPEMAP(int        , "integer(C_INT)"      )
FORTRAN_TYPEMAP(long       , "integer(C_LONG)"     )
FORTRAN_TYPEMAP(long long  , "integer(C_LONG_LONG)")
FORTRAN_TYPEMAP(size_t     , "integer(C_SIZE_T)"   )
FORTRAN_TYPEMAP(float      , "real(C_FLOAT)"       )
FORTRAN_TYPEMAP(double     , "real(C_DOUBLE)"      )

// Apply unsigned equivalent types
%define FORTRAN_EQUIV(CTYPE, CTYPE2)
 %apply       CTYPE  {       CTYPE2  };
 %apply       CTYPE* {       CTYPE2* };
 %apply       CTYPE& {       CTYPE2& };
 %apply const CTYPE* { const CTYPE2* };
 %apply const CTYPE& { const CTYPE2& };
%enddef

FORTRAN_EQUIV(short , unsigned short );
FORTRAN_EQUIV(int   , unsigned int   );
FORTRAN_EQUIV(long  , unsigned long  );
FORTRAN_EQUIV(size_t, unsigned long long);
FORTRAN_EQUIV(size_t, std::size_t);

//---------------------------------------------------------------------------//
// VOID TYPES
//---------------------------------------------------------------------------//

%typemap(ctype)  void %{void%}
%typemap(out)    void %{%}
%typemap(imtype) void ""
%typemap(ftype)  void ""
%typemap(fout)   void %{call $imcall%}

//---------------------------------------------------------------------------//
// PROXY CLASS DEFINITIONS
//---------------------------------------------------------------------------//

%typemap(fdata) SWIGTYPE %{
  type(C_PTR), private :: ptr = C_NULL_PTR
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

%typemap(ctype)  SWIGTYPE %{void*%}
%typemap(in)     SWIGTYPE %{ $1 = *($&1_ltype)($input); %}
%typemap(out)    SWIGTYPE
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
// ARRAY TYPES
//---------------------------------------------------------------------------//

// Cast integer to size_t whenever it shows up as a 'count' argument
%apply int { (std::size_t SIZE) };

// Automatically add "size" parameter from a Fortran array
%typemap(fin, noblock=1) (SWIGTYPE* ARRAY, int SIZE)
    { $1_name, size($1_name) }
%apply (SWIGTYPE* ARRAY, int SIZE) { (SWIGTYPE* ARRAY, int SIZE),
                                     (const SWIGTYPE* ARRAY, int SIZE) };

//---------------------------------------------------------------------------//
// STRING TYPES
//---------------------------------------------------------------------------//

// Single characters: differentiate from char pointers by using value semantics
#if 0
%typemap(ctype, out="char") char %{char*%}
%typemap(in)    char %{ $1 = *$input; %}
%typemap(out)   char %{ $result = $1; %}
%typemap(imtype, out="character") char "character, value"
%typemap(ftype,  out="character") char "character, value, intent(in)"
%typemap(fin) char "$1_name"
#endif

%define CHAR_TYPEMAP(CTYPE, FTYPE)
    %typemap(fin, noblock=1) (CTYPE STRING, int SIZE),
                             (CTYPE STRING, size_t SIZE)
    { $1_name, len($1_name) }
    %typemap(ctype)  CTYPE %{ CTYPE %}
    %typemap(in)     CTYPE %{ $1 = $input; %}
    %typemap(imtype) CTYPE "character(" FTYPE ")"
    %typemap(ftype)  CTYPE "character(len=*)"
    %typemap(fin)    CTYPE "$1_name"
%enddef

CHAR_TYPEMAP(char*, "C_CHAR")
CHAR_TYPEMAP(const char*, "C_CHAR")
CHAR_TYPEMAP(unsigned char*, "C_CHAR")
CHAR_TYPEMAP(const unsigned char*, "C_CHAR")

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
#undef CTYPE
#undef FTYPE

%typemap(ftype)  enum SWIGTYPE "integer(kind($fclassname))"
%typemap(fin)    enum SWIGTYPE "$1_name"
%typemap(fout)   enum SWIGTYPE %{ $result = $imcall %}

//---------------------------------------------------------------------------//
// end of fortran/fortrantypemaps.swg
//---------------------------------------------------------------------------//
