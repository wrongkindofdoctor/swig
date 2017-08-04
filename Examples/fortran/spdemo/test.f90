!-----------------------------------------------------------------------------!
! \file   spdemo/test.f90
! \author Seth R Johnson
! \date   Tue Dec 06 15:37:51 2016
! \brief  test module
! \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

program main

    use ISO_FORTRAN_ENV
    implicit none

    call test_class()

contains

subroutine test_class()
    use ISO_FORTRAN_ENV
    use spdemo, only : Foo, printfoo => print_crsp
    implicit none
    type(Foo) :: f, f2, f3

    write(0, *) "Constructing..."
    call f%create()
    write(0, *) "Setting..."
    call f%set(123.0d0)
    write(0, *) "Clone..."
    f2 = f%clone()
    call printfoo(f2)
    call f%set(234.0d0)
    write(0, *) "Original value should be 234: ", f%get()
    write(0, *) "Cloned value should be 123: ",   f2%get()
    f3 = f2%ref()
    write(0, *) "Reference to f2: ", f3%get()
    call printfoo(f3)
    call f3%set(1.0d0)
    write(0, *) "f2 should be 1: ", f2%get()
    call printfoo(f)

    write(0, *) "Release f"
    call f%release()
    write(0, *) "Release f2"
    call f2%release()
    write(0, *) "Release f3"
    call f3%release()
end subroutine

end program

!-----------------------------------------------------------------------------!
! end of spdemo/test.f90
!-----------------------------------------------------------------------------!
