/* C return types used in the wrapper code */
%typemap(fctype) bool               %{bool%}
%typemap(fctype) char               %{char%}
%typemap(fctype) signed char        %{signed char%}
%typemap(fctype) unsigned char      %{unsigned char%}
%typemap(fctype) short              %{short%}
%typemap(fctype) unsigned short     %{int%}
%typemap(fctype) int                %{int%}
%typemap(fctype) unsigned int       %{long%}
%typemap(fctype) long               %{long%}
%typemap(fctype) unsigned long      %{long%}
%typemap(fctype) long long          %{long long%}
%typemap(fctype) unsigned long long %{size_t%}
%typemap(fctype) float              %{float%}
%typemap(fctype) double             %{double%}
%typemap(fctype) void               %{void%}
%typemap(fctype) SWIGTYPE *         %{void*%}
%typemap(fctype) SWIGTYPE &         %{void*%}

/* FORTRAN types used in the fortran code */
%typemap(fftype) bool        "logical(C_BOOL)"
%typemap(fftype) char        "character(C_CHAR)"
%typemap(fftype) signed char "integer(C_SIGNED_CHAR)"
%typemap(fftype) short       "integer(C_SHORT)"
%typemap(fftype) int         "integer(C_INT)"
%typemap(fftype) long        "integer(C_LONG)"
%typemap(fftype) long long   "integer(C_LONG_LONG)"
%typemap(fftype) size_t      "integer(C_SIZE_T)"
%typemap(fftype) float       "real(C_FLOAT)"
%typemap(fftype) double      "real(C_DOUBLE)"
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
%apply char   { unsigned char };
%apply int    { unsigned short };
%apply long   { unsigned int, unsigned long, const unsigned int & };
%apply size_t { unsigned long long };

%apply bool        { const bool & }
%apply char        { const char & }
%apply signed char { const signed char & }
%apply short       { const short & }
%apply int         { const int & }
%apply long        { const long & }
%apply long long   { const long long & }
%apply size_t      { const size_t & }
%apply float       { const float & }
%apply double      { const double & }


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
%typecheck(SWIG_TYPECHECK_POINTER)
    SWIGTYPE,
    SWIGTYPE *,
    SWIGTYPE &,
    SWIGTYPE &&,
    SWIGTYPE *const&,
    SWIGTYPE [],
    SWIGTYPE (CLASS::*)
    ""

