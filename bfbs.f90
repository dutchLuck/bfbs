!
! B F B S . F 9 0
!
! bfbs.f90 last edited on Tue Feb 17 23:37:30 2026 
!
! This code reads a CSV file containing rows of comma separated
! data and provides summary stats for each column of numbers.
! This code uses the GMP and MPFR libraries packages to implement
! arbitrary precision arithmetic routines to ensure the summary
! stats can be of sufficient accuracy for any given user.
!
! The code can be compiled by gfortran, on a linux system
! with gmp and mpfr installed, as shown below; -
! gfortran -Wall -std=f2008 -O2 mpfr_mod.f90 bfbs.f90 -lmpfr -lgmp -o bfbs_fortran
!
! The code can be run on linux; -
! ./bfbs_fortran data.csv
!
! The output from the above command for the following
! data.csv file is; -
!
! $ cat data.csv
! # Example CSV
! 1.0, 2.0, 3.0
! 4.0, 5.0, 6.0
! 7.0, 8.0, 9.0
!
! $ ./bfbs_fortran data.csv 
! bfbs version 0.0.1
! Fortran compiler: GCC version 11.4.0
! Using  256 bits of calculation precision and  64 digits output precision.
! Column 1: 
!   count  : 3
!   min    : 1
!   mean   : 4
!   median : 4
!   max    : 7
!   range  : 6
!   sum    : 12
!   var    : 9
!   std    : 3
! Column 2: 
!   count  : 3
!   min    : 2
!   mean   : 5
!   median : 5
!   max    : 8
!   range  : 6
!   sum    : 15
!   var    : 9
!   std    : 3
! Column 3: 
!   count  : 3
!   min    : 3
!   mean   : 6
!   median : 6
!   max    : 9
!   range  : 6
!   sum    : 18
!   var    : 9
!   std    : 3
! bfbs (fortran executable) time taken:  0.001 [sec]
!

