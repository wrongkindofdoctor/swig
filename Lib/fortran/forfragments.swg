//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fragments.swg
 * \author Seth R Johnson
 * \date   Sun Apr 30 10:11:28 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

// Define SWIGEXTERN for *const* global data variables: 'extern' if C++,
// nothing if C.
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
%fragment("SwigMemState", "header") %{
enum SwigMemState {
    SWIG_NULL = 0,
    SWIG_OWN,
    SWIG_MOVE,
    SWIG_REF,
    SWIG_CREF
};
%}

%fragment("SwigMemState_f", "fpublic") %{
 enum, bind(c)
  enumerator :: SwigMemState = -1
  enumerator :: SWIG_NULL = 0
  enumerator :: SWIG_OWN
  enumerator :: SWIG_MOVE
  enumerator :: SWIG_REF
  enumerator :: SWIG_CREF
 end enum
%}

//---------------------------------------------------------------------------//
// Wrapper struct that holds a C pointer and memory state
//---------------------------------------------------------------------------//

%fragment("SwigClassWrapper", "header",
          fragment="SwigMemState") %{
struct SwigClassWrapper
{
    void* ptr;
    SwigMemState mem;
};

SWIGINTERN SwigClassWrapper SwigClassWrapper_uninitialized()
{
    SwigClassWrapper result;
    result.ptr = NULL;
    result.mem = SWIG_NULL;
    return result;
}
%}

// Fortran declaration of the class wrapper above. Note that we declare the
// enum as a C_INT instead of `integer(kind(SwigMemState))` to avoid a warning
// in GCC. The types will still be interoperable.
%fragment("SwigClassWrapper_f", "fpublic",
          fragment="SwigMemState_f", noblock=1) %{
type, bind(C) :: SwigClassWrapper
  type(C_PTR), public :: ptr = C_NULL_PTR
  integer(C_INT), public :: mem = SWIG_NULL
end type
%}

//---------------------------------------------------------------------------//
// Runtime check for mutable argument
//---------------------------------------------------------------------------//

// Runtime check for a class wrapper not being const.
%fragment("SWIG_check_mutable", "runtime")
%{
#define SWIG_check_mutable(SWIG_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL) \
    if ((SWIG_CLASS_WRAPPER).mem == SWIG_CREF) { \
        SWIG_exception_impl(FUNCNAME, SWIG_TypeError, \
            "Cannot pass const " TYPENAME " (class " FNAME ") " \
            "as a mutable reference", \
            RETURNNULL); \
    }
%}

// Runtime check for a class wrapper not being const.
%fragment("SWIG_check_nonnull", "runtime")
%{
#define SWIG_check_nonnull(SWIG_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL) \
    if ((SWIG_CLASS_WRAPPER).mem == SWIG_NULL) { \
        SWIG_exception_impl(FUNCNAME, SWIG_TypeError, \
            "Cannot pass null " TYPENAME " (class " FNAME ") " \
            "as a reference", RETURNNULL); \
    }
%}

%fragment("SWIG_check_mutable_nonnull", "runtime",
          fragment="SWIG_check_mutable", fragment="SWIG_check_nonnull")
%{
#define SWIG_check_mutable_nonnull(SWIG_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL) \
    SWIG_check_nonnull(SWIG_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL); \
    SWIG_check_mutable(SWIG_CLASS_WRAPPER, TYPENAME, FNAME, FUNCNAME, RETURNNULL);
%}

//---------------------------------------------------------------------------//
// Assignment: C++ and C++11 implementation
//---------------------------------------------------------------------------//

#ifdef __cplusplus

