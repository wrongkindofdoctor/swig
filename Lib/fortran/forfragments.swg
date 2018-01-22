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
//---------------------------------------------------------------------------//
// Memory state enumeration
//---------------------------------------------------------------------------//
%fragment("SwigfMemState_wrap", "header") %{

enum SwigfMemState {
    SWIGF_NULL = 0,
    SWIGF_OWN,
    SWIGF_MOVE,
    SWIGF_REF,
    SWIGF_CREF
};

const char* const swigf_mem_state_strings[]
  = {"NULL", "OWN", "MOVE", "REF", "CREF"};

%}

%fragment("SwigfMemState", "fpublic") %{
 enum, bind(c)
  enumerator :: SwigfMemState = -1
  enumerator :: SWIGF_NULL = 0
  enumerator :: SWIGF_OWN
  enumerator :: SWIGF_MOVE
  enumerator :: SWIGF_REF
  enumerator :: SWIGF_CREF
 end enum
%}

//---------------------------------------------------------------------------//
// Wrapper struct that holds a C pointer and memory state
//---------------------------------------------------------------------------//

%fragment("SwigfClassWrapper_wrap", "header",
          fragment="SwigfMemState_wrap") %{
struct SwigfClassWrapper
{
    void* ptr;
    SwigfMemState mem;
};

SwigfClassWrapper SwigfClassWrapper_uninitialized()
{
    SwigfClassWrapper result;
    result.ptr = NULL;
    result.mem = SWIGF_NULL;
    return result;
}
%}

// Fortran declaration of the class wrapper above. Note that we declare the
// enum as a C_INT instead of `integer(kind(SwigfMemState))` to avoid a warning
// in GCC. The types will still be interoperable.
%fragment("SwigfClassWrapper", "fpublic",
          fragment="SwigfMemState", noblock=1) %{
type, bind(C) :: SwigfClassWrapper
  type(C_PTR), public :: ptr = C_NULL_PTR
  integer(C_INT), public :: mem = SWIGF_NULL
end type
%}

//---------------------------------------------------------------------------//
// Runtime check for mutable argument
//---------------------------------------------------------------------------//

// Runtime check for a class wrapper not being const.
%fragment("SwigfCheckMutable", "runtime")
%{
#define SWIGF_check_mutable(SWIGF_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL) \
    if ((SWIGF_CLASS_WRAPPER).mem == SWIGF_CREF) { \
        SWIG_exception_impl(SWIG_TypeError, \
            "Cannot pass const " TYPENAME " (class " FNAME ") " \
            "to a function (" FUNCNAME ") that requires a mutable reference", \
            RETURNNULL); \
    }
%}

// Runtime check for a class wrapper not being const.
%fragment("SwigfCheckNonnull", "runtime")
%{
#define SWIGF_check_nonnull(SWIGF_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL) \
    if ((SWIGF_CLASS_WRAPPER).mem == SWIGF_NULL) { \
        SWIG_exception_impl(SWIG_TypeError, \
            "Cannot pass null " TYPENAME " (class " FNAME ") " \
            "to function (" FUNCNAME ")", RETURNNULL); \
    }
%}

%fragment("SwigfCheckMutableNonnull", "runtime",
          fragment="SwigfCheckMutable", fragment="SwigfCheckNonnull")
%{
#define SWIGF_check_mutable_nonnull(SWIGF_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL) \
    SWIGF_check_nonnull(SWIGF_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL); \
    SWIGF_check_mutable(SWIGF_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL);
%}

//---------------------------------------------------------------------------//
// Assignment: C++ and C++11 implementation
//---------------------------------------------------------------------------//

#ifdef __cplusplus

