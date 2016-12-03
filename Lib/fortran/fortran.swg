//---------------------------------------------------------------------------//
// Wrapper code inserted into C
//---------------------------------------------------------------------------//

/* C return types used in the wrapper code */
%typemap(fcrtype) bool       , const bool       & %{bool%}
%typemap(fcrtype) char       , const char       & %{char%}
%typemap(fcrtype) signed char, const signed char& %{signed char%}
%typemap(fcrtype) int        , const int        & %{int%}
%typemap(fcrtype) long       , const long       & %{long%}
%typemap(fcrtype) long long  , const long long  & %{long long%}
%typemap(fcrtype) size_t     , const size_t     & %{size_t%}
%typemap(fcrtype) float      , const float      & %{float%}
%typemap(fcrtype) double     , const double     & %{double%}
%typemap(fcrtype) void       , const void       & %{void%}
%typemap(fcrtype) SWIGTYPE *  %{void*%}

/* C parameter types used in the wrapper code */
%typemap(fcptype) bool        %{bool*%}
%typemap(fcptype) char        %{char*%}
%typemap(fcptype) signed char %{signed char*%}
%typemap(fcptype) int         %{int*%}
%typemap(fcptype) long        %{long*%}
%typemap(fcptype) long long   %{long long*%}
%typemap(fcptype) size_t      %{size_t*%}
%typemap(fcptype) float       %{float*%}
%typemap(fcptype) double      %{double*%}
%typemap(fcptype) SWIGTYPE *  %{void*%}
%typemap(fcptype) SWIGTYPE &  %{void*%}

// TODO: use SWIG's fancy typemap checking
#if 0
#define SWIG_Object void *
#define VOID_Object void
#define SWIG_AppendOutput(result, obj)  SWIG_Fortran_AppendOutput(result, obj)

/* set constant */
#if defined(SWIGfortran_BUILTIN)
#define SWIG_SetConstant(name, obj) SWIG_Fortran_SetConstant(d, d == md ? public_interface : NULL, name,obj) 
#else
#define SWIG_SetConstant(name, obj) SWIG_Fortran_SetConstant(d, name,obj) 
#endif

/* raise */
#define SWIG_Raise(obj, type, desc) SWIG_Fortran_Raise(obj, type, desc)

%include <typemaps/swigtypemaps.swg>

#endif

%typemap(out) void "";
/* Input conversions: Fortran requires input arguments to be pointers */
%typemap(in) bool,
             char,
             signed char,
             short,
             int,
             long,
             long long,
             size_t,
             float,
             double
%{ $1 = *$input; /*tmin*/ %}

/* Output conversions */
%typemap(out) bool,
              char,
              signed char,
              short,
              int,
              long,
              long long,
              size_t,
              float,
              double
%{ $result = $1; /*tmout*/ %}

%typemap(out) SWIGTYPE* %{ *($&1_ltype)&$result = $1; %}

/* Input conversions */
%typemap(in) SWIGTYPE* %{ $1 = ($1_ltype)$input; %}
%typemap(in) SWIGTYPE& %{ $1 = *($&1_ltype)&$input; assert($1); %}

%typemap(out) SWIGTYPE
#ifdef __cplusplus
%{
    // Return object passed by value
    *($&1_ltype*)&$result = new $1_ltype((const $1_ltype &)$1); /* pass-by-value */
%}
#else
{
  $&1_ltype $1ptr = ($&1_ltype) malloc(sizeof($1_ltype));
  memmove($1ptr, &$1, sizeof($1_type));
  *($&1_ltype*)&$result = $1ptr;
}
#endif

/* Generic pointers and references */
%typemap(in) SWIGTYPE * %{ $1 = ($1_ltype)$input; %}
%typemap(in) SWIGTYPE & %{ $1 = *($&1_ltype)&$input; assert($1); %}

%typemap(out) SWIGTYPE *  %{ *($&1_ltype)&$result = $1; %}
%typemap(out) SWIGTYPE &  %{ *($&1_ltype)&$result = $1; %}
%typemap(out) SWIGTYPE && %{ *($&1_ltype)&$result = $1; %}

/* Default array handling */
%typemap(in) SWIGTYPE [] %{ $1 = *($&1_ltype)&$input; %}
%typemap(out) SWIGTYPE [] %{ *($&1_ltype)&$result = $1; %}
%typemap(freearg) SWIGTYPE [ANY], SWIGTYPE [] ""

/* Type checking */
%{
#include <cassert>
%}
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
// Proxy code inserted into Fortran
//---------------------------------------------------------------------------//

