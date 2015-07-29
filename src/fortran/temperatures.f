!
!     CalculiX - A 3-dimensional finite element program
!              Copyright (C) 1998-2015 Guido Dhondt
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation(version 2);
!     
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of 
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
!     GNU General Public License for more details.
!
!     You should have received a copy of the GNU General Public License
!     along with this program; if not, write to the Free Software
!     Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
!
      subroutine temperatures(inpc,textpart,set,istartset,iendset,
     &  ialset,nset,t0,t1,nk,ithermal,iamt1,amname,nam,inoelfree,nk_,
     &  nmethod,temp_flag,istep,istat,n,iline,ipol,inl,ipoinp,inp,
     &  nam_,namtot_,namta,amta,ipoinpc,t1g)
!
!     reading the input deck: *TEMPERATURE
!
      implicit none
!
      logical temp_flag,user,submodel
!
      character*1 inpc(*)
      character*80 amname(*),amplitude
      character*81 set(*),noset
      character*132 textpart(16)
!
      integer istartset(*),iendset(*),ialset(*),iamt1(*),nmethod,
     &  nset,nk,ithermal,istep,istat,n,key,i,j,k,l,nam,ipoinpc(0:*),
     &  iamplitude,ipos,inoelfree,nk_,iline,ipol,inl,ipoinp(2,*),
     &  inp(3,*),nam_,namtot,namtot_,namta(3,*),idelay,iglobstep
!
      real*8 t0(*),t1(*),temperature,tempgrad1,tempgrad2,amta(2,*),
     &  t1g(2,*)
!
      iamplitude=0
      idelay=0
      user=.false.
      iglobstep=0
      submodel=.false.
!
      if(nmethod.eq.3) then
         write(*,*) '*ERROR reading *TEMPERATURE: temperature'
         write(*,*) '       loading is not allowed in a linear'
         write(*,*) '       buckling step; perform a static'
         write(*,*) '       nonlinear calculation instead'
         call exit(201)
      endif
!
      if(istep.lt.1) then
         write(*,*) '*ERROR reading *TEMPERATURE: *TEMPERATURE'
         write(*,*) '  should only be used within a STEP'
         call exit(201)
      endif
!
      if(ithermal.ne.1) then
         write(*,*) '*ERROR reading *TEMPERATURE: a *TEMPERATURE'
         write(*,*) '  card is detected but no thermal'
         write(*,*) '  *INITIAL CONDITIONS are given'
         call exit(201)
      endif
!
      do i=2,n
         if((textpart(i).eq.'OP=NEW').and.(.not.temp_flag)) then
            do j=1,nk
               t1(j)=t0(j)
            enddo
         elseif(textpart(i)(1:10).eq.'AMPLITUDE=') then
            read(textpart(i)(11:90),'(a80)') amplitude
            do j=nam,1,-1
               if(amname(j).eq.amplitude) then
                  iamplitude=j
                  exit
               endif
            enddo
            if(j.eq.0) then
               write(*,*)
     &           '*ERROR reading *TEMPERATURE: nonexistent amplitude'
               write(*,*) '  '
               call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
               call exit(201)
            endif
            iamplitude=j
         elseif(textpart(i)(1:10).eq.'TIMEDELAY=') THEN
            if(idelay.ne.0) then
               write(*,*) 
     &           '*ERROR reading *TEMPERATURE: the parameter TIME'
               write(*,*) '       DELAY is used twice in the same'
               write(*,*) '       keyword; '
               call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
               call exit(201)
            else
               idelay=1
            endif
            nam=nam+1
            if(nam.gt.nam_) then
               write(*,*) '*ERROR reading *TEMPERATURE: increase nam_'
               call exit(201)
            endif
            amname(nam)='
     &                                 '
            if(iamplitude.eq.0) then
               write(*,*) 
     &           '*ERROR reading *TEMPERATURE: time delay must be'
               write(*,*) '       preceded by the amplitude parameter'
               call exit(201)
            endif
            namta(3,nam)=sign(iamplitude,namta(3,iamplitude))
            iamplitude=nam
            if(nam.eq.1) then
               namtot=0
            else
               namtot=namta(2,nam-1)
            endif
            namtot=namtot+1
            if(namtot.gt.namtot_) then
               write(*,*) '*ERROR temperatures: increase namtot_'
               call exit(201)
            endif
            namta(1,nam)=namtot
            namta(2,nam)=namtot
            read(textpart(i)(11:30),'(f20.0)',iostat=istat) 
     &           amta(1,namtot)
            if(istat.gt.0) call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
         elseif(textpart(i)(1:4).eq.'USER') then
            user=.true.
         elseif(textpart(i)(1:8).eq.'SUBMODEL') then
            submodel=.true.
         elseif(textpart(i)(1:5).eq.'STEP=') then
            read(textpart(i)(6:15),'(i10)',iostat=istat) iglobstep
            if(istat.gt.0) call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
         else
            write(*,*) 
     &        '*WARNING reading *TEMPERATURE: parameter not recognized:'
            write(*,*) '         ',
     &                 textpart(i)(1:index(textpart(i),' ')-1)
            call inputwarning(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
         endif
      enddo
!
!     check whether global step was specified for submodel
!
      if((submodel).and.(iglobstep.eq.0)) then
         write(*,*) '*ERROR reading *TEMPERATURE: no global step'
         write(*,*) '       step specified for the submodel'
         call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
      endif
!
!     storing the step for submodels in iamboun
!
      if(submodel) iamplitude=iglobstep
!
      if(user.and.(iamplitude.ne.0)) then
         write(*,*) 
     &     '*WARNING reading *TEMPERATURE: no amplitude definition is'
         write(*,*) '          allowed for temperatures defined by a'
         write(*,*) '          user routine'
         iamplitude=0
      endif
!
      do
         call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &        ipoinp,inp,ipoinpc)
         if((istat.lt.0).or.(key.eq.1)) return
         read(textpart(2)(1:20),'(f20.0)',iostat=istat) temperature
         if(istat.gt.0) call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