program bfbs
  use iso_c_binding
  use iso_fortran_env   !compiler_version(), compiler_options()
  use mpfr_mod
  implicit none

  character(len=*), parameter :: version = "0.0.1"

  integer :: i,j,ncols,nrows,prec_bits,digits,argc,arg_idx,ios,k_row_no
  real :: start_time, finish_time
  character(len=512) :: line, fname
  logical :: has_header, debug_output, help_output, quiet_output
  character(len=512), allocatable :: colnames(:)
  character(len=128), allocatable :: fields(:)     ! N.B. can't handle CSV file numbers of more than 128 digits

  type(mpfr_real), allocatable :: data(:,:)
  type(mpfr_real) :: minv, mean, median, maxv, range, sum, var, std
  type(mpfr_real) :: denom, tmp, tmp_n
  type(mpfr_real), allocatable :: colvals(:)
  character(len=128) :: col_label

  !----------------------------
  ! Start Processing
  !----------------------------
  call cpu_time(start_time)

  !----------------------------
  ! Defaults
  !----------------------------
  prec_bits = 256
  digits = 64
  has_header = .false.
  debug_output = .false.
  help_output = .false.
  quiet_output = .false.

  !----------------------------
  ! Command-line parsing
  !----------------------------
  argc = command_argument_count()
  arg_idx = 1
  do while(arg_idx <= argc)
     call get_command_argument(arg_idx,line)
     if (line(1:min(6,len(line))) == "--prec") then
        arg_idx = arg_idx+1
        call get_command_argument(arg_idx,line)
        read(line,*) prec_bits
     else if (line(1:min(8,len(line))) == "--digits") then
        arg_idx = arg_idx+1
        call get_command_argument(arg_idx,line)
        read(line,*) digits
     else if (line(1:min(8,len(line))) == "--header") then
        has_header = .true.
     else if (line(1:min(7,len(line))) == "--debug") then
        debug_output = .true.
     else if (line(1:min(7,len(line))) == "--quiet") then
        quiet_output = .true.
     else if (line(1:min(6,len(line))) == "--help") then
        help_output = .true.
     else if (line(1:min(2,len(line))) == "-h") then
        help_output = .true.
     else
        fname = trim(line)
     end if
     arg_idx = arg_idx+1
  end do

  !----------------------------------------
  ! Sanitize command parameters if required
  !----------------------------------------
  if ( digits < 8) then
    digits = 8
  else if ( digits > 120) then
    digits = 120
  endif
  if ( prec_bits < 32) then
    prec_bits = 32
  else if ( prec_bits > 2048) then
    prec_bits = 2048
  endif

  if ( .not. quiet_output ) then
    write(*,'(A)') "bfbs version "//trim(version)
    write(*,'(A)') "Fortran compiler: "//trim(compiler_version())
  endif

  if (debug_output) then
    write(*,'(A)') "DEBUG: compile time options: "//trim(compiler_options())
  endif
  print '("Using ",i4," bits of calculation precision and ",i3," digits output precision.")',prec_bits, digits

  !------------------------------------
  ! Output help information if required
  !------------------------------------
  if (help_output) then
    print '("")'
    print '("Usage:")'
    print '(" bfbs [-h][--help][--debug][--digits INT][--header][--prec INT][--quiet] data_file_name.csv")'
    print '("  where; -")'
    print '("  --help or -h .. outputs this help info")'
    print '("  --debug      .. outputs extra information")'
    print '("  --digits INT .. uses up to INT digits to represent the stats numbers")'
    print '("  --header     .. CSV file has a first line with column labels")'
    print '("  --prec INT   .. uses INT bits of precision in the calculations")'
    print '("  --quiet      .. Suppress output of version and timing information")'
    print '("")'
    stop 
  endif

  !----------------------------
  ! Open file
  !----------------------------
  open(10,file=fname,status='old',action='read',iostat=ios)
  if (ios /= 0) then
     write(*,*) "Cannot open file: ", trim(fname)
     stop
  end if

  !----------------------------
  ! Count rows and columns
  !----------------------------
  nrows = 0
  ncols = 0
  do
     read(10,'(A)',iostat=ios) line
     if (ios /= 0) exit
     line = trim(adjustl(line))
     if (line=='' .or. line(1:1)=='#') cycle    ! ignore blank lines and comments
     if (ncols==0) ncols = count_commas(line)+1
     nrows = nrows+1
  end do
  if ( has_header .and. nrows > 1 ) nrows = nrows-1   ! Adjust for header line, so nrows is number of rows with numbers

  rewind(10)

  allocate(data(nrows,ncols))
  allocate(colvals(nrows))
  if (has_header) allocate(colnames(ncols))

  !----------------------------
  ! Read data
  !----------------------------
  k_row_no = 0
  do
     read(10,'(A)',iostat=ios) line
     if (ios /= 0) exit
     line = trim(adjustl(line))
     if (line=='' .or. line(1:1)=='#') cycle    ! ignore blank lines and comments

     if (k_row_no == 0 .and. has_header) then
        fields = split_csv(line,ncols)
        do j=1,ncols
           colnames(j) = trim(fields(j))
        end do
        k_row_no = 1    ! Don't allow entry to this block to get headers again
     else
       fields = split_csv(line,ncols)
       if (k_row_no == 0) k_row_no = 1
       do j=1,ncols
         if (debug_output) then
           write(*,*) "DEBUG: fields()  : ", trim(fields(j))
         endif
         call mpfr_real_init(data(k_row_no,j),prec_bits)
         call mpfr_real_set_str(data(k_row_no,j),trim(fields(j)))
         if (debug_output) then
           write(*,*) "DEBUG: data(",k_row_no,",",j,") : ", trim(mpfr_real_to_string(data(k_row_no,j), digits))
         endif
       end do
       k_row_no = k_row_no+1
     endif
  end do
  close(10)

  if (debug_output) then
    print '(" DEBUG: Closed file after reading ",i6," lines of ",i6," columns.")',k_row_no-1, ncols
  endif

  !----------------------------
  ! Compute statistics per column
  !----------------------------
  do j=1,ncols
     ! Initialize
     call mpfr_real_init(sum,prec_bits)
     call mpfr_real_set_str(sum,'0.0')
     call mpfr_real_init(minv,prec_bits)
     call mpfr_real_init(maxv,prec_bits)
     call mpfr_real_set(minv,data(1,j))
     call mpfr_real_set(maxv,data(1,j))

     ! Sum, min, max
     do i=1,nrows
        call mpfr_real_init(tmp,prec_bits)
        call mpfr_real_set(tmp,data(i,j))
        call mpfr_add(sum,tmp,sum)
        call mpfr_real_init(colvals(i),prec_bits)
        call mpfr_real_set(colvals(i),data(i,j))
        if (mpfr_real_cmp(tmp,minv)<0) call mpfr_real_set(minv,tmp)
        if (mpfr_real_cmp(tmp,maxv)>0) call mpfr_real_set(maxv,tmp)
        call mpfr_real_clear(tmp)
     end do

     if (debug_output) then
       write(*,*) "DEBUG: min    : ", trim(mpfr_real_to_string(minv, digits))
       write(*,*) "DEBUG: max    : ", trim(mpfr_real_to_string(maxv, digits))
       write(*,*) "DEBUG: sum    : ", trim(mpfr_real_to_string(sum, digits))
     endif
 
     ! Range
     call mpfr_real_init(range,prec_bits)
     call mpfr_sub(range,maxv,minv)

     if (debug_output) then
       write(*,*) "DEBUG: range  : ", trim(mpfr_real_to_string(range, digits))
     endif

     ! Mean
     call mpfr_real_init(mean,prec_bits)
     tmp_n = mk_mpfr_real_from_int(nrows,prec_bits)
     call mpfr_div(mean,sum,tmp_n)
     call mpfr_real_clear(tmp_n)

     if (debug_output) then
       write(*,*) "DEBUG: mean   : ", trim(mpfr_real_to_string(mean, digits))
     endif

     ! Variance
     call mpfr_real_init(var,prec_bits)
     call mpfr_real_set_str(var,'0.0')
     do i=1,nrows
        call mpfr_real_init(tmp,prec_bits)
        call mpfr_sub(tmp,data(i,j),mean)
        call mpfr_mul(tmp,tmp,tmp)
        call mpfr_add(var,tmp,var)
        call mpfr_real_clear(tmp)
     end do
     tmp_n = mk_mpfr_real_from_int(nrows-1,prec_bits)
     call mpfr_div(var,var,tmp_n)
     call mpfr_real_clear(tmp_n)

     tmp_n = mk_mpfr_real_from_int(nrows,prec_bits)

     ! Standard deviation
     call mpfr_real_init(std,prec_bits)
     call mpfr_sqrt(std, var)

     if (debug_output) then
       write(*,*) "DEBUG: std    : ", trim(mpfr_real_to_string(std, digits))
     endif

     ! Median
     call mpfr_sort(colvals,nrows,prec_bits)
     if (debug_output) then
       write(*,*) "DEBUG: colvals(1)    : ", trim(mpfr_real_to_string(colvals(1), digits))
       write(*,*) "DEBUG: colvals(last)    : ", trim(mpfr_real_to_string(colvals(nrows), digits))
     endif
     call mpfr_real_init(median,prec_bits)
     if (mod(nrows, 2) == 1) then
        call mpfr_real_set(median,colvals((nrows+1)/2))
     else
        call mpfr_real_init(tmp, prec_bits)
        call mpfr_add(tmp, colvals(nrows/2), colvals(nrows/2+1))
        call mpfr_real_init(denom, prec_bits)
        call mpfr_real_set_str(denom, "2.0")
        call mpfr_div(median, tmp, denom)
     end if

     if (debug_output) then
       write(*,*) "DEBUG: median : ", trim(mpfr_real_to_string(median, digits))
     endif

     ! Column label
     if (has_header) then
        col_label = trim(colnames(j))
     else
        col_label = itoa(j)
     end if

     ! Print Stats for current column
     ! write(*,'(A)',advance='no') "Column "//trim(col_label)//": "
     write(*,'(A)') "Column "//trim(col_label)//": "
     write(*,*) " count  : ", trim(mpfr_real_to_string(tmp_n, digits))
     write(*,*) " min    : ", trim(mpfr_real_to_string(minv, digits))
     write(*,*) " mean   : ", trim(mpfr_real_to_string(mean, digits))
     write(*,*) " median : ", trim(mpfr_real_to_string(median, digits))
     write(*,*) " max    : ", trim(mpfr_real_to_string(maxv, digits))
     write(*,*) " range  : ", trim(mpfr_real_to_string(range, digits))
     write(*,*) " sum    : ", trim(mpfr_real_to_string(sum, digits))
     write(*,*) " var    : ", trim(mpfr_real_to_string(var, digits))
     write(*,*) " std    : ", trim(mpfr_real_to_string(std, digits))

     ! Clear
     call mpfr_real_clear(tmp_n)
     call mpfr_real_clear(minv)
     call mpfr_real_clear(mean)
     call mpfr_real_clear(median)
     call mpfr_real_clear(maxv)
     call mpfr_real_clear(range)
     call mpfr_real_clear(sum)
     call mpfr_real_clear(var)
     call mpfr_real_clear(std)
  end do

  if ( .not. quiet_output ) then
    call cpu_time(finish_time)
    print '("bfbs (fortran executable) time taken: ",f6.3," [sec]")',finish_time-start_time
  endif

