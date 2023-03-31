#!/bin/bash
#SBATCH --job-name=Test_Job
#SBATCH --partition hpc --nodes=2
#SBATCH -o output.%j
#SBATCH -e error.%j
#SBATCH --chdir=/shared/home/azureuser/jobs

nodefile=/shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID

echo "What nodes are part of this job ?"
echo $SLURM_JOB_NODELIST

echo "Is beeond installed :"
rpm -qa | grep -i beeond
echo
echo "Is Beeond & NFSoBlob mounted :"
df -h
echo

echo "Now we copy data from blob :"
date=$(date +%Y%m%d_%H%M%S)
mkdir /hpcpersistent/$date

beeond-cp stagein -n $nodefile -g /hpcpersistent/$date -l /beeond

echo "Now download kernel :"
wget -O /beeond/kernel.tgz https://git.kernel.org/torvalds/t/linux-6.3-rc4.tar.gz
cd /beeond/
ls -l
echo "DATE BEFORE IS :"
date
echo
## Too long for quick demo
#tar -xvzf kernel.tgz
echo "DATE AFTER IS :"
date
echo
cd ~

beeond-cp stageout -l /beeond
echo beeond-cp stageout -l /beeond
ls -l /hpcpersistent/$date

echo "DATE AFTER COPY IS :"
date

echo "Copy done, now let us quit"