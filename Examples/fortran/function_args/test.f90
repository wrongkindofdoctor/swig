#define ASSERT(conditional) \
if (.not. conditional) then; \
  stop 1; \
endif

module x
  use, intrinsic :: ISO_C_BINDING
  implicit none
contains
  function f(i) BIND(C) &
      result(fresult)
    integer(c_int), intent(in), value :: i
    integer(c_int) :: fresult

    fresult = 10*i
  end function
end module x

program test_function_args
  use function_args
  use x
  use, intrinsic :: ISO_C_BINDING
  implicit none

  integer(C_INT) :: i

  ASSERT(gcd(i, C_FUNLOC(f)) == i + f(i))

end program
