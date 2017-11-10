//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fragments.swg
 * \author Seth R Johnson
 * \date   Sun Apr 30 10:11:28 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

// Define SWIGEXTERN for global variables: 'extern' if C++, nothing if C
%insert("runtime") %{
#ifndef SWIGEXTERN
#ifdef __cplusplus
#define SWIGEXTERN extern
#else
#define SWIGEXTERN
#endif
#endif
%}

//---------------------------------------------------------------------------//
// UNKNOWN CLASS
//---------------------------------------------------------------------------//

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered.
%fragment("SwigfUnknownClass", "fpublic", noblock=1) %{
type :: SwigfUnknownClass
  type(C_PTR), public :: swigptr
end type
%}

//---------------------------------------------------------------------------//
// ARRAY WRAPPER
//---------------------------------------------------------------------------//

// Add array wrapper to C++ code when used by Fortran fragment
%fragment("SwigfArrayWrapper_cpp", "header") %{
namespace swig {
template<class T>
struct SwigfArrayWrapper
{
    T* data;
    std::size_t size;
};
}
%}

// Add array wrapper to Fortran types when used
%fragment("SwigfArrayWrapper", "fpublic", fragment="SwigfArrayWrapper_cpp",
          noblock="1") %{
type, public, bind(C) :: SwigfArrayWrapper
  type(C_PTR), public :: data
  integer(C_SIZE_T), public :: size
end type
%}

//---------------------------------------------------------------------------//
// BRUTE CAST
//---------------------------------------------------------------------------//

// This fragment allows making an opaque datatype from C++ member function
// pointers (which according to the standard CANNOT be converted to a pointer).
// encountered. Its syntax is exactly like static_cast.
%fragment("SwigfBruteCast", "runtime",
          fragment="<cstring>") %{
namespace swig
{
template<typename Target>
class brute_cast_impl
{
  public:
    template<typename Source>
    brute_cast_impl(const Source& src_fwd)
    {
#if __cplusplus >= 201103L
        static_assert(sizeof(Source) == sizeof(Target),
                      "Incompatible sizes");
#endif
        std::memcpy(&d_result, &src_fwd, sizeof(Source));
    }

    Target operator() () const { return d_result; }

  private:
    Target d_result;
};

template<typename Target>
class brute_cast_impl<Target&>
{
  public:
    template<typename Source>
    brute_cast_impl(Source& src_ref)
    {
#if __cplusplus >= 201103L
        static_assert(sizeof(Source) == sizeof(Target),
                      "Incompatible sizes");
#endif
        Source* src_ptr = &src_ref;
        std::memcpy(&d_result, &src_ptr, sizeof(Source*));
    }

    Target& operator() () const { return *d_result; }

  private:
    Target* d_result;
};

template<class Target, class Source>
Target brute_cast(const Source& src)
{
    return brute_cast_impl<Target>(src)();
}
}

using swig::brute_cast;
%}

//---------------------------------------------------------------------------//
// MEMBER FUNCTION POINTERS
//
// NOTE: this is HIGHLY experimental. The implementation assumes that all
// member function pointers are the same size (though according to 
// https://www.codeproject.com/Articles/7150/Member-Function-Pointers-and-the-Fastest-Possible
// this is not true for some compilers!)
//---------------------------------------------------------------------------//

// Add array wrapper to C++ code when used by Fortran fragment
%fragment("SwigfOpaqueMemFunPtr_cpp", "header") %{
namespace swig {
namespace detail {
class UndefinedClass;
}

struct SwigfOpaqueMemFunPtr
{
    enum { MEMPTR_SIZE = sizeof(void (detail::UndefinedClass::*)()) };
    char data[MEMPTR_SIZE];
};
}
%}

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered. Note for this to compile and not crash, MEMPTR_SIZE should
// be the same size as in SwigfOpaqueMemFunPtr. This can be accomplished by
// generating a config.h file and including it in Fortran using the C
// preprocessor.
%fragment("SwigfOpaqueMemFunPtr", "fpublic", noblock=1,
          fragment="SwigfOpaqueMemFunPtr_cpp") %{
#ifndef MEMPTR_SIZE 16
#define MEMPTR_SIZE 16
#endif
type :: SwigfOpaqueMemFunPtr
  integer(C_SIGNED_CHAR), dimension(MEMPTR_SIZE), public :: data
end type
%}

//---------------------------------------------------------------------------//
// end of fortran/fragments.swg
//---------------------------------------------------------------------------//
