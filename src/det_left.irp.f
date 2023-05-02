
! ---

 BEGIN_PROVIDER  [ integer, det_left_i ]
&BEGIN_PROVIDER  [ integer, det_left_i_prev ]

  BEGIN_DOC
  ! Current running alpha determinant
  END_DOC

  implicit none

  det_left_i      = det_alpha_order(1)
  det_left_i_prev = det_alpha_order(1)

END_PROVIDER

! ---

 BEGIN_PROVIDER  [ integer, det_left_j ]
&BEGIN_PROVIDER  [ integer, det_left_j_prev ]

  BEGIN_DOC
  ! Current running beta determinant
  END_DOC

  implicit none

  det_left_j      = det_beta_order(1)
  det_left_j_prev = det_beta_order(1)

END_PROVIDER

! ---

 BEGIN_PROVIDER [ integer, mo_left_list_alpha_curr, (elec_alpha_num) ]
&BEGIN_PROVIDER [ integer, mo_left_list_alpha_prev, (elec_alpha_num) ]
&BEGIN_PROVIDER [ integer, mo_left_exc_alpha_curr ]

  BEGIN_DOC
  ! List of MOs in the current alpha determinant
  END_DOC

  implicit none
  integer :: l

  if (det_left_i /= det_alpha_order(1)) then
    mo_left_list_alpha_prev = mo_left_list_alpha_curr
  else
    mo_left_list_alpha_prev = 0
  endif

  !DIR$ FORCEINLINE
  call bitstring_to_list(psi_det_alpha(1,det_left_i), mo_left_list_alpha_curr, l, N_int)
  if(l /= elec_alpha_num) then
    stop 'error in number of alpha electrons'
  endif
  call get_excitation_degree_spin(psi_det_alpha(1,det_left_i),      &
                                  psi_det_alpha(1,det_left_i_prev), &
                                  mo_left_exc_alpha_curr, N_int)

END_PROVIDER

! ---

 BEGIN_PROVIDER [ integer, mo_left_list_beta_curr, (elec_beta_num) ]
&BEGIN_PROVIDER [ integer, mo_left_list_beta_prev, (elec_beta_num) ]
&BEGIN_PROVIDER [ integer, mo_left_exc_beta_curr ]

  BEGIN_DOC
  ! List of MOs in the current beta determinant
  END_DOC

  implicit none
  integer :: l

  if (elec_beta_num == 0) then
    return
  endif
  if (det_left_j /= det_beta_order(1)) then
    mo_left_list_beta_prev = mo_left_list_beta_curr
  else
    mo_left_list_beta_prev = 0
  endif

  !DIR$ FORCEINLINE
  call bitstring_to_list ( psi_det_beta(1,det_left_j), mo_left_list_beta_curr, l, N_int )
  if (l /= elec_beta_num) then
    stop 'error in number of beta electrons'
  endif
  call get_excitation_degree_spin(psi_det_beta(1,det_left_j),    &
                                  psi_det_beta(1,det_left_j_prev), &
                                  mo_left_exc_beta_curr, N_int)

END_PROVIDER

! ---

 BEGIN_PROVIDER [ double precision, det_left_alpha_value_curr ]
