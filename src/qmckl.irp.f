BEGIN_PROVIDER [ integer*8, qmckl_ctx ]
  use qmckl
  implicit none
  BEGIN_DOC
  ! Context for the QMCKL library
  END_DOC

  integer, save :: ifirst = 0
  integer(qmckl_exit_code) :: rc

  if (ifirst == 0) then
    qmckl_ctx = qmckl_context_create()
    ifirst = 1
    rc = qmckl_trexio_read(qmckl_ctx, trim(trexio_filename))
    call qmckl_check(rc, irp_here)

    ! Electrons
    rc = rc + qmckl_set_electron_num(qmckl_ctx, int(elec_alpha_num,8), int(elec_beta_num,8))
    call qmckl_check(rc, irp_here)
    rc = rc + qmckl_set_electron_walk_num(qmckl_ctx, 1_8)
    call qmckl_check(rc, irp_here)
  end if

  rc = qmckl_set_electron_coord(qmckl_ctx, 'T', dble(elec_coord(1:elec_num,1:3)),  &
   int(3*elec_num,8))
  call qmckl_check(rc, irp_here)

END_PROVIDER

subroutine qmckl_check(rc, here)
  use qmckl
  implicit none
  integer(qmckl_exit_code), intent(in) :: rc
  character*(*), intent(in) :: here
  character*(128) :: msg
  if (rc == QMCKL_SUCCESS) return
  call qmckl_string_of_error(rc, msg)
  print *, here
  print *, msg
  stop -1
end

BEGIN_PROVIDER [ integer, qmckl_precision ]
 use qmckl
 implicit none
 BEGIN_DOC
 ! Precision used in QMCKL
 END_DOC
 qmckl_precision = qmckl_get_numprec_precision(qmckl_ctx)
END_PROVIDER

BEGIN_PROVIDER [ double precision, qmckl_ao_vgl, (ao_num, 5, elec_num) ]
 use qmckl
 implicit none
 BEGIN_DOC
 ! AO value, gradients, Laplacian from QMCkl
 END_DOC
 integer(qmckl_exit_code) :: rc
 rc = qmckl_get_ao_basis_ao_vgl(qmckl_ctx, qmckl_ao_vgl, elec_num*ao_num*5_8)
 call qmckl_check(rc, irp_here)

END_PROVIDER