// Optional "std::move" support if using C++11
%fragment("swig::AssignmentTraits", "header", fragment="<utility>")
%{
namespace swig {

enum AssignmentFlags {
  IS_DESTR       = 0x01,
  IS_COPY_CONSTR = 0x02,
  IS_COPY_ASSIGN = 0x04,
  IS_MOVE_CONSTR = 0x08,
  IS_MOVE_ASSIGN = 0x10
};

// Define our own switching struct to support pre-c++11 builds
template<bool Val>
struct bool_constant {};
typedef bool_constant<true>  true_type;
typedef bool_constant<false> false_type;

// Deletion
template<class T>
SWIGINTERN void destruct_impl(T* self, true_type) {
  delete self;
}
template<class T>
SWIGINTERN T* destruct_impl(T* , false_type) {
  SWIG_exception_impl("assignment", SWIG_TypeError,
                      "Invalid assignment: class type has no destructor",
                      return NULL);
}

// Copy construction and assignment
template<class T, class U>
SWIGINTERN T* copy_construct_impl(const U* other, true_type) {
  return new T(*other);
}
template<class T, class U>
SWIGINTERN void copy_assign_impl(T* self, const U* other, true_type) {
  *self = *other;
}

// Disabled construction and assignment
template<class T, class U>
SWIGINTERN T* copy_construct_impl(const U* , false_type) {
  SWIG_exception_impl("assignment", SWIG_TypeError,
                      "Invalid assignment: class type has no copy constructor",
                      return NULL);
}
template<class T, class U>
SWIGINTERN void copy_assign_impl(T* , const U* , false_type) {
  SWIG_exception_impl("assignment", SWIG_TypeError,
                      "Invalid assignment: class type has no copy assignment",
                      return);
}

#if __cplusplus >= 201103L
#include <utility>
#include <type_traits>

// Move construction and assignment
template<class T, class U>
SWIGINTERN T* move_construct_impl(U* other, true_type) {
  return new T(std::move(*other));
}
template<class T, class U>
SWIGINTERN void move_assign_impl(T* self, U* other, true_type) {
  *self = std::move(*other);
}

// Disabled move construction and assignment
template<class T, class U>
SWIGINTERN T* move_construct_impl(U*, false_type) {
  SWIG_exception_impl("assignment", SWIG_TypeError,
                      "Invalid assignment: class type has no move constructor",
                      return NULL);
}
template<class T, class U>
SWIGINTERN void move_assign_impl(T*, U*, false_type) {
  SWIG_exception_impl("assignment", SWIG_TypeError,
                      "Invalid assignment: class type has no move assignment",
                      return);
}

template<class T>
constexpr int assignment_flags() {
  return   (std::is_destructible<T>::value       ? IS_DESTR       : 0)
         | (std::is_copy_constructible<T>::value ? IS_COPY_CONSTR : 0)
         | (std::is_copy_assignable<T>::value    ? IS_COPY_ASSIGN : 0)
         | (std::is_move_constructible<T>::value ? IS_MOVE_CONSTR : 0)
         | (std::is_move_assignable<T>::value    ? IS_MOVE_ASSIGN : 0);
}
#endif

template<class T, int Flags>
struct AssignmentTraits
{
  static void destruct(T* self)
  {
    destruct_impl<T>(self, bool_constant<Flags & IS_DESTR>());
  }

  template<class U>
  static T* copy_construct(const U* other)
  {
    return copy_construct_impl<T,U>(other, bool_constant<bool(Flags & IS_COPY_CONSTR)>());
  }

  template<class U>
  static void copy_assign(T* self, const U* other)
  {
    copy_assign_impl<T,U>(self, other, bool_constant<bool(Flags & IS_COPY_ASSIGN)>());
  }

#if __cplusplus >= 201103L
  template<class U>
  static T* move_construct(U* other)
  {
    return move_construct_impl<T,U>(other, bool_constant<bool(Flags & IS_MOVE_CONSTR)>());
  }
  template<class U>
  static void move_assign(T* self, U* other)
  {
    move_assign_impl<T,U>(self, other, bool_constant<bool(Flags & IS_MOVE_ASSIGN)>());
  }
#else
  template<class U>
  static T* move_construct(U* other)
  {
    return copy_construct_impl<T,U>(other, bool_constant<bool(Flags & IS_COPY_CONSTR)>());
  }
  template<class U>
  static void move_assign(T* self, U* other)
  {
    copy_assign_impl<T,U>(self, other, bool_constant<bool(Flags & IS_COPY_ASSIGN)>());
  }
#endif
};

} // end namespace swig
%}