&BEGIN_PROVIDER [ real,             slater_matrix_left_alpha,         (elec_alpha_num_8,elec_alpha_num) ]
&BEGIN_PROVIDER [ double precision, slater_matrix_left_alpha_inv_det, (elec_alpha_num_8,elec_alpha_num) ]

  BEGIN_DOC
  ! det_left_alpha_value_curr : Value of the current alpha determinant
  !
  ! det_left_alpha_value_curr : Slater matrix for the current alpha determinant.
  !  1st index runs over electrons and
  !  2nd index runs over MOs.
  !  Built with 1st determinant
  !
  ! slater_matrix_left_alpha_inv_det: Inverse of the alpha Slater matrix x determinant
  END_DOC

  implicit none
  integer, save    :: ifirst
  integer          :: i,j,k,imo,l
  integer          :: to_do(elec_alpha_num), n_to_do_old, n_to_do
  real             :: tmp_det(elec_alpha_num_8)
  double precision :: tmp_inv(elec_alpha_num_8)
  double precision :: ddet
  !DIR$ ATTRIBUTES ALIGN : $IRP_ALIGN :: tmp_inv, tmp_det

  if (ifirst == 0) then
    ifirst = 1
    !DIR$ VECTOR ALIGNED
    slater_matrix_left_alpha = 0.
    !DIR$ VECTOR ALIGNED
    slater_matrix_left_alpha_inv_det = 0.d0
  endif

  PROVIDE mo_left_value
  if (det_left_i /= det_alpha_order(1) ) then

    n_to_do = 0
    do k=1,elec_alpha_num
      imo = mo_left_list_alpha_curr(k)
      if ( imo /= mo_left_list_alpha_prev(k) ) then
          n_to_do += 1
          to_do(n_to_do) = k
      endif
    enddo

    ! make swaps and keep 1 update
    if (n_to_do > 1 .and. mo_left_exc_alpha_curr == 1) then

      if (iand(n_to_do+1,1)==1) then
        det_left_alpha_value_curr = -det_left_alpha_value_curr
        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        slater_matrix_left_alpha_inv_det = - slater_matrix_left_alpha_inv_det
      endif

      if (mo_left_list_alpha_curr(to_do(1)) == mo_left_list_alpha_prev(to_do(1)+1)) then

        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        do l=1,elec_alpha_num_8
          tmp_det(l) = slater_matrix_left_alpha(l,to_do(1))
          tmp_inv(l) = slater_matrix_left_alpha_inv_det(l,to_do(1))
        enddo

        do k=to_do(1),to_do(n_to_do-1)
          !DIR$ VECTOR ALWAYS
          !DIR$ VECTOR ALIGNED
          do l=1,elec_alpha_num_8
            slater_matrix_left_alpha(l,k) = slater_matrix_left_alpha(l,k+1)
            slater_matrix_left_alpha_inv_det(l,k) = slater_matrix_left_alpha_inv_det(l,k+1)
          enddo
        enddo
        k = to_do(n_to_do)
        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        do l=1,elec_alpha_num_8
          slater_matrix_left_alpha(l,k) = tmp_det(l)
          slater_matrix_left_alpha_inv_det(l,k) = tmp_inv(l)
        enddo
        to_do(1) = to_do(n_to_do)

      else if (mo_left_list_alpha_curr(to_do(n_to_do)) == mo_left_list_alpha_prev(to_do(n_to_do)-1)) then
        k = to_do(n_to_do)
        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        do l=1,elec_alpha_num_8
          tmp_det(l) = slater_matrix_left_alpha(l,k)
          tmp_inv(l) = slater_matrix_left_alpha_inv_det(l,k)
        enddo
        do k=to_do(n_to_do),to_do(2),-1
          !DIR$ VECTOR ALWAYS
          !DIR$ VECTOR ALIGNED
          do l=1,elec_alpha_num_8
            slater_matrix_left_alpha(l,k) = slater_matrix_left_alpha(l,k-1)
            slater_matrix_left_alpha_inv_det(l,k) = slater_matrix_left_alpha_inv_det(l,k-1)
          enddo
        enddo
        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        do l=1,elec_alpha_num_8
          slater_matrix_left_alpha(l,to_do(1)) = tmp_det(l)
          slater_matrix_left_alpha_inv_det(l,to_do(1)) = tmp_inv(l)
        enddo

      endif
      n_to_do = 1
    endif

    ddet = 0.d0

    if (n_to_do < shiftl(elec_alpha_num,1)) then

      do while ( n_to_do > 0 )
        ddet = det_left_alpha_value_curr
        n_to_do_old = n_to_do
        n_to_do = 0
        do l=1,n_to_do_old
          k = to_do(l)
          imo = mo_left_list_alpha_curr(k)
          call det_update(elec_alpha_num, elec_alpha_num_8,            &
              mo_left_value(1,imo),                                         &
              k,                                                       &
              slater_matrix_left_alpha,                                     &
              slater_matrix_left_alpha_inv_det,                             &
              ddet)
          if (ddet /= 0.d0) then
            det_left_alpha_value_curr = ddet
          else
            n_to_do += 1
            to_do(n_to_do) = k
            ddet = det_left_alpha_value_curr
          endif
        enddo
        if (n_to_do == n_to_do_old) then
          ddet = 0.d0
          exit
        endif
      enddo

    endif

  else

    ddet = 0.d0

  endif

  ! Avoid NaN
  if (ddet /= 0.d0) then
    continue
  else
    do j=1,mo_closed_num
      !DIR$ VECTOR ALIGNED
      !DIR$ LOOP COUNT(100)
      do i=1,elec_alpha_num
        slater_matrix_left_alpha(i,j) = mo_left_value(i,j)
        slater_matrix_left_alpha_inv_det(j,i) = mo_left_value(i,j)
      enddo
    enddo
    do k=mo_closed_num+1,elec_alpha_num
      !DIR$ VECTOR ALIGNED
      !DIR$ LOOP COUNT(100)
      do i=1,elec_alpha_num
        slater_matrix_left_alpha(i,k) = mo_left_value(i,mo_left_list_alpha_curr(k))
        slater_matrix_left_alpha_inv_det(k,i) = mo_left_value(i,mo_left_list_alpha_curr(k))
      enddo
    enddo
    call invert(slater_matrix_left_alpha_inv_det,elec_alpha_num_8,elec_alpha_num,ddet)

  endif
  ASSERT (ddet /= 0.d0)

  det_left_alpha_value_curr = ddet

END_PROVIDER

! ---

 BEGIN_PROVIDER [ double precision, det_left_beta_value_curr ]
