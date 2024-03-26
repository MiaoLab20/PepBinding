#!/bin/bash

##generate a new folder for running Pep-GaMD equilibration
mkdir -p  gamd-equil

## copy all the needed file for running Pep-GaMD equilibration
cp tleap/complex.prmtop tleap/rec.prmtop tleap/pep.prmtop tleap/comp-now.prmtop tleap/complex.inpcrd tleap/rec.inpcrd tleap/pep.inpcrd tleap/comp-now.inpcrd gamd-equil
cd gamd-equil

##to get the atom numbers of receptor, peptide and complex 
natoms_com=`awk '{if(NR==7)print $1}' complex.prmtop` 
natoms_rec=`awk '{if(NR==7)print $1}' rec.prmtop`
natoms_pep=`awk '{if(NR==7)print $1}' pep.prmtop`
natoms_save=`awk '{if(NR==7)print $1}' comp-now.prmtop`
pep_atoms=`echo ${natoms_rec} ${natoms_pep}|awk '{printf("%d-%d\n",$1+1,$1+$2)}'`
igamd=15     ##gamd mode
ntave=250000  
ntcmd=1000000 ##4*ntave
ntcmdprep=500000 ##2*ntave
ntebprep=500000 ##2*ntave
nteb=9000000  ##for learning the system multiply ntave
nstlim=10000000 ##for the all MD steps


echo "minimization simulation
&cntrl
 imin=1,        ! Minimize the initial structure
 maxcyc=100000, ! Maximum number of cycles for minimization
 ncyc=50000,    ! Switch from steepest descent to conjugate gradient minimization after ncyc cycles
 ntb=1,         ! Constant volume
 ntp=0,         ! No pressure scaling
 ntf=1,         ! Complete force evaluation
 ntc=1,         ! No SHAKE
 ntpr=5000,     ! Print to mdout every ntpr steps
 ntwr=5000,     ! Write a restart file every ntwr steps
 cut=9.0,       ! nonbonded cutoff, in angstroms

 ! Wrap coordinates when printing them to the same unit cell
 iwrap=1,
 ntwprt = ${natoms_save},
 ntr=1, restraintmask='(@1-${natoms_save}&!@H=)',
 restraint_wt=1.0
 /">01-min.in

 echo "minimization simulation without any constrains
&cntrl
 imin=1,        ! Minimize the initial structure
 maxcyc=100000, ! Maximum number of cycles for minimization
 ncyc=50000,    ! Switch from steepest descent to conjugate gradient minimization after ncyc cycles
 ntb=1,         ! Constant volume
 ntp=0,         ! No pressure scaling
 ntf=1,         ! Complete force evaluation
 ntc=1,         ! No SHAKE
 ntpr=5000,     ! Print to mdout every ntpr steps
 ntwr=5000,     ! Write a restart file every ntwr steps
 cut=9.0,       ! nonbonded cutoff, in angstroms

 ! Wrap coordinates when printing them to the same unit cell
 iwrap=1,
 ntwprt = ${natoms_save},
 /">02-min.in

echo "heat the system to 300K for 500ps and then equilbriation for 500ps in the 300K
&cntrl
 imin=0,irest=0,ntx=1,
 nstlim=500000,dt=0.002,
 ntc=2,ntf=2,
 ntb=1,
 cut=9.0,      ! nonbonded cutoff, in angstroms
 ntpr=5000, ntwx=5000,
 ntt=3, gamma_ln=2.0,
 tempi=0.0, temp0=300.0,
 ntr=1, restraintmask='(@1-${natoms_save}&!@H=)',
 restraint_wt=1.0,
 nmropt=1,
 ! Wrap coordinates when printing them to the same unit cell
 iwrap=1,
 ntwprt = ${natoms_save},
 /
 &wt TYPE='TEMP0', istep1=0, istep2=500000,
   value1=0.1, value2=300.0, /
 &wt TYPE='END' /">03-nvt.in