/* Fortran parameter types used in the fortran interface */
%typemap(fiptype) bool        *, bool        &, bool        "logical(C_BOOL)"
%typemap(fiptype) char        *, char        &, char        "character(C_CHAR)"
%typemap(fiptype) signed char *, signed char &, signed char "integer(C_SIGNED_CHAR)"
%typemap(fiptype) short       *, short       &, short       "integer(C_SHORT)"
%typemap(fiptype) int         *, int         &, int         "integer(C_INT)"
%typemap(fiptype) long        *, long        &, long        "integer(C_LONG)"
%typemap(fiptype) long long   *, long long   &, long long   "integer(C_LONG_LONG)"
%typemap(fiptype) size_t      *, size_t      &, size_t      "integer(C_SIZE_T)"
%typemap(fiptype) float       *, float       &, float       "real(C_FLOAT)"
%typemap(fiptype) double      *, double      &, double      "real(C_DOUBLE)"
%typemap(fiptype) SWIGTYPE *, SWIGTYPE & "type(C_PTR), value"
%typemap(fiptype) void        ""

/* Fortran return types used in the fortran interface */
%typemap(firtype) bool        *, bool        &, bool        "logical(C_BOOL)"
%typemap(firtype) char        *, char        &, char        "character(C_CHAR)"
%typemap(firtype) signed char *, signed char &, signed char "integer(C_SIGNED_CHAR)"
%typemap(firtype) short       *, short       &, short       "integer(C_SHORT)"
%typemap(firtype) int         *, int         &, int         "integer(C_INT)"
%typemap(firtype) long        *, long        &, long        "integer(C_LONG)"
%typemap(firtype) long long   *, long long   &, long long   "integer(C_LONG_LONG)"
%typemap(firtype) size_t      *, size_t      &, size_t      "integer(C_SIZE_T)"
%typemap(firtype) float       *, float       &, float       "real(C_FLOAT)"
%typemap(firtype) double      *, double      &, double      "real(C_DOUBLE)"
%typemap(firtype) SWIGTYPE *, SWIGTYPE & "type(C_PTR)"

/* Fortran types used in the fortran proxy code */
%typemap(fxtype) bool        *, bool        &, bool        "logical(C_BOOL)"
%typemap(fxtype) char        *, char        &, char        "character(C_CHAR)"
%typemap(fxtype) signed char *, signed char &, signed char "integer(C_SIGNED_CHAR)"
%typemap(fxtype) short       *, short       &, short       "integer(C_SHORT)"
%typemap(fxtype) int         *, int         &, int         "integer(C_INT)"
%typemap(fxtype) long        *, long        &, long        "integer(C_LONG)"
%typemap(fxtype) long long   *, long long   &, long long   "integer(C_LONG_LONG)"
%typemap(fxtype) size_t      *, size_t      &, size_t      "integer(C_SIZE_T)"
%typemap(fxtype) float       *, float       &, float       "real(C_FLOAT)"
%typemap(fxtype) double      *, double      &, double      "real(C_DOUBLE)"
%typemap(fxtype) SWIGTYPE *, SWIGTYPE & "class($fortranclassname)"
%typemap(fxtype) void        ""

/* Fortran 'call' argument extraction used in proxy code subroutine */
%typemap(fxget)  bool        *, bool        &, bool       ,
                 char        *, char        &, char       ,
                 signed char *, signed char &, signed char,
                 short       *, short       &, short      ,
                 int         *, int         &, int        ,
                 long        *, long        &, long       ,
                 long long   *, long long   &, long long  ,
                 size_t      *, size_t      &, size_t     ,
                 float       *, float       &, float      ,
                 double      *, double      &, double 
%{$1%}

// For proxy classes, pass the embedded class pointer
%typemap(fxget) SWIGTYPE, SWIGTYPE *, SWIGTYPE & %{$1%ptr%}

/* ------------------------------------------------------------------------- */
/*
  Add fortran code to the proxy/shadow code 
  
   %fortranprepend   - Add code before the C++ function is called
   %fortranappend    - Add code after the C++ function is called
*/

#define %fortranprepend       %feature("fortranprepend") 
#define %clearfortranprepend  %feature("fortranprepend","")

#define %fortranappend         %feature("fortranappend") 
#define %clearfortranappend    %feature("fortranappend","")

//---------------------------------------------------------------------------//

/* Equivalent types in fortran */
%apply int    { unsigned short };
%apply long   { unsigned int, unsigned long, const unsigned int & };
%apply size_t { unsigned long long };
%apply SWIGTYPE { const SWIGTYPE*, SWIGTYPE &, const SWIGTYPE& }