%fragment("SWIG_assign_impl", "header",
          fragment="SwigClassWrapper", fragment="swig::AssignmentTraits") %{

template<class T1, class T2, int AFlags>
SWIGINTERN void SWIG_assign_impl(SwigClassWrapper* self, SwigClassWrapper* other) {
  typedef swig::AssignmentTraits<T1, AFlags> Traits_t;
  T1* pself  = static_cast<T1*>(self->ptr);
  T2* pother = static_cast<T2*>(other->ptr);

  switch (self->mem) {
    case SWIG_NULL:
      /* LHS is unassigned */
      switch (other->mem) {
        case SWIG_NULL: /* null op */ break;
        case SWIG_MOVE: /* capture pointer from RHS */
          self->ptr = other->ptr;
          other->ptr = NULL;
          self->mem = SWIG_OWN;
          other->mem = SWIG_NULL;
          break;
        case SWIG_OWN: /* copy from RHS */
          self->ptr = Traits_t::copy_construct(pother);
          self->mem = SWIG_OWN;
          break;
        case SWIG_REF: /* pointer to RHS */
        case SWIG_CREF:
          self->ptr = other->ptr;
          self->mem = other->mem;
          break;
      }
      break;
    case SWIG_OWN:
      /* LHS owns memory */
      switch (other->mem) {
        case SWIG_NULL:
          /* Delete LHS */
          Traits_t::destruct(pself);
          self->ptr = NULL;
          self->mem = SWIG_NULL;
          break;
        case SWIG_MOVE:
          /* Move RHS into LHS; delete RHS */
          Traits_t::move_assign(pself, pother);
          Traits_t::destruct(pother);
          other->ptr = NULL;
          other->mem = SWIG_NULL;
          break;
        case SWIG_OWN:
        case SWIG_REF:
        case SWIG_CREF:
          /* Copy RHS to LHS */
          Traits_t::copy_assign(pself, pother);
          break;
      }
      break;
    case SWIG_MOVE:
      SWIG_exception_impl("assignment", SWIG_RuntimeError,
        "Left-hand side of assignment should never be in a 'MOVE' state",
        return);
      break;
    case SWIG_REF:
      /* LHS is a reference */
      switch (other->mem) {
        case SWIG_NULL:
          /* Remove LHS reference */
          self->ptr = NULL;
          self->mem = SWIG_NULL;
          break;
        case SWIG_MOVE:
          /* Move RHS into LHS; delete RHS. The original ownership stays the
           * same. */
          Traits_t::move_assign(pself, pother);
          Traits_t::destruct(pother);
          other->ptr = NULL;
          other->mem = SWIG_NULL;
          break;
        case SWIG_OWN:
        case SWIG_REF:
        case SWIG_CREF:
          /* Copy RHS to LHS */
          Traits_t::copy_assign(pself, pother);
          break;
      }
    case SWIG_CREF:
      switch (other->mem) {
        case SWIG_NULL:
          /* Remove LHS reference */
          self->ptr = NULL;
          self->mem = SWIG_NULL;
        default:
          SWIG_exception_impl("assignment", SWIG_RuntimeError,
              "Cannot assign to a const reference", return);
          break;
      }
  }
}
%}

// Assignment: left = right
%fragment("SWIG_assign", "runtime",
          fragment="SWIG_assign_impl") %{

#if __cplusplus >= 201103L
#define SWIG_assign(LEFTTYPE, LEFT, RIGHTTYPE, RIGHT, FLAGS) \
    SWIG_assign_impl<LEFTTYPE , RIGHTTYPE, swig::assignment_flags<LEFTTYPE >() >( \
            LEFT, RIGHT);
#else
#define SWIG_assign(LEFTTYPE, LEFT, RIGHTTYPE, RIGHT, FLAGS) \
    SWIG_assign_impl<LEFTTYPE , RIGHTTYPE, FLAGS >(LEFT, RIGHT);
#endif

%}

//---------------------------------------------------------------------------//
// Assignment: C implementation
//---------------------------------------------------------------------------//
#else

