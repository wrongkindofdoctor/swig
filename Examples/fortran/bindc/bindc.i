%module bindc

%fortran_bindc_struct(Point)

%{
#include "bindc.h"
%}

%include "bindc.h"

