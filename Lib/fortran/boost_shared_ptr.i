//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/boost_shared_ptr.i
 * \author Seth R Johnson
 * \date   Tue Dec 06 15:44:22 2016
 */
//---------------------------------------------------------------------------//

%include <shared_ptr.i>

#ifndef SWIG_SHARED_PTR_NOT_NULL
#define SWIG_SHARED_PTR_NOT_NULL(f) f
#endif

%define SWIG_SHARED_PTR_TYPEMAPS(CONST, TYPE...)

#define SWIGSP__ SWIG_SHARED_PTR_QNAMESPACE::shared_ptr<CONST TYPE >

// %naturalvar is as documented for member variables
%naturalvar TYPE;
%naturalvar SWIGSP__;

// destructor mods
%feature("unref") TYPE "(void)arg1; delete smartarg1;"

//---------------------------------------------------------------------------//
// In/out typemaps
//---------------------------------------------------------------------------//

// Plain value
%typemap(in, noblock=1) CONST TYPE ($&1_type argp = 0) {
    argp = ((SWIGSP__ *)$input) ? ((SWIGSP__ *)$input)->get() : 0;
    if (!argp)
    {
        throw std::logic_error("Attempt to dereference null $1_type");
        return $null;
    }
    $1 = *argp;
}
%typemap(out, noblock=1) CONST TYPE {
    $result = new SWIGSP__(new $1_ltype(($1_ltype &)$1));
}

// Plain pointer
%typemap(in, noblock=1) CONST TYPE * (SWIGSP__ *smartarg = 0) {
    smartarg = (SWIGSP__ *)$input;
    $1 = (TYPE *)(smartarg ? smartarg->get() : 0);
}
%typemap(out, noblock=1, fragment="SWIG_null_deleter") CONST TYPE * {
    $result = $1 ? new SWIGSP__($1 SWIG_NO_NULL_DELETER_$owner) : 0;
}

// Plain reference
%typemap(in, noblock=1) CONST TYPE & {
    $1 = ($1_ltype)(((SWIGSP__ *)$input)
                    ? ((SWIGSP__ *)$input)->get()
                    : 0);
    if (!$1)
    {
        throw std::logic_error("Attempt to dereference null $1_type");
        return $null;
    }
}
%typemap(out, noblock=1, fragment="SWIG_null_deleter") CONST TYPE & {
    $result = new SWIGSP__($1 SWIG_NO_NULL_DELETER_$owner);
}

// Plain pointer by reference
%typemap(in, noblock=1) TYPE *CONST& ($*1_ltype temp = 0) {
    temp = (TYPE *)(((SWIGSP__ *)$input)
                    ? ((SWIGSP__ *)$input)->get()
                    : 0);
    $1 = &temp;
}
%typemap(out, noblock=1, fragment="SWIG_null_deleter") TYPE *CONST& {
    $result = new SWIGSP__(*$1 SWIG_NO_NULL_DELETER_$owner);
}

// shared_ptr by value
%typemap(in, noblock=1) SWIGSP__ {
    if ($input) $1 = *($&1_ltype)$input;
}
%typemap(out, noblock=1) SWIGSP__ {
    $result = SWIG_SHARED_PTR_NOT_NULL($1) ? new $1_ltype($1) : 0;
}

// shared_ptr by reference
%typemap(in, noblock=1) SWIGSP__ & ($*1_ltype tempnull) {
    $1 = $input ? ($1_ltype)$input : &tempnull;
}
%typemap(out, noblock=1) SWIGSP__ & {
    $result = SWIG_SHARED_PTR_NOT_NULL(*$1) ? new $*1_ltype(*$1) : 0;
}

// shared_ptr by pointer
%typemap(in, noblock=1) SWIGSP__ * ($*1_ltype tempnull) {
    $1 = $input ? ($1_ltype)$input : &tempnull;
}
%typemap(out, noblock=1, fragment="SWIG_null_deleter") SWIGSP__ * {
    $result = ($1 && SWIG_SHARED_PTR_NOT_NULL(*$1)) ? new $*1_ltype(*($1_ltype)$1) : 0;
    if ($owner) delete $1;
}

// shared_ptr by pointer reference
%typemap(in, noblock=1) SWIGSP__ *&
            (SWIGSP__ tempnull, $*1_ltype temp = 0) {
    temp = $input ? *($1_ltype)&$input : &tempnull;
    $1 = &temp;
}
%typemap(out, noblock=1) SWIGSP__ *& {
    *($1_ltype)&$result = (*$1 && **$1) ? new SWIGSP__(**$1) : 0;
}

// Various missing typemaps - If ever used (unlikely) ensure compilation error rather than runtime bug
%typemap(in) CONST TYPE[], CONST TYPE[ANY], CONST TYPE (CLASS::*) %{
#error "typemaps for $1_type not available"
%}
%typemap(out) CONST TYPE[], CONST TYPE[ANY], CONST TYPE (CLASS::*) %{
#error "typemaps for $1_type not available"
%}

//---------------------------------------------------------------------------//
// C/Fortran interface (pass as pointers)
//---------------------------------------------------------------------------//
#define ALL_SWIGSP__ SWIGSP__, SWIGSP__ &, SWIGSP__ *, SWIGSP__ *&

%typemap(ctype) ALL_SWIGSP__ "void *"
%typemap(imtype, out="type(C_PTR)") ALL_SWIGSP__ "type(C_PTR), value"
%typemap(ftype) ALL_SWIGSP__ "$typemap(ftype, TYPE)"
%typemap(fin) ALL_SWIGSP__ "$1_name%swigptr"
%typemap(fout) ALL_SWIGSP__
%{
   $result%swigptr = $imcall
%}

%typemap(fdata) CONST TYPE
%{
  type(C_PTR), public :: swigptr = C_NULL_PTR
%}

%typemap(fcreate) CONST TYPE
%{
   if (c_associated(self%swigptr)) call self%release()
   self%swigptr = $imcall
%}

%typemap(frelease) CONST TYPE
%{
   call $imcall
   self%swigptr = C_NULL_PTR
%}

// References
%typemap(fout) TYPE, TYPE &, TYPE *
%{
   $result%swigptr = $imcall
%}

// Instantiate shared pointer
%template() SWIGSP__;

#undef SWIGSP__
#undef ALL_SWIGSP__

%enddef

//---------------------------------------------------------------------------//
// end of fortran/boost_shared_ptr.i
//---------------------------------------------------------------------------//
