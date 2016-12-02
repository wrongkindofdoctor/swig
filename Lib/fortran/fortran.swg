//---------------------------------------------------------------------------//
// Wrapper code inserted into C
//---------------------------------------------------------------------------//

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

/* C return types used in the wrapper code */
%typemap(fcrtype) bool        %{bool%}
%typemap(fcrtype) char        %{char%}
%typemap(fcrtype) signed char %{signed char%}
%typemap(fcrtype) int         %{int%}
%typemap(fcrtype) long        %{long%}
%typemap(fcrtype) long long   %{long long%}
%typemap(fcrtype) size_t      %{size_t%}
%typemap(fcrtype) float       %{float%}
%typemap(fcrtype) double      %{double%}
%typemap(fcrtype) void        %{void%}
%typemap(fcrtype) SWIGTYPE *  %{void*%}

// TODO: use SWIG's fancy typemap checking
#if 0
#define SWIG_Object void *
#define VOID_Object void
#define SWIG_AppendOutput(result, obj)  SWIG_Fortran_AppendOutput(result, obj)

/* set constant */
#if defined(SWIGPYTHON_BUILTIN)
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
// Wrapper code inserted into Fortran
//---------------------------------------------------------------------------//

/* Fortran types used in the fortran interface code */
%typemap(fitype) bool        *, bool        &, bool        "logical(C_BOOL)"
%typemap(fitype) char        *, char        &, char        "character(C_CHAR)"
%typemap(fitype) signed char *, signed char &, signed char "integer(C_SIGNED_CHAR)"
%typemap(fitype) short       *, short       &, short       "integer(C_SHORT)"
%typemap(fitype) int         *, int         &, int         "integer(C_INT)"
%typemap(fitype) long        *, long        &, long        "integer(C_LONG)"
%typemap(fitype) long long   *, long long   &, long long   "integer(C_LONG_LONG)"
%typemap(fitype) size_t      *, size_t      &, size_t      "integer(C_SIZE_T)"
%typemap(fitype) float       *, float       &, float       "real(C_FLOAT)"
%typemap(fitype) double      *, double      &, double      "real(C_DOUBLE)"
%typemap(fitype) SWIGTYPE *, SWIGTYPE & "type(C_PTR)"
%typemap(fitype) void        ""

/* Fortran types used in the fortran wrapper code */
%typemap(fwtype) bool        *, bool        &, bool        "logical(C_BOOL)"
%typemap(fwtype) char        *, char        &, char        "character(C_CHAR)"
%typemap(fwtype) signed char *, signed char &, signed char "integer(C_SIGNED_CHAR)"
%typemap(fwtype) short       *, short       &, short       "integer(C_SHORT)"
%typemap(fwtype) int         *, int         &, int         "integer(C_INT)"
%typemap(fwtype) long        *, long        &, long        "integer(C_LONG)"
%typemap(fwtype) long long   *, long long   &, long long   "integer(C_LONG_LONG)"
%typemap(fwtype) size_t      *, size_t      &, size_t      "integer(C_SIZE_T)"
%typemap(fwtype) float       *, float       &, float       "real(C_FLOAT)"
%typemap(fwtype) double      *, double      &, double      "real(C_DOUBLE)"
%typemap(fwtype) SWIGTYPE *, SWIGTYPE & "class($*1_ltype)"
%typemap(fwtype) void        ""

/* Fortran 'call' argument extraction used in wrapper subroutine */
%typemap(fwcall) bool        *, bool        &, bool       ,
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

// For wrapped classes, pass the embedded class pointer
%typemap(fwcall) SWIGTYPE, SWIGTYPE *, SWIGTYPE & %{$1%ptr%}

//---------------------------------------------------------------------------//

/* Equivalent types in fortran */
//%apply int    { unsigned short };
//%apply long   { unsigned int, unsigned long, const unsigned int & };
//%apply size_t { unsigned long long };
//%apply SWIGTYPE { const SWIGTYPE*, SWIGTYPE &, const SWIGTYPE& }