echo "density the system for another 1000ps
&cntrl
 imin=0,        ! No minimization
 irest=1,       ! This IS a new MD simulation
 ntx=5,         ! read coordinates only
 ! Temperature control
 ntt=3,         ! Langevin dynamics
 gamma_ln=1.0,  ! Friction coefficient (ps^-1)
 tempi=300.0,   ! Initial temperature
 temp0=300.0,   ! Target temperature
 ig=-1,         ! random seed

 ! Potential energy control
 cut=9.0,       ! nonbonded cutoff, in Angstroms
 ! MD settings
 nstlim=500000, ! simulation length
 dt=0.002,      ! time step (ps)
 ! SHAKE
 ntc=2,         ! Constrain bonds containing hydrogen
 ntf=2,         ! Do not calculate forces of bonds containing hydrogen
 ! Control how often information is printed
 ntpr=1000,     ! Print energies every 1000 steps
 ntwx=1000,     ! Print coordinates every 1000 steps to the trajectory
 ntwr=5000,    ! Print a restart file every 10K steps (can be less frequent)
 ntxo=2,        ! Write NetCDF format
 ioutfm=1,      ! Write NetCDF format (always do this!)

 ! Wrap coordinates when printing them to the same unit cell
  iwrap=1,
  ntwprt = $natoms_save,

  ! Constant pressure control. Note that ntp=3 requires barostat=1
  barostat=1,    ! Berendsen... change to 2 for MC barostat
  ntp=1,         ! 1=isotropic, 2=anisotropic, 3=semi-isotropic w/ surften
  pres0=1.0,     ! Target external pressure, in bar
  taup=0.5,      ! Berendsen coupling constant (ps)
  ntr=1, restraintmask='(@1-${natoms_save}&!@H=)',
  restraint_wt=1.0,
  /">04-npt.in

echo "density the system for another 2000ps without any constraints
&cntrl
 imin=0,        ! No minimization
 irest=1,       ! This IS a new MD simulation
 ntx=5,         ! read coordinates only
 ! Temperature control
 ntt=3,         ! Langevin dynamics
 gamma_ln=1.0,  ! Friction coefficient (ps^-1)
 tempi=300.0,   ! Initial temperature
 temp0=300.0,   ! Target temperature
 ig=-1,         ! random seed
 ! Potential energy control
 cut=9.0,       ! nonbonded cutoff, in angstroms
 ! MD settings
 nstlim=1000000,! simulation length
 dt=0.002,      ! time step (ps)
 ! SHAKE
 ntc=2,         ! Constrain bonds containing hydrogen
 ntf=2,         ! Do not calculate forces of bonds containing hydrogen
 ! Control how often information is printed
  ntpr=1000,    ! Print energies every 1000 steps
  ntwx=1000,    ! Print coordinates every 1000 steps to the trajectory
  ntwr=5000,    ! Print a restart file every 10K steps (can be less frequent)
  ntxo=2,       ! Write NetCDF format
  ioutfm=1,     ! Write NetCDF format (always do this!)
  ! Wrap coordinates when printing them to the same unit cell
  iwrap=1,
  ntwprt = $natoms_save,
  ! Constant pressure control. Note that ntp=3 requires barostat=1
  barostat=1,    ! Berendsen... change to 2 for MC barostat
  ntp=1,         ! 1=isotropic, 2=anisotropic, 3=semi-isotropic w/ surften
  pres0=1.0,     ! Target external pressure, in bar
  taup=0.5,      ! Berendsen coupling constant (ps)
  /">05-cmd.in
  
echo "GaMD equilibration simulation
 &cntrl
    imin=0,        ! No minimization
    irest=0,       ! This IS a new MD simulation
    ntx=1,         ! read coordinates only

    ! Temperature control
    ntt=3,         ! Langevin dynamics
    gamma_ln=1.0,  ! Friction coefficient (ps^-1)
    tempi=300.0,   ! Initial temperature
    temp0=300.0,   ! Target temperature
    ig=-1,         ! random seed

    ! Potential energy control
    cut=9.0,      ! nonbonded cutoff, in angstroms

    ! MD settings
    nstlim=${nstlim}, ! simulation length
    dt=0.002,      ! time step (ps)

    ! SHAKE
    ntc=2,         ! Constrain bonds containing hydrogen
    ntf=1,         ! Do not calculate forces of bonds containing hydrogen

    ! Control how often information is printed
    ntpr=500,     ! Print energies every 500 steps
    ntwx=500,     ! Print coordinates every 500 steps to the trajectory
    ntwr=5000,    ! Print a restart file every 10K steps (can be less frequent)
    ntxo=2,        ! Write NetCDF format
    ioutfm=1,      ! Write NetCDF format (always do this!)

    ! Wrap coordinates when printing them to the same unit cell
    iwrap=1,
    ntwprt = $natoms_save,

    ! Constant pressure control. Note that ntp=3 requires barostat=1
    barostat=1,    ! Berendsen... change to 2 for MC barostat
    ntp=1,         ! 1=isotropic, 2=anisotropic, 3=semi-isotropic w/ surften
    pres0=1.0,     ! Target external pressure, in bar
    taup=0.5,      ! Berendsen coupling constant (ps)

    ! GaMD parameters
    ntcmd = ${ntcmd}, nteb = ${nteb}, ntave = $ntave,
    ntcmdprep = ${ntcmdprep}, ntebprep = ${ntebprep},
    igamd = 15, irest_gamd = 0,
    sigma0P = 6.0, sigma0D = 6.0, iEP = 1, iED = 1,
    gti_cpu_output = 0, gti_add_sc = 1,
    icfe = 1,
    ifsc = 1,
    timask1 = '@${pep_atoms}',
    scmask1 = '@${pep_atoms}',
    timask2 = '',
    scmask2 = '',
 /
