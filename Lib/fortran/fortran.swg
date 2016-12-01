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

/* FORTRAN types used in the fortran code */
%typemap(fftype) bool        *, bool        &, bool        "logical(C_BOOL)"
%typemap(fftype) char        *, char        &, char        "character(C_CHAR)"
%typemap(fftype) signed char *, signed char &, signed char "integer(C_SIGNED_CHAR)"
%typemap(fftype) short       *, short       &, short       "integer(C_SHORT)"
%typemap(fftype) int         *, int         &, int         "integer(C_INT)"
%typemap(fftype) long        *, long        &, long        "integer(C_LONG)"
%typemap(fftype) long long   *, long long   &, long long   "integer(C_LONG_LONG)"
%typemap(fftype) size_t      *, size_t      &, size_t      "integer(C_SIZE_T)"
%typemap(fftype) float       *, float       &, float       "real(C_FLOAT)"
%typemap(fftype) double      *, double      &, double      "real(C_DOUBLE)"

%typemap(fftype) SWIGTYPE *  "type(C_PTR)"
%typemap(fftype) SWIGTYPE &  "type(C_PTR)"
%typemap(fftype) void        ""

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
%{ $1 = *$input; %}

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
%{ $result = $1; %}

%typemap(out) void "";

/* Fortran class insertion */
%typemap(faccess) bool,
                  char,
                  signed char,
                  short,
                  int,
                  long,
                  long long,
                  size_t,
                  float,
                  double
%{$1%}

// For wrapped classes, pass the embedded class pointer
%typemap(faccess) SWIGTYPE, SWIGTYPE *, SWIGTYPE &      %{$1%ptr%}

/* Equivalent types in fortran */
//%apply int    { unsigned short };
//%apply long   { unsigned int, unsigned long, const unsigned int & };
//%apply size_t { unsigned long long };
//%apply SWIGTYPE { const SWIGTYPE*, SWIGTYPE &, const SWIGTYPE& }

%typemap(out) SWIGTYPE
#ifdef __cplusplus
%{
    // Return object passed by value
    *($&1_ltype*)&$result = new $1_ltype((const $1_ltype &)$1);
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

