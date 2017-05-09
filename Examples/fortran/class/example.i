/* File : example.i */
%module example

%{
#include "example.hh"
%}

/* Uncomment to test exeption handling */
#if 0
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

#endif

/* Let's just grab the original header file here */
%include "example.hh"