&BEGIN_PROVIDER [ real,             slater_matrix_left_beta,         (elec_beta_num_8,elec_beta_num) ]
&BEGIN_PROVIDER [ double precision, slater_matrix_left_beta_inv_det, (elec_beta_num_8,elec_beta_num) ]

  BEGIN_DOC
  !  det_left_beta_value_curr : Value of the current beta determinant
  !
  !  slater_matrix_left_beta : Slater matrix for the current beta determinant.
  !  1st index runs over electrons and
  !  2nd index runs over MOs.
  !  Built with 1st determinant
  !
  !  slater_matrix_left_beta_inv_det : Inverse of the beta Slater matrix x determinant
  END_DOC

  implicit none
  integer, save    :: ifirst
  integer          :: i,j,k,imo,l
  integer          :: to_do(elec_alpha_num-mo_closed_num), n_to_do_old, n_to_do
  real             :: tmp_det(elec_alpha_num_8)
  double precision :: tmp_inv(elec_alpha_num_8)
  double precision :: ddet

  if (elec_beta_num == 0) then
    det_left_beta_value_curr = 0.d0
    return
  endif

  if (ifirst == 0) then
    ifirst = 1
    slater_matrix_left_beta = 0.
    slater_matrix_left_beta_inv_det = 0.d0
  endif
  PROVIDE mo_left_value

  if (det_left_j /= det_beta_order(1)) then

    n_to_do = 0
    do k=mo_closed_num+1,elec_beta_num
      imo = mo_left_list_beta_curr(k)
      if ( imo /= mo_left_list_beta_prev(k) ) then
          n_to_do += 1
          to_do(n_to_do) = k
      endif
    enddo

    ! make swaps and keep 1 update
    if (n_to_do > 1 .and. mo_left_exc_beta_curr == 1) then

      if (iand(n_to_do+1,1)==1) then
        det_left_beta_value_curr = -det_left_beta_value_curr
        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        slater_matrix_left_beta_inv_det = - slater_matrix_left_beta_inv_det
      endif

      if (mo_left_list_beta_curr(to_do(1)) == mo_left_list_beta_prev(to_do(1)+1)) then

        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        do l=1,elec_beta_num_8
          tmp_det(l) = slater_matrix_left_beta(l,to_do(1))
          tmp_inv(l) = slater_matrix_left_beta_inv_det(l,to_do(1))
        enddo

        do k=to_do(1),to_do(n_to_do-1)
          !DIR$ VECTOR ALWAYS
          !DIR$ VECTOR ALIGNED
          do l=1,elec_beta_num_8
            slater_matrix_left_beta(l,k) = slater_matrix_left_beta(l,k+1)
            slater_matrix_left_beta_inv_det(l,k) = slater_matrix_left_beta_inv_det(l,k+1)
          enddo
        enddo
        k = to_do(n_to_do)
        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        do l=1,elec_beta_num_8
          slater_matrix_left_beta(l,k) = tmp_det(l)
          slater_matrix_left_beta_inv_det(l,k) = tmp_inv(l)
        enddo
        to_do(1) = to_do(n_to_do)

      else if (mo_left_list_beta_curr(to_do(n_to_do)) == mo_left_list_beta_prev(to_do(n_to_do)-1)) then
        k = to_do(n_to_do)
        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        do l=1,elec_beta_num_8
          tmp_det(l) = slater_matrix_left_beta(l,k)
          tmp_inv(l) = slater_matrix_left_beta_inv_det(l,k)
        enddo
        do k=to_do(n_to_do),to_do(2),-1
          !DIR$ VECTOR ALWAYS
          !DIR$ VECTOR ALIGNED
          do l=1,elec_beta_num_8
            slater_matrix_left_beta(l,k) = slater_matrix_left_beta(l,k-1)
            slater_matrix_left_beta_inv_det(l,k) = slater_matrix_left_beta_inv_det(l,k-1)
          enddo
        enddo
        !DIR$ VECTOR ALWAYS
        !DIR$ VECTOR ALIGNED
        do l=1,elec_beta_num_8
          slater_matrix_left_beta(l,to_do(1)) = tmp_det(l)
          slater_matrix_left_beta_inv_det(l,to_do(1)) = tmp_inv(l)
        enddo

      endif
      n_to_do = 1
    endif

    ddet = 0.d0

    if (n_to_do < shiftl(elec_beta_num,1)) then

      do while ( n_to_do > 0 )
        ddet = det_left_beta_value_curr
        n_to_do_old = n_to_do
        n_to_do = 0
        do l=1,n_to_do_old
          k = to_do(l)
          imo = mo_left_list_beta_curr(k)
          call det_update(elec_beta_num, elec_beta_num_8,                &
              mo_left_value(elec_alpha_num+1,imo),                            &
              k,                                                         &
              slater_matrix_left_beta,                                        &
              slater_matrix_left_beta_inv_det,                                &
              ddet)
          if (ddet /= 0.d0) then
            det_left_beta_value_curr = ddet
          else
            n_to_do += 1
            to_do(n_to_do) = k
            ddet = det_left_beta_value_curr
          endif
        enddo
        if (n_to_do == n_to_do_old) then
          ddet = 0.d0
          exit
        endif
      enddo

    endif

  else

    ddet = 0.d0

  endif

  ! Avoid NaN
  if (ddet /= 0.d0) then
    continue
  else
    do j=1,mo_closed_num
      !DIR$ VECTOR UNALIGNED
      !DIR$ LOOP COUNT (100)
      do i=1,elec_beta_num
        slater_matrix_left_beta(i,j) = mo_left_value(i+elec_alpha_num,j)
        slater_matrix_left_beta_inv_det(j,i) = mo_left_value(i+elec_alpha_num,j)
      enddo
    enddo
    do k=mo_closed_num+1,elec_beta_num
      !DIR$ VECTOR UNALIGNED
      !DIR$ LOOP COUNT (100)
      do i=1,elec_beta_num
        slater_matrix_left_beta(i,k) = mo_left_value(i+elec_alpha_num,mo_left_list_beta_curr(k))
        slater_matrix_left_beta_inv_det(k,i) = mo_left_value(i+elec_alpha_num,mo_left_list_beta_curr(k))
      enddo
    enddo
    call invert(slater_matrix_left_beta_inv_det,elec_beta_num_8,elec_beta_num,ddet)
  endif
  ASSERT (ddet /= 0.d0)

  det_left_beta_value_curr = ddet

