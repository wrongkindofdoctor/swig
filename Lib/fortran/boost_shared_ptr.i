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

// Runtime check for a class wrapper not being const.
%fragment("SwigfCheckSpNonnull", "runtime")
%{
#define SWIGF_check_sp_nonnull(INPUT, TYPENAME, FNAME, FUNCNAME, RETURNNULL) \
    if (!(INPUT)) { \
        SWIG_exception_impl(SWIG_TypeError, \
            "Cannot pass null " TYPENAME " (class " FNAME ") " \
            "to function (" FUNCNAME ")", RETURNNULL); \
    }
%}

%define SWIG_SHARED_PTR_TYPEMAPS(CONST, TYPE...)
//---------------------------------------------------------------------------//
// Macro shortcuts
#define SWIGSP__ SWIG_SHARED_PTR_QNAMESPACE::shared_ptr<CONST TYPE >
#define ALL_TYPE__ CONST TYPE, CONST TYPE &, CONST TYPE *, CONST TYPE *&
#define ALL_SWIGSP__ SWIGSP__, SWIGSP__ &, SWIGSP__ *, SWIGSP__ *&
#define CONST_ALL_SWIGSP__ const SWIGSP__ &, const SWIGSP__ *, const SWIGSP__ *&

//---------------------------------------------------------------------------//
// Shared pointers *always* return either NULL or a newly allocated shared
// pointer.
//---------------------------------------------------------------------------//
// %naturalvar causes these types to be wrapped as const references rather than
// pointers when they're member variables. Not sure what this does in practice.
//%naturalvar TYPE;
//%naturalvar SWIGSP__;

//---------------------------------------------------------------------------//
// Copy basic settings from non-SP type (i.e. Fortran will see it the same; we
// override the in/out/ctype below)

%typemap(ftype) ALL_SWIGSP__ "$typemap(ftype, " #TYPE ")"

//---------------------------------------------------------------------------//
// C types: we wrap the *shared pointer* as the value type. The 'in' type is
// always passed to us as a pointer to a SwigfClassWrapper, and the 'out' is
// returned by value.
%typemap(ctype, out="SwigfClassWrapper",
         null="SwigfClassWrapper_uninitialized()", noblock=1,
         fragment="SwigfClassWrapper_wrap")
ALL_SWIGSP__, CONST_ALL_SWIGSP__
  {const SwigfClassWrapper *}

//---------------------------------------------------------------------------//
// Original class by value: access the 'ptr' member of the input, return a
// SP-owned copy of the obtained value.
//---------------------------------------------------------------------------//
%typemap(in, noblock=1,
         fragment="SwigfCheckSpNonnull") CONST TYPE ($&1_type argp = 0)
{
    SWIGF_check_sp_nonnull($input, "$1_ltype", "$fclassname", "$decl", return $null)
    argp = $input->ptr ? %static_cast($input->ptr, SWIGSP__*)->get() : NULL;
    $1 = *argp;
}
%typemap(out, noblock=1) CONST TYPE
{
   $result.ptr = new SWIGSP__(%new_copy($1, $1_basetype));
   $result.mem = SWIGF_MOVE;
}

//---------------------------------------------------------------------------//
// Original class by pointer. Note that the deleter is determined by the owner
// mem, but the shared pointer instance itself is in a "moving" mem
// regardless.
//---------------------------------------------------------------------------//
%typemap(in, noblock=1) CONST TYPE * (SWIGSP__* smartarg)
{
    smartarg = %static_cast($input->ptr, SWIGSP__*);
    $1 = smartarg ? %as_mutable(smartarg->get()) : NULL;
}

%typemap(out, noblock=1, fragment="SWIG_null_deleter") CONST TYPE *
{
    $result.ptr = $1 ? new SWIGSP__($1 SWIG_NO_NULL_DELETER_$owner) : NULL;
    $result.mem = SWIGF_MOVE;
}

//---------------------------------------------------------------------------//
// Original class by reference. Same as by pointer, but with null checks.
//---------------------------------------------------------------------------//
%typemap(in, noblock=1,
         fragment="SwigfCheckSpNonnull") CONST TYPE& (SWIGSP__* smartarg)
{
    SWIGF_check_sp_nonnull($input,
                        "$1_ltype", "$fclassname", "$decl", return $null)
    smartarg = %static_cast($input->ptr, SWIGSP__*);
    $1 = %as_mutable(smartarg->get());
}

%typemap(out) CONST TYPE&
{
    $result.ptr = new SWIGSP__($1 SWIG_NO_NULL_DELETER_$owner);
    $result.mem = SWIGF_MOVE;
}

//---------------------------------------------------------------------------//
// SP by value
//---------------------------------------------------------------------------//
%typemap(in, noblock=1) SWIGSP__
{
    if ($input->ptr) $1 = *%static_cast($input->ptr, SWIGSP__*);
}

%typemap(out, noblock=1) SWIGSP__
{
    $result.ptr = %new_copy($1, SWIGSP__);
    $result.mem = SWIGF_MOVE;
}

//---------------------------------------------------------------------------//
// SP by reference
//---------------------------------------------------------------------------//
%typemap(in, noblock=1) SWIGSP__& ($*1_ltype tempnull)
{
    $1 = $input->ptr ? %static_cast($input->ptr, $1_ltype) : &tempnull;
}

%typemap(out, noblock=1) SWIGSP__&
{
    $result.ptr = SWIG_SHARED_PTR_NOT_NULL(*$1) ? new $*1_ltype(*$1) : 0;
    $result.mem = SWIGF_MOVE;
}

//---------------------------------------------------------------------------//
// SP by pointer
//
// Make sure that the SP* is allocated.
//---------------------------------------------------------------------------//
%typemap(in, noblock=1) SWIGSP__ * ($*1_ltype tempnull)
{
    $1 = $input->ptr ? %static_cast($input->ptr, $1_ltype) : &tempnull;
}

%typemap(out, noblock=1, fragment="SWIG_null_deleter") SWIGSP__ *
{
    $result = ($1 && SWIG_SHARED_PTR_NOT_NULL(*$1)) ? new $*1_ltype(*($1_ltype)$1) : 0;
    if ($owner) delete $1;
}

//---------------------------------------------------------------------------//
// Miscellaneous
//---------------------------------------------------------------------------//
// Various missing typemaps - If ever used (unlikely) ensure compilation error
// inside the wrapper
%typemap(in) CONST TYPE[], CONST TYPE[ANY], CONST TYPE (CLASS::*) %{
#error "typemaps for $1_type not available"
%}
%typemap(out) CONST TYPE[], CONST TYPE[ANY], CONST TYPE (CLASS::*) %{
#error "typemaps for $1_type not available"
%}

//---------------------------------------------------------------------------//
// Replace call to "delete (Foo*) arg1;" with call to delete the *shared
// pointer* (so decrement the reference count instead of forcing the object to
// be destroyed and causing a double-delete)
%feature("unref") TYPE
%{ (void)$self; delete smart$self; %}

//---------------------------------------------------------------------------//
// Instantiate shared pointer
%template() SWIGSP__;

//---------------------------------------------------------------------------//
// Clean up macros
#undef SWIGSP__
#undef ALL_TYPE__
#undef ALL_SWIGSP__
#undef CONST_ALL_SWIGSP__

%enddef

//---------------------------------------------------------------------------//
// end of fortran/boost_shared_ptr.i
//---------------------------------------------------------------------------//
