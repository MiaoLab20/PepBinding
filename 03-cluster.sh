#!/bin/sh

natoms_com=`awk '{if(NR==7)print $1}' complex.prmtop`
natoms_rec=`awk '{if(NR==7)print $1}' rec.prmtop`
natoms_pep=`awk '{if(NR==7)print $1}' pep.prmtop`
natoms_save=`awk '{if(NR==7)print $1}' comp-now.prmtop`
pep_atoms=`echo ${natoms_rec} ${natoms_pep}|awk '{printf("%d-%d\n",$1+1,$1+$2)}'`

rm -r top-confs clustering.cpptraj
mkdir -p top-confs

echo "parm comp-now.prmtop
reference comp-now.inpcrd
trajin sim1/md-2.nc 
trajin sim2/md-2.nc 
trajin sim3/md-2.nc
autoimage
rms reference mass @1-${natoms_rec}&@CA,N,O,C
cluster C0 hieragglo averagelinkage clusters 10 epsilonplot top-confs/epsilonplot.dat rms @${pep_atoms}&@CA,N,O,C nofit sieve 500 out top-confs/cnumvtime.dat summary top-confs/summary.dat info top-confs/info.dat singlerepout top-confs/top-confs.pdb singlerepfmt pdb
" > extract-top-confs.cpptraj
cpptraj <extract-top-confs.cpptraj

##for the reweighting
##get the correspinding gamd.log file for reweighting
cat sim1/gamd-2.log sim2/gamd-2.log sim3/gamd-2.log |grep -v "#" > top-confs/gamd-all.log

cd top-confs
grep -v  "#" cnumvtime.dat> cnumvtime2.dat

#chmod +x do-reweighted-1d.sh
#./do-reweighted-1d.sh cnumvtime2.dat
echo "directory: $workfolder"
rm -v weights.dat Phi.dat Psi.dat
rm -v weights0.dat Phi0.dat Psi0.dat dist0.dat
nlines_gamd_eq=0
nlines_cmd=0
nlines_header_xvg=0
nlines_all=`wc -l gamd-all.log |  awk '{print $1}'`
nlines=$(expr $nlines_all - $nlines_gamd_eq)
nlines_reweight=$nlines
nlines_gamd=$(expr $nlines_reweight + $nlines_gamd_eq)
nlines_nc=$(expr $nlines_reweight + $nlines_gamd_eq + $nlines_cmd + 1)
nlines_vmd=$(expr $nlines_reweight + $nlines_gamd_eq + $nlines_cmd )
nlines_xvg=$(expr $nlines_reweight + $nlines_gamd_eq + $nlines_cmd + $nlines_header_xvg )
echo "nlines_gamd, nlines_nc, nlines_xvg = $nlines_gamd, $nlines_nc, $nlines_xvg" | tee -a reweight_variable.log

# calculate weights
ncstep=1
#modified to exclude the large boost energy frame 
tail -n $nlines_reweight gamd-all.log | awk "NR%$ncstep==0" | awk '{if($7>=100)print "nan                " $2  "             " ($8+$7);else print ($8+$7)/(0.001987*300)"                " $2  "             " ($8+$7)}' > weights0.dat
tail -n $nlines_reweight cnumvtime2.dat | awk "NR%$ncstep==0" | awk '{print $2}' >> Phi0.dat
cp -v Phi0.dat dist0.dat
paste Phi0.dat  weights0.dat dist0.dat > reweight-data.dat
grep -v nan reweight-data.dat | grep -v "e+" > reweight-data-noNaN.dat
awk '{print $1}' reweight-data-noNaN.dat > Phi.dat
awk '{print $2 "             " $3 "             " $4}' reweight-data-noNaN.dat > weights.dat

## reweight
##to get the xmin and xmax
xmin=0
xmax=`sort -n -k1 Phi.dat|tail -1|awk '{print $1+1.0}'`
Emax=100.0
binx=1
cutoff=500
echo "xmin xmax for this file"
python PyReweighting-1D.py -input Phi.dat -disc ${binx} -Xdim $xmin $xmax  -Emax $Emax  -cutoff $cutoff -job amdweight_CE -weight weights.dat

echo "parm ../tleap/comp-now.prmtop
reference ../tleap/comp-now.inpcrd
trajin ../sim1/md-2.nc 
trajin ../sim2/md-2.nc 
trajin ../sim3/md-2.nc
autoimage
rms reference mass @CA"> extract-ranked-cluster.in

#awk '{if(NR>=6)print $0}' pmf-c2-Phi.dat.xvg |sort -n -k2 |awk '{printf("%d\t%8.2f\n",$1,$2)}'>pmf-rank.dat
clusters=`awk '{if(NR<=10)print $1}' pmf-rank.dat | while read l 
do 
awk -v ncluster=$l '{if($1==ncluster)printf("%d,",$6)}' summary.dat
done`
echo "trajout cluster-ranked.pdb onlyframes $clusters">> extract-ranked-cluster.in

cpptraj <extract-ranked-cluster.in