" > md.in
echo "GaMD production simulation
 &cntrl
    imin=0,        ! No minimization
    irest=0,       ! This IS a new MD simulation
    ntx=1,         ! read coordinates only

    ! Temperature control
    ntt=3,         ! Langevin dynamics
    gamma_ln=1.0,  ! Friction coefficient (ps^-1)
    tempi=300.0,   ! Initial temperature
    temp0=300.0,   ! Target temperature
    ig=-1,         ! random seed

    ! Potential energy control
    cut=9.0,      ! nonbonded cutoff, in angstroms

    ! MD settings
    nstlim=100000000, ! simulation length
    dt=0.002,      ! time step (ps)

    ! SHAKE
    ntc=2,         ! Constrain bonds containing hydrogen
    ntf=1,         ! Do not calculate forces of bonds containing hydrogen

    ! Control how often information is printed
    ntpr=500,     ! Print energies every 1000 steps
    ntwx=500,     ! Print coordinates every 1000 steps to the trajectory
    ntwr=5000,    ! Print a restart file every 10K steps (can be less frequent)
    ntxo=2,        ! Write NetCDF format
    ioutfm=1,      ! Write NetCDF format (always do this!)

    ! Wrap coordinates when printing them to the same unit cell
    iwrap=1,
    ntwprt = $natoms_save,

    ! Constant pressure control. Note that ntp=3 requires barostat=1
    barostat=1,    ! Berendsen... change to 2 for MC barostat
    ntp=1,         ! 1=isotropic, 2=anisotropic, 3=semi-isotropic w/ surften
    pres0=1.0,     ! Target external pressure, in bar
    taup=0.5,      ! Berendsen coupling constant (ps)

    ! GaMD parameters
    ntcmd = 0, nteb = 0, ntave = $ntave,
    ntcmdprep = 0, ntebprep = 0,
    igamd = 15, irest_gamd = 1,
    sigma0P = 6.0, sigma0D = 6.0, iEP = 1, iED = 1,
    gti_cpu_output = 0, gti_add_sc = 1,
    icfe = 1,
    ifsc = 1,
    timask1 = '@${pep_atoms}',
    scmask1 = '@${pep_atoms}',
    timask2 = '',
    scmask2 = '',
 /
" > gamd-restart.in
echo "#!/bin/sh
##please modify the following environment variables
source \${AMBERHOME}/amber.sh
cd gamd-equil
pmemd.cuda -O -i 01-min.in -p complex.prmtop -c complex.inpcrd -o 01-min.out -x 01-min.nc -ref complex.inpcrd -r 01-min.rst
pmemd.cuda -O -i 02-min.in -p complex.prmtop -c 01-min.rst -o 02-min.out -x 02-min.nc -ref 01-min.rst -r 02-min.rst
pmemd.cuda -O -i 03-nvt.in -p complex.prmtop -c 02-min.rst -o 03-nvt.out -x 03-nvt.nc -ref 02-min.rst -r 03-nvt.rst
pmemd.cuda -O -i 04-npt.in -p complex.prmtop -c 03-nvt.rst -o 04-npt.out -x 04-npt.nc -ref 03-nvt.rst -r 04-npt.rst
pmemd.cuda -O -i 05-cmd.in -p complex.prmtop -c 04-npt.rst -o 05-cmd.out -x 05-cmd.nc -r 05-cmd.rst
##GaMD equilibration
pmemd.cuda -O -i md.in -p complex.prmtop -c 05-cmd.rst -o md.out -r gamd-1.rst -x md-1.nc -gamd gamd-1.log
">run-GaMD-equil.sh
chmod +x run-GaMD-equil.sh

##run one the equilibration and pep-GaMD equilibration simulations
./run-GaMD-equil.sh
cd ../

## GaMD production, will have three replicas in three individula folders
mkdir sim1 sim2 sim3
echo "#!/bin/sh
#please modify the following environment variables
source \${AMBERHOME}/amber.sh
for i in \`echo sim1 sim2 sim3\`
do
cp gamd-equil/complex.prmtop gamd-equil/gamd-1.rst gamd-equil/gamd-restart.dat gamd-equil/gamd-restart.in \$i
cd \$i
pmemd.cuda -O -i gamd-restart.in -p complex.prmtop -c gamd-1.rst -o gamd-2.out -x md-2.nc -r gamd-2.rst -gamd gamd-2.log
cd ..
done
">run-GaMD-prod.sh
chmod +x run-GaMD-prod.sh
./run-GaMD-prod.sh