END_PROVIDER

! ---

BEGIN_PROVIDER  [ double precision, det_left_alpha_pseudo_curr, (elec_alpha_num) ]

  BEGIN_DOC
  ! Pseudopotential non-local contribution
  END_DOC

  implicit none
  integer, save    :: ifirst = 0
  integer          :: i, n, imo
  double precision :: c

  if(ifirst == 0) then
    ifirst = 1
    det_left_alpha_pseudo_curr = 0.d0
  endif

  if(do_pseudo) then
    do i = 1, elec_alpha_num
      det_left_alpha_pseudo_curr(i) = 0.d0
      do n = 1, elec_alpha_num
        imo = mo_left_list_alpha_curr(n)
        c   = slater_matrix_left_alpha_inv_det(i,n)
        det_left_alpha_pseudo_curr(i) = det_left_alpha_pseudo_curr(i) + c * pseudo_mo_term(imo,i)
      enddo
    enddo
  endif

END_PROVIDER

! ---

BEGIN_PROVIDER  [ double precision, det_left_beta_pseudo_curr, (elec_alpha_num+1:elec_num) ]

  BEGIN_DOC
  ! Pseudopotential non-local contribution
  END_DOC

  implicit none
  integer, save    :: ifirst = 0
  integer          :: i, n, imo
  double precision :: c

  if(elec_beta_num == 0) then
    return
  endif

  if (ifirst == 0) then
    ifirst = 1
    det_left_beta_pseudo_curr = 0.d0
  endif

  if (do_pseudo) then
    do i = elec_alpha_num+1, elec_num
      det_left_beta_pseudo_curr(i) = 0.d0
      do n = 1, elec_beta_num
        imo = mo_left_list_beta_curr(n)
        c   = slater_matrix_left_beta_inv_det(i-elec_alpha_num,n)
        det_left_beta_pseudo_curr(i) = det_left_beta_pseudo_curr(i) + c * pseudo_mo_term(imo,i)
      enddo
    enddo
  endif

END_PROVIDER

! ---

 BEGIN_PROVIDER [ double precision , det_left_alpha_value,     (det_alpha_num_8) ]
&BEGIN_PROVIDER [ double precision , det_left_alpha_grad_lapl, (4,elec_alpha_num,det_alpha_num) ]
&BEGIN_PROVIDER [ double precision , det_left_alpha_pseudo,    (elec_alpha_num_8,det_alpha_num_pseudo) ]

  BEGIN_DOC
  ! Values of the alpha determinants
  ! Gradients of the alpha determinants
  ! Laplacians of the alpha determinants
  END_DOC

  implicit none
  integer       :: j
  integer, save :: ifirst = 0

  if (ifirst == 0) then
    ifirst = 1
    det_left_alpha_value     = 0.d0
    det_left_alpha_grad_lapl = 0.d0
    det_left_alpha_pseudo    = 0.d0
  endif

  do j = 1, det_alpha_num

    det_left_i_prev = det_left_i
    det_left_i      = det_alpha_order(j)
    if(j > 1) then
      TOUCH det_left_i
    endif

    det_left_alpha_value(det_left_i)                          = det_left_alpha_value_curr
    det_left_alpha_grad_lapl(1:4,1:elec_alpha_num,det_left_i) = det_left_alpha_grad_lapl_curr(1:4,1:elec_alpha_num)
    if(do_pseudo) then
      det_left_alpha_pseudo(1:elec_alpha_num,det_left_i) = det_left_alpha_pseudo_curr(1:elec_alpha_num)
    endif

  enddo

  det_left_i      = det_alpha_order(1)
  det_left_i_prev = det_alpha_order(1)
  SOFT_TOUCH det_left_i det_left_i_prev

END_PROVIDER

! ---

 BEGIN_PROVIDER [ double precision, det_left_beta_value,     (det_beta_num_8) ]
&BEGIN_PROVIDER [ double precision, det_left_beta_grad_lapl, (4,elec_beta_num,det_beta_num) ]
&BEGIN_PROVIDER [ double precision, det_left_beta_pseudo,    (elec_beta_num_8,det_beta_num_pseudo) ]

  BEGIN_DOC
  ! Values of the beta determinants
  ! Gradients of the beta determinants
  ! Laplacians of the beta determinants
  END_DOC

  implicit none
  integer       :: j
  integer, save :: ifirst = 0

  if(elec_beta_num == 0) then
    det_left_beta_value = 1.d0
    return
  endif

  if(ifirst == 0) then
    ifirst = 1
    det_left_beta_value     = 0.d0
    det_left_beta_grad_lapl = 0.d0
    det_left_beta_pseudo    = 0.d0
  endif

  do j = 1, det_beta_num

    det_left_j_prev = det_left_j
    det_left_j      = det_beta_order(j)
    if(j > 1) then
      TOUCH det_left_j
    endif

    det_left_beta_value(det_left_j)                         = det_left_beta_value_curr
    det_left_beta_grad_lapl(1:4,1:elec_beta_num,det_left_j) = det_left_beta_grad_lapl_curr(1:4,elec_alpha_num+1:elec_num)
    if(do_pseudo) then
      det_left_beta_pseudo(1:elec_beta_num,det_left_j) = det_left_beta_pseudo_curr(elec_alpha_num+1:elec_num)
    endif

  enddo

  det_left_j      = det_beta_order(1)
  det_left_j_prev = det_beta_order(1)
  SOFT_TOUCH det_left_j det_left_j_prev

