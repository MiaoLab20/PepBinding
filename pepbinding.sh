#!/bin/sh
##coded by Jinan Wang #######
##

if [ $# != 2 ]
 then
  echo "./pepbinding.sh rec.pdb peptide.pdb"
  exit
fi
recfile=$1
pepfile=$2


chmod +x 01-run-generate-system.sh  02-run-PepGaMD.sh  03-cluster.sh 
./01-run-generate-system.sh ${recfile} ${pepfile}
./02-run-PepGaMD.sh
./03-cluster.sh