// Optional "std::move" support if using C++11
%fragment("SwigfStdMove", "header", fragment="<utility>")
%{
namespace swigf {

enum AssignmentFlags {
  IS_COPY_CONSTR = 0x1,
  IS_COPY_ASSIGN = 0x2,
  IS_MOVE_CONSTR = 0x4,
  IS_MOVE_ASSIGN = 0x8
};

// Define our own switching struct to support pre-c++11 builds
template<bool Val>
struct bool_constant {};
typedef bool_constant<true>  true_type;
typedef bool_constant<false> false_type;

// Copy construction and assignment
template<class T, class U>
T* copy_construct_impl(const U* other, true_type) {
  return new T(*other);
}
template<class T, class U>
void copy_assign_impl(T* self, const U* other, true_type) {
  *self = *other;
}

// Disabled construction and assignment
template<class T, class U>
T* copy_construct_impl(const U* , false_type) {
  SWIG_exception_impl(SWIG_TypeError,
                      "Invalid assignment: class type has no copy constructor",
                      return NULL);
}
template<class T, class U>
void copy_assign_impl(T* , const U* , false_type) {
  SWIG_exception_impl(SWIG_TypeError,
                      "Invalid assignment: class type has no copy assignment",
                      return);
}

#if __cplusplus >= 201103L
#include <utility>
#include <type_traits>

// Move construction and assignment
template<class T, class U>
T* move_construct_impl(U* other, true_type) {
  return new T(std::move(*other));
}
template<class T, class U>
void move_assign_impl(T* self, U* other, true_type) {
  *self = std::move(*other);
}

// Disabled move construction and assignment
template<class T, class U>
T* move_construct_impl(U*, false_type) {
  SWIG_exception_impl(SWIG_TypeError,
                      "Invalid assignment: class type has no move constructor",
                      return NULL);
}
template<class T, class U>
void move_assign_impl(T*, U*, false_type) {
  SWIG_exception_impl(SWIG_TypeError,
                      "Invalid assignment: class type has no move assignment",
                      return);
}

template<class T>
constexpr int assignment_flags() {
  return   (std::is_copy_constructible<T>::value ? IS_COPY_CONSTR : 0)
         | (std::is_copy_assignable<T>::value    ? IS_COPY_ASSIGN : 0)
         | (std::is_move_constructible<T>::value ? IS_MOVE_CONSTR : 0)
         | (std::is_move_assignable<T>::value    ? IS_MOVE_ASSIGN : 0);
}
#endif

template<class T, int Flags>
struct AssignmentTraits
{
  template<class U>
  static T* copy_construct(const U* other)
  {
    return copy_construct_impl<T,U>(other,
                                    bool_constant<Flags & IS_COPY_CONSTR>());
  }

  template<class U>
  static void copy_assign(T* self, const U* other)
  {
    return copy_assign_impl<T,U>(self, other,
                                 bool_constant<Flags & IS_COPY_ASSIGN>());
  }

#if __cplusplus >= 201103L
  template<class U>
  static T* move_construct(U* other)
  {
    return move_construct_impl<T,U>(other,
                                    bool_constant<Flags & IS_MOVE_CONSTR>());
  }
  template<class U>
  static void move_assign(T* self, U* other)
  {
    return move_assign_impl<T,U>(self, other,
                                 bool_constant<Flags & IS_MOVE_ASSIGN>());
  }
#else
  template<class U>
  static T* move_construct(U* other)
  {
    return copy_construct_impl<T,U>(other,
                                    bool_constant<Flags & IS_COPY_CONSTR>());
  }
  template<class U>
  static void move_assign(T* self, U* other)
  {
    return copy_assign_impl<T,U>(self, other,
                                 bool_constant<Flags & IS_COPY_ASSIGN>());
  }
#endif
};

} // end namespace swigf    
%}

%fragment("SwigfClassAssign_wrap", "header",
          fragment="SwigfClassWrapper_wrap", fragment="SwigfStdMove") %{

template<class T1, class T2, int AFlags>
void SwigfAssign(SwigfClassWrapper* self, SwigfClassWrapper* other) {
  typedef swigf::AssignmentTraits<T1, AFlags> Traits_t;
  T1* pself  = static_cast<T1*>(self->ptr);
  T2* pother = static_cast<T2*>(other->ptr);

  switch (self->mem) {
    case SWIGF_NULL:
      /* LHS is unassigned */
      switch (other->mem) {
        case SWIGF_NULL: /* null op */ break;
        case SWIGF_MOVE: /* capture pointer from RHS */
          self->ptr = other->ptr;
          other->ptr = NULL;
          self->mem = SWIGF_OWN;
          other->mem = SWIGF_NULL;
          break;
        case SWIGF_OWN: /* copy from RHS */
          self->ptr = Traits_t::copy_construct(pother);
          self->mem = SWIGF_OWN;
          break;
        case SWIGF_REF: /* pointer to RHS */
        case SWIGF_CREF:
          self->ptr = other->ptr;
          self->mem = other->mem;
          break;
      }
      break;
    case SWIGF_OWN:
      /* LHS owns memory */
      switch (other->mem) {
        case SWIGF_NULL:
          /* Delete LHS */
          delete pself;
          self->ptr = NULL;
          self->mem = SWIGF_NULL;
          break;
        case SWIGF_MOVE:
          /* Move RHS into LHS; delete RHS */
          Traits_t::move_assign(pself, pother);
          delete pother;
          other->ptr = NULL;
          other->mem = SWIGF_NULL;
          break;
        case SWIGF_OWN:
        case SWIGF_REF:
        case SWIGF_CREF:
          /* Copy RHS to LHS */
          Traits_t::copy_assign(pself, pother);
          break;
      }
      break;
    case SWIGF_MOVE:
      SWIG_exception_impl(SWIG_RuntimeError,
        "Left-hand side of assignment should never be in a 'MOVE' state",
        return);
      break;
    case SWIGF_REF:
      /* LHS is a reference */
      switch (other->mem) {
        case SWIGF_NULL:
          /* Remove LHS reference */
          self->ptr = NULL;
          self->mem = SWIGF_NULL;
          break;
        case SWIGF_MOVE:
          /* Move RHS into LHS; delete RHS. The original ownership stays the
           * same. */
          Traits_t::move_assign(pself, pother);
          delete pother;
          other->ptr = NULL;
          other->mem = SWIGF_NULL;
          break;
        case SWIGF_OWN:
        case SWIGF_REF:
        case SWIGF_CREF:
          /* Copy RHS to LHS */
          Traits_t::copy_assign(pself, pother);
          break;
      }
    case SWIGF_CREF:
      switch (other->mem) {
        case SWIGF_NULL:
          /* Remove LHS reference */
          self->ptr = NULL;
          self->mem = SWIGF_NULL;
        default:
          SWIG_exception_impl(SWIG_RuntimeError,
              "Cannot assign to a const reference", return);
          break;
      }
  }
}
%}

