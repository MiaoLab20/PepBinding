# PepBinding: A workflow for predicting peptide binding structures by combining Peptide Docking and Peptide Gaussian Accelerated Molecular Dynamics Simulations
The “PepBinding” is a workflow for predicting peptide binding structures, which combines peptide docking, all-atom enhanced sampling simulations using the Peptide Gaussian accelerated Molecular Dynamics (Pep-GaMD) method and structural clustering. PepBinding has been demonstrated on seven distinct model peptides. In peptide docking using HPEPDOCK, the lowest peptide backbone root-mean-square deviations (RMSDs) of their bound conformations relative to X-ray structures ranged from 3.8 Å to 16.0 Å, corresponding to the medium to inaccurate quality models according to the Critical Assessment of PRediction of Interactions (CAPRI) criteria. The Pep-GaMD simulations performed for only 200 ns  significantly improved the docking models, resulting in five medium and two acceptable quality models. Therefore, PepBinding is an efficient workflow for predicting peptide binding structures.

An example test folder that contains the input pdb files for both receptor and peptide obtaeind from HPEPDOCK is included in this repository. 

A run script can be found in pepbinding.sh. To run the test folder, simply copy all the scripts (pepbinding.sh, 01-run-generate-system.sh, 02-run-PepGaMD.sh and 03-cluster.sh) and run the following commands:

sh ./pepbinding.sh rec.pdb peptide.pdb

The details can be found at the reference below. 

Reference:
Jinan Wang, Kushal Koirala, Hung N. Do, Yinglong Miao. PepBinding: A workflow for predicting peptide binding structures by combining Peptide Docking and Peptide Gaussian Accelerated Molecular Dynamics Simulations (In preparion)