contains

  function itoa(i) result(s)
    integer, intent(in) :: i
    character(len=16) :: s
    write(s,'(I0)') i
  end function

  function mk_mpfr_real_from_int(i,prec) result(r)
    integer, intent(in) :: i, prec
    type(mpfr_real) :: r
    call mpfr_real_init(r,prec)
    call mpfr_real_set_str(r,trim(itoa(i)))
  end function

  integer function count_commas(line)
    character(len=*), intent(in) :: line
    integer :: k
    count_commas = 0
    do k=1,len_trim(line)
       if (line(k:k)==',') count_commas = count_commas+1
    end do
  end function

  function split_csv(line,ncols) result(fields)
    character(len=*), intent(in) :: line
    integer, intent(in) :: ncols
    character(len=128), dimension(ncols) :: fields     ! N.B. can't handle CSV file numbers of more than 128 digits
    integer :: i,j,start
    start = 1
    j = 1
    do i=1,len_trim(line)
       if (line(i:i)==',' .or. i==len_trim(line)) then
          if (i==len_trim(line)) then
             fields(j) = adjustl(line(start:i))
          else
             fields(j) = adjustl(line(start:i-1))
          end if
          j=j+1
          start = i+1
       end if
    end do
  end function

  !----------------------------
  ! Simple bubble sort for mpfr_real array
  !----------------------------
  subroutine mpfr_sort(a,n,prec_bts)
    type(mpfr_real), intent(inout) :: a(:)
    integer, intent(in) :: n, prec_bts
    integer :: i,j
    type(mpfr_real) :: temp
    call mpfr_real_init(temp,prec_bts)
    do i = 1, n-1
       do j = 1, n-i
          if (mpfr_real_cmp(a(j),a(j+1)) > 0) then
             call mpfr_real_set(temp,a(j))
             call mpfr_real_set(a(j),a(j+1))
             call mpfr_real_set(a(j+1),temp)
          end if
       end do
    end do
    call mpfr_real_clear(temp)
  end subroutine

end program