END_PROVIDER

! ---

 BEGIN_PROVIDER [ double precision, det_left_alpha_lapl_sum, (det_alpha_num_8) ]
&BEGIN_PROVIDER [ double precision, det_left_beta_lapl_sum,  (det_beta_num_8) ]

  BEGIN_DOC
  ! Sum of Laplacian_i per spin-determinant
  END_DOC

  implicit none
  integer :: k

  do k = 1, det_alpha_num
    det_left_alpha_lapl_sum(k) = sum(det_left_alpha_grad_lapl(4,1:elec_alpha_num,k))
  enddo
  do k = 1, det_beta_num
    det_left_beta_lapl_sum(k) = sum(det_left_beta_grad_lapl(4,1:elec_beta_num,k))
  enddo
END_PROVIDER

! ---

 BEGIN_PROVIDER [ double precision, psidet_left_value ]
&BEGIN_PROVIDER [ double precision, psidet_left_inv ]
&BEGIN_PROVIDER [ double precision, psidet_left_grad_lapl, (4,elec_num_8) ]
&BEGIN_PROVIDER [ double precision, pseudo_left_non_local, (elec_num) ]
&BEGIN_PROVIDER [ double precision, CDb_left, (det_alpha_num_8) ]
&BEGIN_PROVIDER [ double precision, DaC_left, (det_beta_num_8) ]

  BEGIN_DOC
  ! Value of the determinantal part of the wave function

  ! Gradient of the determinantal part of the wave function

  ! Laplacian of determinantal part of the wave function

  ! Regularized 1/psi = 1/(psi + 1/psi)

  ! C x D_beta

  ! D_alpha^t x C

  ! D_alpha^t x (C x D_beta)
  END_DOC

  implicit none
  integer          :: i,j,k, l
  integer          :: i1,i2,i3,i4,det_num4
  integer          :: j1,j2,j3,j4
  double precision :: f
  integer, save    :: ifirst=0

  if (ifirst == 0) then
    ifirst = 1
    psidet_left_grad_lapl = 0.d0
    pseudo_left_non_local = 0.d0
  endif

  DaC_left = 0.d0
  CDb_left = 0.d0

  if(det_num < shiftr(det_alpha_num*det_beta_num,2)) then

    det_num4 = iand(det_num,not(3))
    !DIR$ VECTOR ALIGNED
    do k=1,det_num4,4
      i1 = det_coef_matrix_rows(k  )
      i2 = det_coef_matrix_rows(k+1)
      i3 = det_coef_matrix_rows(k+2)
      i4 = det_coef_matrix_rows(k+3)
      j1 = det_coef_matrix_columns(k  )
      j2 = det_coef_matrix_columns(k+1)
      j3 = det_coef_matrix_columns(k+2)
      j4 = det_coef_matrix_columns(k+3)
      if ( (j1 == j2).and.(j1 == j3).and.(j1 == j4) ) then
        f = det_left_beta_value (j1)
        CDb_left(i1) = CDb_left(i1) + det_left_coef_matrix_values(k  )*f
        CDb_left(i2) = CDb_left(i2) + det_left_coef_matrix_values(k+1)*f
        CDb_left(i3) = CDb_left(i3) + det_left_coef_matrix_values(k+2)*f
        CDb_left(i4) = CDb_left(i4) + det_left_coef_matrix_values(k+3)*f

        if ( ((i2-i1) == 1).and.((i3-i1) == 2).and.((i4-i1) == 3) ) then
          DaC_left(j1) = DaC_left(j1) + det_left_coef_matrix_values(k)*det_left_alpha_value(i1) &
          + det_left_coef_matrix_values(k+1)*det_left_alpha_value(i1+1) &
          + det_left_coef_matrix_values(k+2)*det_left_alpha_value(i1+2) &
          + det_left_coef_matrix_values(k+3)*det_left_alpha_value(i1+3)
        else
          DaC_left(j1) = DaC_left(j1) + det_left_coef_matrix_values(k)*det_left_alpha_value(i1) &
          + det_left_coef_matrix_values(k+1)*det_left_alpha_value(i2) &
          + det_left_coef_matrix_values(k+2)*det_left_alpha_value(i3) &
          + det_left_coef_matrix_values(k+3)*det_left_alpha_value(i4)
        endif
      else
        DaC_left(j1) = DaC_left(j1) + det_left_coef_matrix_values(k  )*det_left_alpha_value(i1)
        DaC_left(j2) = DaC_left(j2) + det_left_coef_matrix_values(k+1)*det_left_alpha_value(i2)
        DaC_left(j3) = DaC_left(j3) + det_left_coef_matrix_values(k+2)*det_left_alpha_value(i3)
        DaC_left(j4) = DaC_left(j4) + det_left_coef_matrix_values(k+3)*det_left_alpha_value(i4)
        CDb_left(i1) = CDb_left(i1) + det_left_coef_matrix_values(k  )*det_left_beta_value (j1)
        CDb_left(i2) = CDb_left(i2) + det_left_coef_matrix_values(k+1)*det_left_beta_value (j2)
        CDb_left(i3) = CDb_left(i3) + det_left_coef_matrix_values(k+2)*det_left_beta_value (j3)
        CDb_left(i4) = CDb_left(i4) + det_left_coef_matrix_values(k+3)*det_left_beta_value (j4)
      endif
    enddo

    do k=det_num4+1,det_num
      i = det_coef_matrix_rows(k)
      j = det_coef_matrix_columns(k)
      DaC_left(j) = DaC_left(j) + det_left_coef_matrix_values(k)*det_left_alpha_value(i)
      CDb_left(i) = CDb_left(i) + det_left_coef_matrix_values(k)*det_left_beta_value (j)
    enddo

  else

    if(det_num == 1) then

      DaC_left(1) = det_left_alpha_value_curr
      CDb_left(1) = det_left_beta_value_curr

    else

      call dgemv('T',det_alpha_num,det_beta_num,1.d0,det_left_coef_matrix_dense, &
        size(det_left_coef_matrix_dense,1), det_left_alpha_value, 1, 0.d0, DaC_left, 1)

      call dgemv('N',det_alpha_num,det_beta_num,1.d0,det_left_coef_matrix_dense, &
        size(det_left_coef_matrix_dense,1), det_left_beta_value, 1, 0.d0, CDb_left, 1)

    endif

  endif

  ! Value
  ! -----

  psidet_left_value = 0.d0
  do j = 1, det_beta_num
    psidet_left_value = psidet_left_value + det_left_beta_value(j) * DaC_left(j)
  enddo

  if(use_lr) then
    psidet_left_inv = 1.d10
  else
    if(psidet_left_value == 0.d0) then
      call abrt(irp_here,'Determinantal component of the left wave function is zero.')
    endif
    psidet_left_inv = 1.d0 / psidet_left_value
  endif


  ! Gradients
  ! ---------
  if(det_num .eq. 1) then
    do i = 1, elec_alpha_num
      psidet_left_grad_lapl(1,i) = det_left_alpha_grad_lapl_curr(1,i) * det_left_beta_value_curr
      psidet_left_grad_lapl(2,i) = det_left_alpha_grad_lapl_curr(2,i) * det_left_beta_value_curr
      psidet_left_grad_lapl(3,i) = det_left_alpha_grad_lapl_curr(3,i) * det_left_beta_value_curr
      psidet_left_grad_lapl(4,i) = det_left_alpha_grad_lapl_curr(4,i) * det_left_beta_value_curr
    enddo
    do i = elec_alpha_num+1, elec_num
      psidet_left_grad_lapl(1,i) = det_left_beta_grad_lapl_curr(1,i) * det_left_alpha_value_curr
      psidet_left_grad_lapl(2,i) = det_left_beta_grad_lapl_curr(2,i) * det_left_alpha_value_curr
      psidet_left_grad_lapl(3,i) = det_left_beta_grad_lapl_curr(3,i) * det_left_alpha_value_curr
      psidet_left_grad_lapl(4,i) = det_left_beta_grad_lapl_curr(4,i) * det_left_alpha_value_curr
    enddo
  else
    ! psidet_left_grad_lapl(4,elec_alpha_num) = det_left_alpha_grad_lapl(4,elec_alpha_num,det_alpha_num) @ CDb_left(det_alpha_num)
    call dgemv('N',elec_alpha_num*4,det_alpha_num,1.d0,                    &
        det_left_alpha_grad_lapl,                                          &
        size(det_left_alpha_grad_lapl,1)*size(det_left_alpha_grad_lapl,2), &
        CDb_left, 1, 0.d0, psidet_left_grad_lapl, 1)
    if (elec_beta_num /= 0) then
      call dgemv('N',elec_beta_num*4,det_beta_num,1.d0,                    &
          det_left_beta_grad_lapl,                                         &
          size(det_left_beta_grad_lapl,1)*size(det_left_beta_grad_lapl,2), &
          DaC_left, 1, 0.d0, psidet_left_grad_lapl(1,elec_alpha_num+1), 1)
    endif
  endif

  if(do_pseudo) then
    call dgemv( 'N', elec_alpha_num, det_alpha_num, psidet_left_inv                &
              , det_left_alpha_pseudo, size(det_left_alpha_pseudo, 1), CDb_left, 1 &
              , 0.d0, pseudo_left_non_local, 1)

    if(elec_beta_num /= 0) then
      call dgemv( 'N', elec_beta_num, det_beta_num, psidet_left_inv                &
                , det_left_beta_pseudo, size(det_left_beta_pseudo, 1), DaC_left, 1 &
                , 0.d0, pseudo_left_non_local(elec_alpha_num+1), 1)
    endif
  endif

