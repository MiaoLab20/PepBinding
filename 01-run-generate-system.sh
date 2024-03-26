#!/bin/sh
#xxx get receptor and peptide docking model


if [ $# != 2 ]
 then
  echo "./01-run-generate-system.sh rec.pdb peptide.pdb"
  exit
fi
recfile=$1
pepfile=$2

mkdir -p tleap
##cp the original file into the same file name for tleap
cp ${recfile} tleap/rec.pdb
cp ${pepfile} tleap/pep-docked.pdb
cd tleap

##generate the system using tleap, the force field and water model could be modified here

echo "source leaprc.protein.ff14SB
source leaprc.water.tip3p
rec=loadpdb rec.pdb
pep=loadpdb pep-docked.pdb
com=combine{rec pep}
charge com
saveamberparm rec rec.prmtop rec.inpcrd
saveamberparm pep pep.prmtop pep.inpcrd
saveamberparm com comp-now.prmtop comp-now.inpcrd
charge com
solvatebox com TIP3PBOX 15
addions com Na+ 0
addions com Cl- 0
saveamberparm com complex.prmtop complex.inpcrd
savepdb com complex.pdb
quit"> tleap.in
tleap -s -f tleap.in
cd ..

