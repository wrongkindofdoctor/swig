!-----------------------------------------------------------------------------!
! \file   simple_class/test.f90
! \author Seth R Johnson
! \date   Thu Dec 01 15:07:28 2016
! \brief  test module
! \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

program main
    use ISO_FORTRAN_ENV

    call test_enum()
    !call test_class()

contains

subroutine test_enum()
    use simple_class
    implicit none
    call print_color(RED)
    call print_color(GREEN)
    call print_color(BLUE)
    call print_color(BLACK)
    GREEN = BLUE
    call print_color(GREEN)
!    BLACK = BLUE
!    call print_color(BLACK)
end subroutine

subroutine test_class()
    use simple_class
    implicit none
    type(SimpleClass) :: orig
    type(SimpleClass) :: made
    type(SimpleClass) :: ref
    type(BasicStruct) :: s

    write(0, *) "Constructing..."
    call orig%create()
    ! write(0, "(a, z16)") "Orig:", orig%swigptr, "Copy:", copy%swigptr
    write(0, *) "Setting..."
    call orig%set(1)
    write(0, *) "Current value ", orig%get()
    call orig%double_it()
    write(0, *) "Current value ", orig%get()
    write(0, *) "Quadrupled: ", orig%get_multiplied(4)
    call print_value(orig)
    call orig%set(1)

    ! Pass a class by value
    write(0, *) "Setting by copy"
    call set_class_by_copy(orig)
    write(0, *) "Getting by reference"
    ref = get_class()
    write(0, *) "Got", ref%get()

    ! Create
    write(0, *) "Making class "
    made = make_class(2)
    write(0, *) "printing value"
    call print_value(made)
    ! ! TODO: this should release 'orig'; maybe transfer ownership??
    write(0, *) "Assigning"
    orig = made
    ! TODO: this should release 'made'
    write(0, *) "Returning by value"
    made = make_class(3)

    ! Shouldn't do anything since we don't own
    write(0, *) "Releasing ref"
    call ref%release()
    ! Release orig
    write(0, *) "Releasing orig"
    call orig%release()
    ! Release created
    write(0, *) "Releasing ret-by-val"
    call made%release()
    write(0, *) "Done!"

    ! If this is commented out and the '-final' code generation option is used,
    ! no memory leak will occur. Otherwise, the class is never deallocated.
    ! HOWEVER, if the class construction is done in 'program main' it actually
    ! is never deallocated.
    ! ALSO: you can still call release multiple times and it will be OK.
    ! call orig%release()

    ! write(0, *) "Copying..."
    ! copy = orig
    ! ! write(0, "(a, z16)") "Orig:", orig%swigptr, "Copy:", copy%swigptr
    ! call print_value(copy)
    ! write(0, *) "Destroying..."
    ! call orig%release()
    ! write(0, *) "Double-deleting..."
    ! call copy%release()

    write(0, *) "Building struct..."
    call s%create()
    call s%set_val(4)
    write(0, *) "Values:", s%get_val()
    call s%release()
end subroutine

end program

!-----------------------------------------------------------------------------!
! end of simple_class/test.f90
!-----------------------------------------------------------------------------!
