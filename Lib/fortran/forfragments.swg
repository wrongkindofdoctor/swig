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
// CLASS WRAPPER
// TODO: add const char* for class type??
//---------------------------------------------------------------------------//
%fragment("SwigfProxyFlag_wrap", "header") %{

enum SwigfProxyFlag {
    SWIGF_UNINIT = -1,
    SWIGF_OWNER = 0,
    SWIGF_MOVING = 1,
    SWIGF_REFERENCE = 2,
    SWIGF_CONST_REFERENCE = 3
};

%}

%fragment("SwigfProxyFlag", "fpublic") %{
 enum, bind(c)
  enumerator :: SwigfProxyFlag = -1
  enumerator :: SWIGF_UNINIT = -1
  enumerator :: SWIGF_OWNER = 0
  enumerator :: SWIGF_MOVING = 1
  enumerator :: SWIGF_REFERENCE = 2
  enumerator :: SWIGF_CONST_REFERENCE = 3
 end enum
%}

#ifdef __cplusplus
%fragment("SwigfClassWrapper_wrap", "header",
          fragment="SwigfProxyFlag_wrap") %{
template<class T>
struct SwigfClassWrapper
{
    T*             ptr;
    SwigfProxyFlag flag;
};
%}
#else
// Plain C: use a void* instead of a struct
%fragment("SwigfClassWrapper_wrap", "header") %{
struct SwigfClassWrapper
{
    void*          ptr;
    SwigfProxyFlag flag;
};
%}
#endif

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered.
%fragment("SwigfClassWrapper", "fpublic",
          fragment="SwigfProxyFlag", fragment="SwigfClassWrapper_wrap",
          noblock=1) %{
type, bind(C) :: SwigfClassWrapper
  type(C_PTR), public :: ptr = C_NULL_PTR
  integer(kind(SwigfProxyFlag)), public :: flag = SWIGF_UNINIT
end type
%}

//---------------------------------------------------------------------------//
// UNKNOWN CLASS
//---------------------------------------------------------------------------//

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered.
%fragment("SwigfUnknownClass", "fpublic", noblock=1) %{
type :: SwigfUnknownClass
  type(C_PTR), public :: ptr
end type
%}

// This fragment is inserted by the fortran.cxx code when an unknown enum is
// encountered.
%fragment("SwigfUnknownEnum", "fpublic", noblock=1) %{
enum, bind(c)
  enumerator :: SwigfUnknownEnum = -1
end enum
%}

//---------------------------------------------------------------------------//
// ARRAY WRAPPER
//---------------------------------------------------------------------------//

// Add array wrapper to C++ code when used by Fortran fragment
%fragment("SwigfArrayWrapper_wrap", "header") %{
template<class T>
struct SwigfArrayWrapper
{
    T* data;
    std::size_t size;
};
%}

// Add array wrapper to Fortran types when used
%fragment("SwigfArrayWrapper", "fpublic", fragment="SwigfArrayWrapper_wrap",
          noblock="1") %{
type, bind(C) :: SwigfArrayWrapper
  type(C_PTR), public :: data
  integer(C_SIZE_T), public :: size
end type
%}

// Add function to return allocatable array from assumed-length char
%fragment("SwigfStringToCharArray", "fwrapper",
          fragment="SwigfArrayWrapper",
          noblock="1") %{
subroutine swigf_string_to_chararray(string, chars, wrap)
  use, intrinsic :: ISO_C_BINDING
  character(kind=C_CHAR, len=*), intent(IN) :: string
  character(kind=C_CHAR), dimension(:), target, allocatable, intent(OUT) :: chars
  type(SwigfArrayWrapper), intent(OUT) :: wrap 
  integer(kind=C_SIZE_T) :: i

  allocate(character(kind=C_CHAR) :: chars(len(string)))
  do i=1,size(chars)
    chars(i) = string(i:i)
  enddo
  wrap%data = c_loc(chars)
  wrap%size = size(chars)
end subroutine
%}

// Add function to return allocatable string from char array
%fragment("SwigfCharArrayToString", "fwrapper",
          fragment="SwigfArrayWrapper",
          noblock="1") %{
subroutine swigf_chararray_to_string(wrap, string)
  use, intrinsic :: ISO_C_BINDING
  type(SwigfArrayWrapper), intent(IN) :: wrap 
  character(kind=C_CHAR, len=:), allocatable, intent(OUT) :: string
  character(kind=C_CHAR), dimension(:), pointer :: chars
  integer(kind=C_SIZE_T) :: i
  call c_f_pointer(wrap%data, chars, [wrap%size])
  allocate(character(kind=C_CHAR, len=wrap%size) :: string)
  do i=1, wrap%size
    string(i:i) = chars(i)
  enddo
end subroutine
%}

//---------------------------------------------------------------------------//
// BRUTE CAST
//---------------------------------------------------------------------------//

// This fragment allows making an opaque datatype from C++ member function
// pointers (which according to the standard CANNOT be converted to a pointer).
// encountered. Its syntax is exactly like static_cast.
%fragment("SwigfBruteCast", "runtime",
          fragment="<cstring>", fragment="<cstdlib>") %{
template<typename Dst, typename Src>
void swigf_opaque_memcpy(Dst* dst, const Src* src)
{
    const std::size_t MINSIZE
        = (sizeof(dst) < sizeof(src) ? sizeof(dst) : sizeof(src));
    const std::size_t MAXSIZE
        = (sizeof(dst) > sizeof(src) ? sizeof(dst) : sizeof(src));
    std::memcpy(dst, src, MINSIZE);
    if (MAXSIZE > MINSIZE)
    {
        std::memset(static_cast<char*>(static_cast<void*>(dst)) + MINSIZE,
                    MAXSIZE - MINSIZE,
                    0);
    }
    // Otherwise should assert all the other bytes are zero?
}

namespace swig
{
template<typename Target>
class brute_cast_impl
{
  public:
    template<typename Source>
    brute_cast_impl(const Source& src_fwd)
    {
        swigf_opaque_memcpy(&d_result, &src_fwd);
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
        Source* src_ptr = &src_ref;
        swigf_opaque_memcpy(&d_result, &src_ptr);
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
} // end namespace swig

using swig::brute_cast;
%}

//---------------------------------------------------------------------------//
// MEMBER FUNCTION POINTERS
//
// We memcpy the member function pointer
//---------------------------------------------------------------------------//

// Add array wrapper to C++ code when used by Fortran fragment
%fragment("SwigfOpaqueMemFunPtr_wrap", "header") %{
struct SwigfOpaqueMemFunPtr
{
    enum { MEMPTR_SIZE = 32 };
    char data[MEMPTR_SIZE];
#if __cplusplus >= 201103L
    static_assert(sizeof(void (detail::UndefinedClass::*)()) <= MEMPTR_SIZE,
                 "Member pointer buffer isn't large enough");
#endif
};
%}

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered. Note for this to compile and not crash, MEMPTR_SIZE should
// be the same size as in SwigfOpaqueMemFunPtr. This can be accomplished by
// generating a config.h file and including it in Fortran using the C
// preprocessor.
%fragment("SwigfOpaqueMemFunPtr", "fpublic", noblock=1,
          fragment="SwigfOpaqueMemFunPtr_wrap") %{
type, public, bind(C) :: SwigfOpaqueMemFunPtr
  integer(C_SIGNED_CHAR), dimension(32), public :: data
end type
%}

//---------------------------------------------------------------------------//
// end of fortran/fragments.swg
//---------------------------------------------------------------------------//
