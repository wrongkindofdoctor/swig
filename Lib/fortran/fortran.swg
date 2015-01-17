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
%typemap(fctype) unsigned long long, const unsigned long long & "object"
%typemap(fctype) float,              const float &              "float"
%typemap(fctype) double,             const double &             "double"
%typemap(fctype) void                                           "void"

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
%typemap(fftype) void                                           "void"

/* Input conversions */
%typemap(in) char,
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
