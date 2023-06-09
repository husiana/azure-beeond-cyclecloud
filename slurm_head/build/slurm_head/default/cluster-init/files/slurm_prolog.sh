#!/bin/bash
### Code derived from MS TechCommunity https://techcommunity.microsoft.com/t5/azure-compute-blog/automate-beeond-filesystem-on-azure-cyclecloud-slurm-cluster/ba-p/3625544

logdir="/sched/log"
logfile=$logdir/slurm_prolog-${SLURM_JOB_ID}.log
user=$(/usr/bin/id)

exec 2>&1> $logfile

echo "logdir     = "$logdir
echo "logfile    = "$logfile
echo "user       = "$user
echo "JobID      = "$SLURM_JOB_ID
echo "nodelist   = "$SLURM_JOB_NODELIST
echo "JobUser    = "$SLURM_JOB_USER

# add a test to check if beeond is already mounted, unmount / stop it ?

if [ $(/opt/cycle/jetpack/bin/jetpack config slurm.hpc) == "True" ]; then
  echo ""
  echo "-------------------------------------------------------------------------------------------"
  echo "$(date)...creating Slurm Job $SLURM_JOB_ID nodefile and starting Beeond"

  # create the nodelist by asking slurm what nodes are allocated to this job
  /usr/bin/scontrol show hostnames $SLURM_JOB_NODELIST > /shared/home/$SLURM_JOB_USER/tmp-nodefile-$SLURM_JOB_ID
  echo "Was node file built yet ?"
  echo $(/usr/bin/ls -l  /shared/home/$SLURM_JOB_USER/tmp-nodefile-$SLURM_JOB_ID)

  # if "Node as Hostname" is NOT enabled we need to create a hostfile
  ## This isn't working, let's assume we need the IP's in every scenarios :

#  if [ ! /opt/cycle/jetpack/bin/jetpack config slurm.use_nodename_as_hostname ]; then
#    echo "Node as Hostname is NOT enabled...creating nodefile"
    echo "Building list of IP's to start beeond :"
    while IFS= read -r line
    do
      scontrol show node "$line" | grep -oE "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" >> /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID-tmp
    done < "/shared/home/$SLURM_JOB_USER/tmp-nodefile-$SLURM_JOB_ID"

    uniq /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID-tmp /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID
    rm /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID-tmp /shared/home/$SLURM_JOB_USER/tmp-nodefile-$SLURM_JOB_ID
    cat /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID
#  else
#    echo "Node as Hostname is enabled...moving nodefile"
#    mv /shared/home/$SLURM_JOB_USER/tmp-nodefile-$SLURM_JOB_ID /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID
#  fi

  chown $SLURM_JOB_USER:$SLURM_JOB_USER /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID
  chmod 644 /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID

  # Start Beeond as $SLURM_JOB_USER
  echo "Now starting beeond ... "
  echo /usr/bin/beeond start -P -b /usr/bin/pdsh -n /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID  -d /mnt/resource/beeond -c /beeond
  /usr/bin/beeond start -P -b /usr/bin/pdsh -n /shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID  -d /mnt/resource/beeond -c /beeond
else
  echo "Skipping Beeond start since this is not an HPC partition..."
fi

echo "Is Beeond mounted ?"
/usr/bin/df -h /beeond
echo "This is the end, Thank you."
