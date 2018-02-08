%module bindc

%fortran_bindc_struct(Point)

%{
#include "bindc.hh"
%}

%include "bindc.hh"