END_PROVIDER

! ---

BEGIN_PROVIDER  [ double precision, det_left_alpha_grad_lapl_curr, (4,elec_alpha_num) ]

  BEGIN_DOC
  ! Gradient of the current alpha determinant
  END_DOC

  implicit none
  integer :: i, j, k
  integer :: imo, imo2

  !DIR$ VECTOR ALIGNED
  do i = 1, elec_alpha_num
    det_left_alpha_grad_lapl_curr(1,i) = 0.d0
    det_left_alpha_grad_lapl_curr(2,i) = 0.d0
    det_left_alpha_grad_lapl_curr(3,i) = 0.d0
    det_left_alpha_grad_lapl_curr(4,i) = 0.d0
  enddo


  if(iand(elec_alpha_num, 1) == 0) then

    do j = 1, elec_alpha_num, 2
      imo  = mo_left_list_alpha_curr(j  )
      imo2 = mo_left_list_alpha_curr(j+1)
      do i = 1, elec_alpha_num, 2
        !DIR$ VECTOR ALIGNED
        do k = 1, 4
          det_left_alpha_grad_lapl_curr(k,i  ) = det_left_alpha_grad_lapl_curr(k,i)                                          &
                                               + mo_left_grad_lapl_alpha(k,i,imo ) * slater_matrix_left_alpha_inv_det(i,j  ) &
                                               + mo_left_grad_lapl_alpha(k,i,imo2) * slater_matrix_left_alpha_inv_det(i,j+1)
          det_left_alpha_grad_lapl_curr(k,i+1) = det_left_alpha_grad_lapl_curr(k,i+1)                                            &
                                               + mo_left_grad_lapl_alpha(k,i+1,imo ) * slater_matrix_left_alpha_inv_det(i+1,j  ) &
                                               + mo_left_grad_lapl_alpha(k,i+1,imo2) * slater_matrix_left_alpha_inv_det(i+1,j+1)
        enddo
      enddo
    enddo

  else

    do j = 1, elec_alpha_num-1, 2
      imo  = mo_left_list_alpha_curr(j  )
      imo2 = mo_left_list_alpha_curr(j+1)
      do i = 1, elec_alpha_num-1, 2
        !DIR$ VECTOR ALIGNED
        do k = 1, 4
          det_left_alpha_grad_lapl_curr(k,i  ) = det_left_alpha_grad_lapl_curr(k,i)                                          &
                                               + mo_left_grad_lapl_alpha(k,i,imo ) * slater_matrix_left_alpha_inv_det(i,j  ) &
                                               + mo_left_grad_lapl_alpha(k,i,imo2) * slater_matrix_left_alpha_inv_det(i,j+1)
          det_left_alpha_grad_lapl_curr(k,i+1) = det_left_alpha_grad_lapl_curr(k,i+1)                                          &
                                               + mo_left_grad_lapl_alpha(k,i+1,imo )*slater_matrix_left_alpha_inv_det(i+1,j  ) &
                                               + mo_left_grad_lapl_alpha(k,i+1,imo2)*slater_matrix_left_alpha_inv_det(i+1,j+1)
        enddo
      enddo
      i = elec_alpha_num
      !DIR$ VECTOR ALIGNED
      do k = 1, 4
        det_left_alpha_grad_lapl_curr(k,i) = det_left_alpha_grad_lapl_curr(k,i)                                          &
                                           + mo_left_grad_lapl_alpha(k,i,imo ) * slater_matrix_left_alpha_inv_det(i,j  ) &
                                           + mo_left_grad_lapl_alpha(k,i,imo2) * slater_matrix_left_alpha_inv_det(i,j+1)
      enddo
    enddo

    j   = elec_alpha_num
    imo = mo_left_list_alpha_curr(j)
    do i = 1, elec_alpha_num
      !DIR$ VECTOR ALIGNED
      do k = 1, 4
        det_left_alpha_grad_lapl_curr(k,i) = det_left_alpha_grad_lapl_curr(k,i) & 
                                           + mo_left_grad_lapl_alpha(k,i,imo) * slater_matrix_left_alpha_inv_det(i,j)
      enddo
    enddo

  endif

