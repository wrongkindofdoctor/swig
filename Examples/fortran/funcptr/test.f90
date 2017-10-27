program test_function_args
    use funcptr
    use, intrinsic :: ISO_C_BINDING
    implicit none

    integer(C_INT) :: a = 4
    integer(C_INT) :: b = 3


    write(*,*) "Trying some C callback functions"
    write(*,*) "    a        = ", a
    write(*,*) "    b        = ", b
!    write(*,*) "    ADD(a,b) = ", do_op(a,b,c_funloc(add))
!    write(*,*) "    SUB(a,b) = ", do_op(a,b,c_funloc(sub))
!    write(*,*) "    MUL(a,b) = ", do_op(a,b,c_funloc(mul))
    write(*,*) "    POW(a,b) = ", do_op(a,b,c_funloc(fortfunc))

contains
    function fortfunc(alfa, bravo) BIND(C) &
            result(fresult)
        integer(c_int), intent(in), value :: alfa
        integer(c_int), intent(in), value :: bravo
        integer(c_int) :: fresult

        fresult = alfa**bravo
    end function
end program
