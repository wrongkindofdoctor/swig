/* File : example.i */
%module example

%{
#include "example.h"
%}

%include <std_except.i>
%exception {
    try {
        $action
    }
    catch (const std::exception& e)
    {
        SWIG_exception(SWIG_RuntimeError, e.what());
    }
}

/* Let's just grab the original header file here */
%include "example.h"