!
!        dummy temperature consisting of the first primes
!
         if(user) temperature=1.2357111317d0
         if(submodel) temperature=1.9232931374d0
!
         if(inoelfree.ne.0) then
            tempgrad1=0.d0
            tempgrad2=0.d0
            if(n.gt.2) then
               read(textpart(3)(1:20),'(f20.0)',iostat=istat) tempgrad1
               if(istat.gt.0) call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
            endif
            if(n.gt.3) then
               read(textpart(4)(1:20),'(f20.0)',iostat=istat) tempgrad2
               if(istat.gt.0) call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
            endif
         endif
!            
         read(textpart(1)(1:10),'(i10)',iostat=istat) l
         if(istat.eq.0) then
            if(l.gt.nk) then
               write(*,*) '*WARNING reading *TEMPERATURE: node ',l
               write(*,*) '         exceeds the largest defined ',
     &            'node number'
               cycle
            endif
            t1(l)=temperature
            if(nam.gt.0) iamt1(l)=iamplitude
            if(inoelfree.ne.0) then
               t1g(1,l)=tempgrad1
               t1g(2,l)=tempgrad2
            endif
         else
            read(textpart(1)(1:80),'(a80)',iostat=istat) noset
            noset(81:81)=' '
            ipos=index(noset,' ')
            noset(ipos:ipos)='N'
            do i=1,nset
               if(set(i).eq.noset) exit
            enddo
            if(i.gt.nset) then
               noset(ipos:ipos)=' '
               write(*,*) '*ERROR reading *TEMPERATURE: node set ',noset
               write(*,*) '       has not yet been defined. '
               call inputerror(inpc,ipoinpc,iline,
     &"*TEMPERATURE%")
               call exit(201)
            endif
            do j=istartset(i),iendset(i)
               if(ialset(j).gt.0) then
                  t1(ialset(j))=temperature
                  if(nam.gt.0) iamt1(ialset(j))=iamplitude
                  if(inoelfree.ne.0) then
                     t1g(1,ialset(j))=tempgrad1
                     t1g(2,ialset(j))=tempgrad2
                  endif
               else
                  k=ialset(j-2)
                  do
                     k=k-ialset(j)
                     if(k.ge.ialset(j-1)) exit
                     t1(k)=temperature
                     if(nam.gt.0) iamt1(k)=iamplitude
                     if(inoelfree.ne.0) then
                        t1g(1,k)=tempgrad1
                        t1g(2,k)=tempgrad2
                     endif
                  enddo
               endif
            enddo
         endif
      enddo
!
      return
      end