%fragment("SWIG_assign_impl", "header",
          fragment="SwigClassWrapper", "<stddef.h>") %{
SWIGINTERN void SWIG_assign_impl(SwigClassWrapper* self, SwigClassWrapper* other,
                 size_t size)
{
    // XXX TODO: memcpy
  assert(0);
}

// Assignment: left = right. TODO: check that left and right are the same type?
// (or at least the same size)
%fragment("SWIG_assign", "runtime",
          fragment="SWIG_assign_impl") %{
#define SWIG_assign(LEFTTYPE, LEFT, RIGHTTYPE, RIGHT) \
    SWIG_assign_impl(LEFT, sizeof(LEFTTYPE), RIGHT);
%}


#endif

//---------------------------------------------------------------------------//
// UNKNOWN CLASS
//---------------------------------------------------------------------------//

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered.
%fragment("SwigUnknownClass_f", "fpublic", noblock=1,
          fragment="SwigClassWrapper_f") %{
type :: SwigUnknownClass
  type(SwigClassWrapper), public :: swigdata
end type
%}

// This fragment is inserted by the fortran.cxx code when an unknown enum is
// encountered.
%fragment("SwigUnknownEnum_f", "fpublic", noblock=1) %{
enum, bind(c)
  enumerator :: SwigUnknownEnum = -1
end enum
%}

//---------------------------------------------------------------------------//
// ARRAY WRAPPER
//---------------------------------------------------------------------------//

// Add array wrapper to C++ code when used by Fortran fragment
%fragment("SwigArrayWrapper", "header") %{
struct SwigArrayWrapper
{
    void* data;
    std::size_t size;
};

SWIGINTERN SwigArrayWrapper SwigArrayWrapper_uninitialized()
{
    SwigArrayWrapper result;
    result.data = NULL;
    result.size = 0;
    return result;
}
%}

// Add array wrapper to Fortran types when used
%fragment("SwigArrayWrapper_f", "fpublic",
          noblock="1") %{
type, bind(C) :: SwigArrayWrapper
  type(C_PTR), public :: data = C_NULL_PTR
  integer(C_SIZE_T), public :: size = 0
end type
%}

// Add function to return allocatable array from assumed-length char
%fragment("SWIG_string_to_chararray_f", "fwrapper",
          fragment="SwigArrayWrapper_f",
          noblock="1") %{
subroutine swig_string_to_chararray(string, chars, wrap)
  use, intrinsic :: ISO_C_BINDING
  character(kind=C_CHAR, len=*), intent(IN) :: string
  character(kind=C_CHAR), dimension(:), target, allocatable, intent(OUT) :: chars
  type(SwigArrayWrapper), intent(OUT) :: wrap
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
%fragment("SWIG_chararray_to_string_f", "fwrapper",
          fragment="SwigArrayWrapper_f",
          noblock="1") %{
subroutine SWIG_chararray_to_string(wrap, string)
  use, intrinsic :: ISO_C_BINDING
  type(SwigArrayWrapper), intent(IN) :: wrap
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

// Add function to return allocatable string from char array
%fragment("SWIG_restore_chararray_f", "fwrapper",
          fragment="SwigArrayWrapper_f",
          noblock="1") %{
subroutine SWIG_restore_chararray(chars, string)
  use, intrinsic :: ISO_C_BINDING
  character(kind=C_CHAR), dimension(:), intent(IN) :: chars
  character(kind=C_CHAR, len=*), intent(OUT) :: string
  integer(kind=C_SIZE_T) :: i
  do i=1, len(string)
    string(i:i) = chars(i)
  enddo
end subroutine
%}

// Add function to convert Fortran logical values to C-bound integers
%fragment("SWIG_logical_to_int_f", "fwrapper",
          noblock="1") %{
function SWIG_logical_to_int(inp) &
    result(out)
  use, intrinsic :: ISO_C_BINDING
  logical, intent(IN) :: inp
  integer(kind=C_INT) :: out
  if (inp .eqv. .true.) then
    out = 1
  else
    out = 0
  end if
end function
%}

// Add function to convert Fortran logical values to C-bound integers
%fragment("SWIG_int_to_logical_f", "fwrapper",
          noblock="1") %{
function SWIG_int_to_logical(inp) &
    result(out)
  use, intrinsic :: ISO_C_BINDING
  integer(kind=C_INT), intent(IN) :: inp
  logical :: out
  if (inp /= 0) then
    out = .true.
  else
    out = .false.
  end if
end function
%}

//---------------------------------------------------------------------------//
// BRUTE CAST
//---------------------------------------------------------------------------//

// This fragment allows making an opaque datatype from C++ member function
// pointers (which according to the standard CANNOT be converted to a pointer).
// encountered. Its syntax is exactly like static_cast.
// Note that the <cstring> fragment imports size_t into the global namespace.
%fragment("swig::brute_cast", "runtime",
          fragment="<cstring>") %{
template<typename Dst, typename Src>
SWIGINTERN void SWIG_opaque_memcpy(Dst* dst, const Src* src)
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
        SWIG_opaque_memcpy(&d_result, &src_fwd);
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
        SWIG_opaque_memcpy(&d_result, &src_ptr);
    }

    Target& operator() () const { return *d_result; }

  private:
    Target* d_result;
};

template<class Target, class Source>
SWIGINTERN Target brute_cast(const Source& src)
{
    return brute_cast_impl<Target>(src)();
}
} // end namespace swig

using swig::brute_cast;
%}

