/* C types used in the wrapper code */
%typemap(fctype) bool,               const bool &               "bool"
%typemap(fctype) char,               const char &               "char"
%typemap(fctype) signed char,        const signed char &        "char"
%typemap(fctype) unsigned char,      const unsigned char &      "short"
%typemap(fctype) short,              const short &              "short"
%typemap(fctype) unsigned short,     const unsigned short &     "int"
%typemap(fctype) int,                const int &                "int"
%typemap(fctype) unsigned int,       const unsigned int &       "long"
%typemap(fctype) long,               const long &               "int"
%typemap(fctype) unsigned long,      const unsigned long &      "long"
%typemap(fctype) long long,          const long long &          "long"
%typemap(fctype) unsigned long long, const unsigned long long & "size_t"
%typemap(fctype) float,              const float &              "float"
%typemap(fctype) double,             const double &             "double"
%typemap(fctype) void                                           "void"
%typemap(fctype) SWIGTYPE *, SWIGTYPE &                         "void*"


/* FORTRAN types used in the fortran code */
%typemap(fftype) bool,               const bool &               "logical(C_BOOL)"
%typemap(fftype) char,               const char &               "character(C_CHAR)"
%typemap(fftype) signed char,        const signed char &        "integer(C_SIGNED_CHAR)"
%typemap(fftype) unsigned char,      const unsigned char &      "integer(C_SHORT)"
%typemap(fftype) short,              const short &              "integer(C_SHORT)"
%typemap(fftype) unsigned short,     const unsigned short &     "integer(C_INT)"
%typemap(fftype) int,                const int &                "integer(C_INT)"
%typemap(fftype) unsigned int,       const unsigned int &       "integer(C_LONG)"
%typemap(fftype) long,               const long &               "integer(C_LONG)"
%typemap(fftype) unsigned long,      const unsigned long &      "integer(C_LONG)"
%typemap(fftype) long long,          const long long &          "integer(C_LONG_LONG)"
%typemap(fftype) unsigned long long, const unsigned long long & "integer(C_SIZE_T)"
%typemap(fftype) float,              const float &              "real(C_FLOAT)"
%typemap(fftype) double,             const double &             "real(C_DOUBLE)"
%typemap(fftype) void                                           ""
%typemap(fftype) SWIGTYPE *, SWIGTYPE &                         "type(C_PTR)"

/* Input conversions */
%typemap(in) bool,
             char,
             signed char,
             unsigned char,
             short,
             unsigned short,
             int,
             unsigned int,
             long,
             unsigned long,
             long long,
             unsigned long long,
             float,
             double
%{ $1 = ($1_ltype)$input; %}

/* Output conversions */
%typemap(out) bool,
              char,
              signed char,
              unsigned char,
              short,
              unsigned short,
              int,
              unsigned int,
              long,
              unsigned long,
              long long,
              unsigned long long,
              float,
              double
%{ $result = $1; %}
%typemap(out) void "";


/* Default handling. Object passed by value: Convert to a pointer */
%typemap(in) SWIGTYPE ($&1_type argp)
%{ argp = *($&1_ltype*)&$input;
   if (!argp) {
     return $null;
   }
   $1 = *argp;
%}

%typemap(out) SWIGTYPE
#ifdef __cplusplus
%{ *($&1_ltype*)&$result = new $1_ltype((const $1_ltype &)$1); %}
#else
{
  $&1_ltype $1ptr = ($&1_ltype) malloc(sizeof($1_ltype));
  memmove($1ptr, &$1, sizeof($1_type));
  *($&1_ltype*)&$result = $1ptr;
}
#endif

/* Generic pointers and references */
%typemap(in) SWIGTYPE * %{ $1 = *($&1_ltype)&$input; %}
%typemap(in) SWIGTYPE & %{ $1 = *($&1_ltype)&$input;
  if (!$1) {
    SWIG_JavaThrowException(jenv, SWIG_JavaNullPointerException, "$1_type reference is null");
    return $null;
  } %}
%typemap(in) SWIGTYPE && %{ $1 = *($&1_ltype)&$input;
  if (!$1) {
    SWIG_JavaThrowException(jenv, SWIG_JavaNullPointerException, "$1_type reference is null");
    return $null;
  } %}
%typemap(out) SWIGTYPE *
%{ *($&1_ltype)&$result = $1; %}
%typemap(out) SWIGTYPE &
%{ *($&1_ltype)&$result = $1; %}
%typemap(out) SWIGTYPE &&
%{ *($&1_ltype)&$result = $1; %}

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

