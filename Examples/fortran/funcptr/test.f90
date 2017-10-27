program test_function_args
    use funcptr
    use, intrinsic :: ISO_C_BINDING
    implicit none

    integer(C_INT) :: a = 37
    integer(C_INT) :: b = 42


    write(*,*) "Trying some C callback functions"
    write(*,*) "    a        = ", a
    write(*,*) "    b        = ", b
    write(*,*) "    ADD(a,b) = ", do_op(a,b,example.ADD)
    write(*,*) "    SUB(a,b) = ", do_op(a,b,example.SUB)
    write(*,*) "    MUL(a,b) = ", do_op(a,b,example.MUL)
    write(*,*) "    POW(a,b) = ", do_op(a,b,fortfunc)

contains
    function fortfunc(alfa, bravo) BIND(C) &
            result(fresult)
        integer(c_int), intent(in), value :: alfa
        integer(c_int), intent(in), value :: bravo
        integer(c_int) :: fresult

        fresult = alfa**bravo
    end function
end program