END_PROVIDER

! ---

BEGIN_PROVIDER  [ double precision, det_left_beta_grad_lapl_curr, (4,elec_alpha_num+1:elec_num) ]


  BEGIN_DOC
  ! Gradient and Laplacian of the current beta determinant
  END_DOC

  implicit none
  integer :: i, j, k, l
  integer :: imo, imo2

  !DIR$ VECTOR ALIGNED
  do i = elec_alpha_num+1, elec_num
    det_left_beta_grad_lapl_curr(1,i) = 0.d0
    det_left_beta_grad_lapl_curr(2,i) = 0.d0
    det_left_beta_grad_lapl_curr(3,i) = 0.d0
    det_left_beta_grad_lapl_curr(4,i) = 0.d0
  enddo

  if(iand(elec_beta_num,1) == 0) then

    do j = 1, elec_beta_num, 2
      imo  = mo_left_list_beta_curr(j  )
      imo2 = mo_left_list_beta_curr(j+1)
      !DIR$ LOOP COUNT (16)
      do i = elec_alpha_num+1, elec_num, 2
        l = i-elec_alpha_num
        !DIR$ VECTOR ALIGNED
        do k = 1, 4
          det_left_beta_grad_lapl_curr(k,i) = det_left_beta_grad_lapl_curr(k,i)                                         &
                                            + mo_left_grad_lapl_beta(k,i,imo ) * slater_matrix_left_beta_inv_det(l,j  ) &
                                            + mo_left_grad_lapl_beta(k,i,imo2) * slater_matrix_left_beta_inv_det(l,j+1)
          det_left_beta_grad_lapl_curr(k,i+1) = det_left_beta_grad_lapl_curr(k,i+1)                                         &
                                              + mo_left_grad_lapl_beta(k,i+1,imo ) * slater_matrix_left_beta_inv_det(l+1,j) &
                                              + mo_left_grad_lapl_beta(k,i+1,imo2) * slater_matrix_left_beta_inv_det(l+1,j+1)
        enddo
      enddo
    enddo

  else

    do j = 1, elec_beta_num-1, 2
      imo  = mo_left_list_beta_curr(j  )
      imo2 = mo_left_list_beta_curr(j+1)
      !DIR$ LOOP COUNT (16)
      do i = elec_alpha_num+1, elec_num-1, 2
        l = i-elec_alpha_num
        !DIR$ VECTOR ALIGNED
        do k = 1, 4
          det_left_beta_grad_lapl_curr(k,i) = det_left_beta_grad_lapl_curr(k,i)                                         &
                                            + mo_left_grad_lapl_beta(k,i,imo ) * slater_matrix_left_beta_inv_det(l,j  ) &
                                            + mo_left_grad_lapl_beta(k,i,imo2) * slater_matrix_left_beta_inv_det(l,j+1)
          det_left_beta_grad_lapl_curr(k,i+1) = det_left_beta_grad_lapl_curr(k,i+1)                                           &
                                              + mo_left_grad_lapl_beta(k,i+1,imo ) * slater_matrix_left_beta_inv_det(l+1,j  ) &
                                              + mo_left_grad_lapl_beta(k,i+1,imo2) * slater_matrix_left_beta_inv_det(l+1,j+1)
        enddo
      enddo
      i = elec_num
      l = elec_num-elec_alpha_num
      !DIR$ VECTOR ALIGNED
      do k = 1, 4
        det_left_beta_grad_lapl_curr(k,i) = det_left_beta_grad_lapl_curr(k,i)                                         &
                                          + mo_left_grad_lapl_beta(k,i,imo ) * slater_matrix_left_beta_inv_det(l,j  ) &
                                          + mo_left_grad_lapl_beta(k,i,imo2) * slater_matrix_left_beta_inv_det(l,j+1)
      enddo
    enddo

    j   = elec_beta_num
    imo = mo_left_list_beta_curr(j)
    do i = elec_alpha_num+1, elec_num
      l = i-elec_alpha_num
      !DIR$ VECTOR ALIGNED
      do k = 1, 4
        det_left_beta_grad_lapl_curr(k,i) = det_left_beta_grad_lapl_curr(k,i) &
                                          + mo_left_grad_lapl_beta(k,i,imo) * slater_matrix_left_beta_inv_det(l,j)
      enddo
    enddo

  endif

