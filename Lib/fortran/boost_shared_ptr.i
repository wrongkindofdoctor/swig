//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/boost_shared_ptr.i
 * \author Seth R Johnson
 * \date   Tue Dec 06 15:44:22 2016
 */
//---------------------------------------------------------------------------//

%include <shared_ptr.i>

%define SWIG_SHARED_PTR_TYPEMAPS(CONST, TYPE...)

// %naturalvar is as documented for member variables
%naturalvar TYPE;
%naturalvar SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >;

// destructor mods
%feature("unref") TYPE "(void)arg1; delete smartarg1;"

//---------------------------------------------------------------------------//
// In/out typemaps
//---------------------------------------------------------------------------//

// Plain value
%typemap(in) CONST TYPE ($&1_type argp = 0) %{
    argp = ((SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *)$input)
        ? ((SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *)$input)->get()
        : 0;
    if (!argp)
    {
        throw std::logic_error("Attempt to dereference null $1_type");
        return $null;
    }
    $1 = *argp;
%}
%typemap(out) CONST TYPE %{
    $result = new SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >(new $1_ltype(($1_ltype &)$1));
%}

// Plain pointer
%typemap(in) CONST TYPE * (SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *smartarg = 0) %{
    smartarg = (SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *)$input;
    $1 = (TYPE *)(smartarg ? smartarg->get() : 0);
%}
%typemap(out, fragment="SWIG_null_deleter") CONST TYPE * %{
    $result = $1 ? new SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >($1 SWIG_NO_NULL_DELETER_$owner) : 0;
%}

// Plain reference
%typemap(in) CONST TYPE & %{
    $1 = ($1_ltype)(((SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *)$input)
                    ? ((SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *)$input)->get()
                    : 0);
    if (!$1)
    {
        throw std::logic_error("Attempt to dereference null $1_type");
        return $null;
    }
%}
%typemap(out, fragment="SWIG_null_deleter") CONST TYPE & %{
    $result = new SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >($1 SWIG_NO_NULL_DELETER_$owner);
%}

// Plain pointer by reference
%typemap(in) TYPE *CONST& ($*1_ltype temp = 0) %{
    temp = (TYPE *)(((SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *)$input)
                    ? ((SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *)$input)->get()
                    : 0);
    $1 = &temp;
%}
%typemap(out, fragment="SWIG_null_deleter") TYPE *CONST& %{
    $result = new SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >(*$1 SWIG_NO_NULL_DELETER_$owner);
%}

// shared_ptr by value
%typemap(in) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > %{
    if ($input) $1 = *($&1_ltype)$input;
%}
%typemap(out) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > %{
    $result = $1 ? new $1_ltype($1) : 0;
%}

// shared_ptr by reference
%typemap(in) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > & ($*1_ltype tempnull) %{
    $1 = $input ? ($1_ltype)$input : &tempnull;
%}
%typemap(out) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > & %{
    $result = *$1 ? new $*1_ltype(*$1) : 0;
%}

// shared_ptr by pointer
%typemap(in) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > * ($*1_ltype tempnull) %{
    $1 = $input ? ($1_ltype)$input : &tempnull;
%}
%typemap(out, fragment="SWIG_null_deleter") SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > * %{
    $result = ($1 && *$1) ? new $*1_ltype(*($1_ltype)$1) : 0;
    if ($owner) delete $1;
%}

// shared_ptr by pointer reference
%typemap(in) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *&
            (SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > tempnull, $*1_ltype temp = 0) %{
    temp = $input ? *($1_ltype)&$input : &tempnull;
    $1 = &temp;
%}
%typemap(out) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *& %{
    *($1_ltype)&$result = (*$1 && **$1) ? new SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >(**$1) : 0;
%}

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

%typemap(ftype) CONST TYPE "class($fortranclassname)"
%typemap(fin)   CONST TYPE "$1_name%ptr"

%typemap(ctype)
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > &,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *&
        "void *"
%typemap(imtype, out="type(C_PTR)")
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > &,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *&
        "type(C_PTR), value"
%typemap(ftype)
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > &,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *&
        "$typemap(ftype, TYPE)"
%typemap(fin)
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > &,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *,
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *&
        "$1_name%ptr"

#if 0
%typemap(fout, excode=SWIGEXCODE)
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >
{
    type(C_PTR) cPtr = $imcall;
    $typemap(ftype, TYPE) ret = (cPtr == type(C_PTR).Zero) ? null : new $typemap(ftype, TYPE)(cPtr, true);$excode
        return ret;
}
%typemap(fout, excode=SWIGEXCODE) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > & {
    type(C_PTR) cPtr = $imcall;
    $typemap(ftype, TYPE) ret = (cPtr == type(C_PTR).Zero) ? null : new $typemap(ftype, TYPE)(cPtr, true);$excode
        return ret;
}
%typemap(fout, excode=SWIGEXCODE) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > * {
    type(C_PTR) cPtr = $imcall;
    $typemap(ftype, TYPE) ret = (cPtr == type(C_PTR).Zero) ? null : new $typemap(ftype, TYPE)(cPtr, true);$excode
        return ret;
}
%typemap(fout, excode=SWIGEXCODE) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > *& {
    type(C_PTR) cPtr = $imcall;
    $typemap(ftype, TYPE) ret = (cPtr == type(C_PTR).Zero) ? null : new $typemap(ftype, TYPE)(cPtr, true);$excode
        return ret;
}


