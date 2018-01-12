!-----------------------------------------------------------------------------!
! \file   simple_class/test.f90
! \author Seth R Johnson
! \date   Thu Dec 01 15:07:28 2016
! \brief  test module
! \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

program main
    use ISO_FORTRAN_ENV

    call test_class()

contains

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
    ! TODO: this should release existing 'made'
    write(0, *) "Returning by value"
    made = make_class(3)

    ! TODO Should be able to call ref%release (a reference to the global
    ! variable g_globalclass) without consequence.
    !! write(0, *) "Releasing ref"
    !! call ref%release()

    ! TODO: the class pointed to by 'orig' is already deleted because of 
    ! Release orig 
    ! write(0, *) "Releasing orig"
    ! call orig%release()
    
    ! Release created
    write(0, *) "Releasing ret-by-val"
    call made%release()
    write(0, *) "Done!"

    write(0, *) "Building struct..."
    s%foo = 4
    s%bar = 9.11d0
    call print_struct(s)
end subroutine

end program

!-----------------------------------------------------------------------------!
! end of simple_class/test.f90
!-----------------------------------------------------------------------------!