// Assignment: left = right
%fragment("SwigfClassAssign", "runtime",
          fragment="SwigfClassAssign_wrap") %{

#if __cplusplus >= 201103L
#define SWIGF_assign(LEFTTYPE, LEFT, RIGHTTYPE, RIGHT, FLAGS) \
    SwigfAssign<LEFTTYPE , RIGHTTYPE, swigf::assignment_flags<LEFTTYPE >() >( \
            LEFT, RIGHT);
#else
#define SWIGF_assign(LEFTTYPE, LEFT, RIGHTTYPE, RIGHT, FLAGS) \
    SwigfAssign<LEFTTYPE , RIGHTTYPE, FLAGS >(LEFT, RIGHT);
#endif

%}

//---------------------------------------------------------------------------//
// Assignment: C implementation
//---------------------------------------------------------------------------//
#else

%fragment("SwigfClassAssign_wrap", "header",
          fragment="SwigfClassWrapper_wrap", "<stddef.h>") %{
void SwigfAssign(SwigfClassWrapper* self, SwigfClassWrapper* other,
                 size_t size)
{
    // XXX TODO: memcpy
  assert(0);
}

// Assignment: left = right. TODO: check that left and right are the same type?
// (or at least the same size)
%fragment("SwigfClassAssign", "runtime",
          fragment="SwigfClassAssign_wrap") %{
#define SWIGF_assign(LEFTTYPE, LEFT, RIGHTTYPE, RIGHT) \
    SwigfAssign(LEFT, sizeof(LEFTTYPE), RIGHT);
%}


#endif

//---------------------------------------------------------------------------//
// UNKNOWN CLASS
//---------------------------------------------------------------------------//

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered.
%fragment("SwigfUnknownClass", "fpublic", noblock=1,
          fragment="SwigfClassWrapper") %{
type :: SwigfUnknownClass
  type(SwigfClassWrapper), public :: swigdata
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
// Note that the <cstring> fragment imports size_t into the global namespace.
%fragment("SwigfBruteCast", "runtime",
          fragment="<cstring>") %{
template<typename Dst, typename Src>
void swigf_opaque_memcpy(Dst* dst, const Src* src)
{
    const size_t MINSIZE
        = (sizeof(dst) < sizeof(src) ? sizeof(dst) : sizeof(src));
    const size_t MAXSIZE
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
%fragment("SwigfOpaqueMemFunPtr_wrap", "header", fragment="<cstring>") %{
struct SwigfOpaqueMemFunPtr
{
    enum { MEMPTR_SIZE = 32 };
    char data[MEMPTR_SIZE];
#if __cplusplus >= 201103L
    static_assert(sizeof(void (detail::UndefinedClass::*)()) <= MEMPTR_SIZE,
                 "Member pointer buffer isn't large enough");
#endif
};

SwigfOpaqueMemFunPtr SwigfOpaqueMemFunPtr_uninitialized()
{
    SwigfOpaqueMemFunPtr result;
    std::memset(result.data, sizeof(result.data), 0);
    return result;
}
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
