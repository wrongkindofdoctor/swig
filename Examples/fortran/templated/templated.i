%module "templated"

%{
#include "templated.hpp"
%}
%include "templated.hpp"

// Note that template instantiation is after the header include
%template(Thing_Int)  Thing<int>;
%template(Thing_Dbl)  Thing<double>;

// Instantiate and overload a function
%template(print_thing)  print_thing<int>;
%template(print_thing)  print_thing<double>;
