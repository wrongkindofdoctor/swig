!-----------------------------------------------------------------------------!
! \file   simple_class/test.f90
! \author Seth R Johnson
! \date   Thu Dec 01 15:07:28 2016
! \brief  test module
! \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

program main
    implicit none
    call test_simple_class_memory()
    call test_simple_class_actions()
    call test_basic_struct()
contains

subroutine test_simple_class_actions()
    use simple_class
    use ISO_C_BINDING
    implicit none
    type(SimpleClass) :: sc
    integer(C_INT) :: example

    write(0, *) "Constructing..."
    call sc%create()
    call sc%set(9)

    example = 7
    call sc%action(example)
    write(0, *) "Should be 63:", example
    call sc%release()
end subroutine

subroutine test_simple_class_memory()
    use simple_class
    use ISO_C_BINDING
    implicit none
    type(SimpleClass) :: orig
    type(SimpleClass) :: copied
    type(SimpleClass) :: assigned

    write(0, *) "Constructing..."
    call orig%create()
    call orig%set(1)

    ! Copy construct ideally
    write(0, *) "Copying class "
    copied = orig
    write(0, *) "Orig/copied: should be 12/1"
    write(0,*) "is", copied%id(), "/", orig%id()

    ! Assign to an already-created instance
    write(0, *) "Assigning"
    call assigned%create()
    call assigned%set(3)
    assigned = orig
    call orig%set(4)
    write(0, *) "Orig/assigned: should be 4/3"
    call print_value(orig)
    call print_value(assigned)

    ! Release created
    write(0, *) "Releasing orig"
    call orig%release()
    ! Release copy constructed
    write(0, *) "Releasing copied"
    call copied%release()
    ! Release assigned
    write(0, *) "Releasing assigned"
    call assigned%release()
end subroutine

subroutine test_basic_struct()
    use simple_class
    implicit none
    type(BasicStruct) :: bs
    bs%foo = 4321
    bs%bar = 1.234d0
    call print_struct(bs)
end subroutine

end program

!-----------------------------------------------------------------------------!
! end of simple_class/test.f90
!-----------------------------------------------------------------------------!
