!
! M P F R _ M O D . F 9 0
!
! mpfr_mod.f90 last edited on Fri Feb 13 22:40:59 2026 
!

module mpfr_mod
  use iso_c_binding
  implicit none

  integer(c_int), parameter :: RND = 0   ! MPFR_RNDN

  type, bind(C) :: mpfr_t
     integer(c_long) :: limbs(4)
  end type mpfr_t

  type :: mpfr_real
     type(mpfr_t) :: v
  end type mpfr_real

  interface
     subroutine c_mpfr_init2(x, prec) bind(C,name="mpfr_init2")
       import :: mpfr_t, c_long
       type(mpfr_t), intent(out) :: x
       integer(c_long), value :: prec
     end subroutine

     subroutine c_mpfr_clear(x) bind(C,name="mpfr_clear")
       import :: mpfr_t
       type(mpfr_t), intent(inout) :: x
     end subroutine

     integer(c_int) function c_mpfr_set_str(x,s,base,rnd) &
       bind(C,name="mpfr_set_str")
       import :: mpfr_t, c_char, c_int
       type(mpfr_t), intent(inout) :: x
       character(c_char), dimension(*) :: s
       integer(c_int), value :: base, rnd
     end function

     subroutine c_mpfr_set(z,x,rnd) bind(C,name="mpfr_set")
       import :: mpfr_t, c_int
       type(mpfr_t), intent(inout) :: z
       type(mpfr_t), intent(in) :: x
       integer(c_int), value :: rnd
     end subroutine

     subroutine c_mpfr_add(z,x,y,rnd) bind(C,name="mpfr_add")
       import :: mpfr_t, c_int
       type(mpfr_t), intent(inout) :: z
       type(mpfr_t), intent(in) :: x,y
       integer(c_int), value :: rnd
     end subroutine

     subroutine c_mpfr_sub(z,x,y,rnd) bind(C,name="mpfr_sub")
       import :: mpfr_t, c_int
       type(mpfr_t), intent(inout) :: z
       type(mpfr_t), intent(in) :: x,y
       integer(c_int), value :: rnd
     end subroutine

     subroutine c_mpfr_mul(z,x,y,rnd) bind(C,name="mpfr_mul")
       import :: mpfr_t, c_int
       type(mpfr_t), intent(inout) :: z
       type(mpfr_t), intent(in) :: x,y
       integer(c_int), value :: rnd
     end subroutine

     subroutine c_mpfr_div(z,x,y,rnd) bind(C,name="mpfr_div")
       import :: mpfr_t, c_int
       type(mpfr_t), intent(inout) :: z
       type(mpfr_t), intent(in) :: x,y
       integer(c_int), value :: rnd
     end subroutine

     subroutine c_mpfr_sqrt(z,x,rnd) bind(C,name="mpfr_sqrt")
       import :: mpfr_t, c_int
       type(mpfr_t), intent(inout) :: z
       type(mpfr_t), intent(in) :: x
       integer(c_int), value :: rnd
     end subroutine

     integer(c_int) function c_mpfr_cmp(x,y) bind(C,name="mpfr_cmp")
       import :: mpfr_t, c_int
       type(mpfr_t), intent(in) :: x,y
     end function

     integer(c_int) function c_mpfr_snprintf(buf,n,fmt,x) &
       bind(C,name="mpfr_snprintf")
       import :: mpfr_t, c_char, c_size_t, c_int
       character(c_char), dimension(*) :: buf
       integer(c_size_t), value :: n
       character(c_char), dimension(*) :: fmt
       type(mpfr_t), intent(in) :: x
     end function
  end interface

contains

  subroutine mpfr_real_init(r, prec_bits)
    type(mpfr_real), intent(out) :: r
    integer, intent(in) :: prec_bits
    call c_mpfr_init2(r%v, int(prec_bits, c_long))
  end subroutine

  subroutine mpfr_real_clear(r)
    type(mpfr_real), intent(inout) :: r
    call c_mpfr_clear(r%v)
  end subroutine

  subroutine mpfr_real_set_str(r, s)
    type(mpfr_real), intent(inout) :: r
    character(len=*), intent(in) :: s
    character(c_char), allocatable :: cbuf(:)
    integer(c_int) :: rc
    integer :: n

    n = len_trim(s) + 1
    allocate(cbuf(n))
    cbuf(1:n-1) = transfer(s(1:n-1), cbuf(1:n-1))
    cbuf(n) = c_null_char

    rc = c_mpfr_set_str(r%v, cbuf, 10, RND)
    deallocate(cbuf)
  end subroutine

function mpfr_real_to_string(x, digits) result(s)
  type(mpfr_real), intent(in) :: x
  integer, intent(in) :: digits

  character(len=256) :: s
  character(len=32)  :: fstr
  character(c_char)  :: buf(256)
  character(c_char)  :: fmt(32)
  integer(c_int) :: rc
  integer :: i, n

  ! Build Fortran format string
  write(fstr,'("%.",I0,"Rg")') digits

  ! Copy format to C string
  n = len_trim(fstr)
  do i = 1, n
     fmt(i) = fstr(i:i)
  end do
  fmt(n+1) = c_null_char

  ! Call MPFR
  rc = c_mpfr_snprintf(buf, int(size(buf),c_size_t), fmt, x%v)

  ! Clear result
  s = ' '

  ! Copy C string until null terminator
  do i = 1, len(s)
     if (buf(i) == c_null_char) exit
     s(i:i) = transfer(buf(i), s(i:i))
  end do
end function

  subroutine mpfr_add(z, x, y)
    type(mpfr_real), intent(inout) :: z
    type(mpfr_real), intent(in)    :: x, y
    call c_mpfr_add(z%v, x%v, y%v, RND)
  end subroutine

  subroutine mpfr_sub(z, x, y)
    type(mpfr_real), intent(inout) :: z
    type(mpfr_real), intent(in)    :: x, y
    call c_mpfr_sub(z%v, x%v, y%v, RND)
  end subroutine

  subroutine mpfr_mul(z, x, y)
    type(mpfr_real), intent(inout) :: z
    type(mpfr_real), intent(in)    :: x, y
    call c_mpfr_mul(z%v, x%v, y%v, RND)
  end subroutine

  subroutine mpfr_div(z, x, y)
    type(mpfr_real), intent(inout) :: z
    type(mpfr_real), intent(in)    :: x, y
    call c_mpfr_div(z%v, x%v, y%v, RND)
  end subroutine

  subroutine mpfr_sqrt(z, x)
    type(mpfr_real), intent(inout) :: z
    type(mpfr_real), intent(in) :: x
    call c_mpfr_sqrt(z%v, x%v, RND)
  end subroutine

function mpfr_real_cmp(a,b) result(res)
  type(mpfr_real), intent(in) :: a,b
  integer :: res
  res = c_mpfr_cmp(a%v, b%v)
end function

subroutine mpfr_real_set(dest, src)
  type(mpfr_real), intent(inout) :: dest
  type(mpfr_real), intent(in) :: src
  call c_mpfr_set(dest%v, src%v, RND)
end subroutine

end module mpfr_mod