END_PROVIDER

! ---

 BEGIN_PROVIDER [ double precision, single_det_left_value ]
&BEGIN_PROVIDER [ double precision, single_det_left_grad, (elec_num_8,3) ]
&BEGIN_PROVIDER [ double precision, single_det_left_lapl, (elec_num) ]

  BEGIN_DOC
  ! Value of a single determinant wave function from the 1st determinant
  END_DOC

  implicit none
  integer :: i

  det_left_i = 1
  det_left_j = 1

  single_det_left_value = det_left_alpha_value_curr * det_left_beta_value_curr
  do i = 1, elec_alpha_num
    single_det_left_grad(i,1)  = det_left_alpha_grad_lapl_curr(1,i) * det_left_beta_value_curr
    single_det_left_grad(i,2)  = det_left_alpha_grad_lapl_curr(2,i) * det_left_beta_value_curr
    single_det_left_grad(i,3)  = det_left_alpha_grad_lapl_curr(3,i) * det_left_beta_value_curr
    single_det_left_lapl(i)    = det_left_alpha_grad_lapl_curr(4,i) * det_left_beta_value_curr
  enddo
  do i = elec_alpha_num+1, elec_num
    single_det_left_grad(i,1)  = det_left_alpha_value_curr * det_left_beta_grad_lapl_curr(1,i)
    single_det_left_grad(i,2)  = det_left_alpha_value_curr * det_left_beta_grad_lapl_curr(2,i)
    single_det_left_grad(i,3)  = det_left_alpha_value_curr * det_left_beta_grad_lapl_curr(3,i)
    single_det_left_lapl(i)    = det_left_alpha_value_curr * det_left_beta_grad_lapl_curr(4,i)
  enddo

END_PROVIDER

! ---

BEGIN_PROVIDER [ double precision, psidet_left_lapl ]

  BEGIN_DOC
  ! Laplacian of the wave functionwithout Jastrow
  END_DOC

  implicit none
  integer :: j

  psidet_left_lapl = 0.d0
  do j = 1, elec_num
    psidet_left_lapl = psidet_left_lapl + psidet_left_grad_lapl(4,j)
  enddo

END_PROVIDER

! ---