//---------------------------------------------------------------------------//
// MEMBER FUNCTION POINTERS
//
// We memcpy the member function pointer to an opaque data class using
// brute_cast.
//---------------------------------------------------------------------------//

// Add array wrapper to C++ code when used by Fortran fragment
%fragment("SwigOpaqueMemFunPtr", "header", fragment="<cstring>") %{
struct SwigOpaqueMemFunPtr
{
    enum { MEMPTR_SIZE = 32 };
    char data[MEMPTR_SIZE];
#if __cplusplus >= 201103L
    static_assert(sizeof(void (detail::UndefinedClass::*)()) <= MEMPTR_SIZE,
                 "Member pointer buffer isn't large enough");
#endif
};

SWIGINTERN SwigOpaqueMemFunPtr SwigOpaqueMemFunPtr_uninitialized()
{
    SwigOpaqueMemFunPtr result;
    std::memset(result.data, sizeof(result.data), 0);
    return result;
}
%}

// This fragment is inserted by the fortran.cxx code when an unknown class is
// encountered. Note for this to compile and not crash, the size of 'data' should
// be the same size as in SwigOpaqueMemFunPtr. This can be accomplished more
// elegantly by  generating a config.h file and including it in Fortran using
// the C preprocessor.
%fragment("SwigOpaqueMemFunPtr_f", "fpublic", noblock=1,
          fragment="SwigOpaqueMemFunPtr") %{
type, public, bind(C) :: SwigOpaqueMemFunPtr
  integer(C_SIGNED_CHAR), dimension(32), public :: data
end type
%}

//---------------------------------------------------------------------------//
// STRING CONVERSION
//---------------------------------------------------------------------------//

// When returning a std::string by value, store it in this temporary memory
// space so that it's still allocated when the Fortran wrapper code converts it.
%fragment("SWIG_store_string", "header", fragment="SwigArrayWrapper",
          fragment="<string>") %{

SWIGINTERN SwigArrayWrapper SWIG_store_string(const std::string& str)
{
    static std::string* temp = NULL;
    SwigArrayWrapper result;
    if (str.empty())
    {
        // Result is empty
        result.data = NULL;
        result.size = 0;
    }
    else
    {
        if (!temp)
        {
            // Allocate a new temporary string
            temp = new std::string(str);
        }
        else
        {
            // Assign the string
            *temp = str;
        }
        result.data = &(*(temp->begin()));
        result.size = temp->size();
    }
    return result;
}
%}

//---------------------------------------------------------------------------//
// end of fortran/fragments.swg
//---------------------------------------------------------------------------//
