//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_except.i
 * \author Seth R Johnson
 * \date   Sun Apr 30 10:29:57 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%fragment("<stdexcept>");

%include <exception.i>

%define %std_exception_map(Exception, Code)
  %typemap(throws,noblock=1) Exception {
    SWIG_exception(Code, $1.what());
  }
  %ignore Exception;
  struct Exception {
  };
%enddef

namespace std {
  %std_exception_map(bad_cast,           SWIG_TypeError);
  %std_exception_map(bad_exception,      SWIG_SystemError);
  %std_exception_map(domain_error,       SWIG_ValueError);
  %std_exception_map(exception,          SWIG_SystemError);
  %std_exception_map(invalid_argument,   SWIG_ValueError);
  %std_exception_map(length_error,       SWIG_IndexError);
  %std_exception_map(logic_error,        SWIG_RuntimeError);
  %std_exception_map(out_of_range,       SWIG_IndexError);
  %std_exception_map(overflow_error,     SWIG_OverflowError);
  %std_exception_map(range_error,        SWIG_OverflowError);
  %std_exception_map(runtime_error,      SWIG_RuntimeError);
  %std_exception_map(underflow_error,    SWIG_OverflowError);
}

//---------------------------------------------------------------------------//
// end of fortran/std_except.i
//---------------------------------------------------------------------------//