%typemap(fout, excode=SWIGEXCODE) CONST TYPE {
    $typemap(ftype, TYPE) ret = new $typemap(ftype, TYPE)($imcall, true);$excode
        return ret;
}
%typemap(fout, excode=SWIGEXCODE) CONST TYPE & {
    $typemap(ftype, TYPE) ret = new $typemap(ftype, TYPE)($imcall, true);$excode
        return ret;
}
%typemap(fout, excode=SWIGEXCODE) CONST TYPE * {
    type(C_PTR) cPtr = $imcall;
    $typemap(ftype, TYPE) ret = (cPtr == type(C_PTR).Zero) ? null : new $typemap(ftype, TYPE)(cPtr, true);$excode
        return ret;
}
%typemap(fout, excode=SWIGEXCODE) TYPE *CONST& {
    type(C_PTR) cPtr = $imcall;
    $typemap(ftype, TYPE) ret = (cPtr == type(C_PTR).Zero) ? null : new $typemap(ftype, TYPE)(cPtr, true);$excode
        return ret;
}

%typemap(csvarout, excode=SWIGEXCODE2) CONST TYPE & %{
    get {
        $csclassname ret = new $csclassname($imcall, true);$excode
            return ret;
    } %}
%typemap(csvarout, excode=SWIGEXCODE2) CONST TYPE * %{
    get {
        type(C_PTR) cPtr = $imcall;
        $csclassname ret = (cPtr == type(C_PTR).Zero) ? null : new $csclassname(cPtr, true);$excode
            return ret;
    } %}

%typemap(csvarout, excode=SWIGEXCODE2) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > & %{
    get {
        type(C_PTR) cPtr = $imcall;
        $typemap(ftype, TYPE) ret = (cPtr == type(C_PTR).Zero) ? null : new $typemap(ftype, TYPE)(cPtr, true);$excode
            return ret;
    } %}
%typemap(csvarout, excode=SWIGEXCODE2) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE > * %{
    get {
        type(C_PTR) cPtr = $imcall;
        $typemap(ftype, TYPE) ret = (cPtr == type(C_PTR).Zero) ? null : new $typemap(ftype, TYPE)(cPtr, true);$excode
            return ret;
    } %}


// Proxy classes (base classes, ie, not derived classes)
%typemap(csbody) TYPE %{
    private global::System.Runtime.InteropServices.HandleRef swigCPtr;
    private bool swigCMemOwnBase;

    PTRCTOR_VISIBILITY $csclassname(type(C_PTR) cPtr, bool cMemoryOwn)
    {
        swigCMemOwnBase = cMemoryOwn;
        swigCPtr = new global::System.Runtime.InteropServices.HandleRef(this, cPtr);
    }

    CPTR_VISIBILITY static global::System.Runtime.InteropServices.HandleRef getCPtr($csclassname obj)
    {
        return (obj == null) ? new global::System.Runtime.InteropServices.HandleRef(null, type(C_PTR).Zero) : obj.swigCPtr;
    }
%}

// Derived proxy classes
%typemap(csbody_derived) TYPE %{
    private global::System.Runtime.InteropServices.HandleRef swigCPtr;
    private bool swigCMemOwnDerived;

    PTRCTOR_VISIBILITY $csclassname(type(C_PTR) cPtr, bool cMemoryOwn) : base($imclassname.$csclazznameSWIGSmartPtrUpcast(cPtr), true)
    {
        swigCMemOwnDerived = cMemoryOwn;
        swigCPtr = new global::System.Runtime.InteropServices.HandleRef(this, cPtr);
    }

    CPTR_VISIBILITY static global::System.Runtime.InteropServices.HandleRef getCPtr($csclassname obj)
    {
        return (obj == null) ? new global::System.Runtime.InteropServices.HandleRef(null, type(C_PTR).Zero) : obj.swigCPtr;
    }
%}

%typemap(csdestruct, methodname="Dispose", methodmodifiers="public") TYPE {
    lock(this)
    {
        if (swigCPtr.Handle != type(C_PTR).Zero)
        {
            if (swigCMemOwnBase)
            {
                swigCMemOwnBase = false;
                $imcall;
            }
            swigCPtr = new global::System.Runtime.InteropServices.HandleRef(null, type(C_PTR).Zero);
        }
        global::System.GC.SuppressFinalize(this);
    }
}

%typemap(csdestruct_derived, methodname="Dispose", methodmodifiers="public") TYPE {
    lock(this)
    {
        if (swigCPtr.Handle != type(C_PTR).Zero)
        {
            if (swigCMemOwnDerived)
            {
                swigCMemOwnDerived = false;
                $imcall;
            }
            swigCPtr = new global::System.Runtime.InteropServices.HandleRef(null, type(C_PTR).Zero);
        }
        global::System.GC.SuppressFinalize(this);
        base.Dispose();
    }
}
#endif

// Instantiate shared pointer
%template() SWIG_SHARED_PTR_QNAMESPACE::shared_ptr< CONST TYPE >;

%enddef

//---------------------------------------------------------------------------//
// end of fortran/boost_shared_ptr.i
//---------------------------------------------------------------------------//
