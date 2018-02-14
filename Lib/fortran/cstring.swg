
%include <typemaps/fragments.swg>

//---------------------------------------------------------------------------//
// STRING CONVERSION
//---------------------------------------------------------------------------//
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


