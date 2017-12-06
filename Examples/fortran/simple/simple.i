/* File : simple.i */
%module simple

%include "docstring.i"

%inline %{
extern int    gcd(int x, int y);
extern double Foo;
%}

