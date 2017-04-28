/* File : example.i */
%module classes

%{
#include "classes.hh"
%}

/* Let's just grab the original header file here */
%include "classes.hh"
