//---------------------------------------------------------------------------//
// FRAGMENTS
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

