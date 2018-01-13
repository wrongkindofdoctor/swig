!-----------------------------------------------------------------------------!
! \file   spdemo/test.f90
! \author Seth R Johnson
! \date   Sat Jan 13 15:54:44 2018
! \brief  Test showing that you can't avoid assignment when returning a class via a function. There is no copy elision/RVO in
! fortran.
!-----------------------------------------------------------------------------!
module test_foo
    type :: Foo
        integer :: val = 0
        logical :: assigned = .FALSE.
    contains
        procedure, private :: assign_Foo
        generic :: assignment(=) => assign_Foo
    end type

contains
    subroutine assign_Foo(self, other)
        class(Foo), intent(inout) :: self
        type(Foo), intent(in) :: other
        self%val = other%val
        self%assigned = .TRUE.
    end subroutine

    function emit_foo(val) result(res)
        integer, intent(in) :: val
        type(Foo) :: res
        res%val = val
        res%assigned = .FALSE.
    end function

    subroutine replace_foo(res, val)
        type(Foo), intent(inout) :: res
        integer, intent(in) :: val
        res%val = val
        res%assigned = .FALSE.
    end subroutine

    subroutine print_foo(varname, f)
        character(len=*), target :: varname
        type(Foo), intent(in) :: f
        write(0,*) varname, ":", f%val, f%assigned
    end subroutine

end module

program main
    call test_semantics()
contains
    subroutine test_semantics()
        use :: test_foo
        type(Foo) :: f1, f2, f3

        f1 = emit_foo(2)
        call print_foo("f1", f1)
        call replace_foo(f2, 3)
        call print_foo("f2", f2)
        f3 = f2
        call print_foo("f3", f3)

    end subroutine
end program

!-----------------------------------------------------------------------------!
! end of spdemo/test.f90
!-----------------------------------------------------------------------------!
