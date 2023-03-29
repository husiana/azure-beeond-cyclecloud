#!/bin/bash
### Code derived from MS TechCommunity https://techcommunity.microsoft.com/t5/azure-compute-blog/automate-beeond-filesystem-on-azure-cyclecloud-slurm-cluster/ba-p/3625544

logdir="/sched/log"
logfile=$logdir/slurm_epilog-${SLURM_JOB_ID}.log
user=$(/usr/bin/id)

exec 2>&1> $logfile

echo "logdir     = "$logdir
echo "logfile    = "$logfile
echo "user       = "$user
echo "JobID      = "$SLURM_JOB_ID
echo "nodelist   = "$SLURM_JOB_NODELIST
echo "JobUser    = "$SLURM_JOB_USER

if [ "$(/opt/cycle/jetpack/bin/jetpack config slurm.hpc)" == "True" ]; then
  nodefile=/shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID
  nodecnt=$(wc -l $nodefile | cut -f 1 -d " ")

  echo $nodefile" "$nodecnt
  if [[ -e $nodefile && $nodecnt -gt 1 ]] ; then
    echo "$(date).... Stopping beeond"
    while read host; do
      echo /usr/bin/beeond stop -b /usr/bin/pdsh -n $nodefile -L -d -P -c
      /usr/bin/beeond stop -b /usr/bin/pdsh -n $nodefile -L -d -P -c
      break
    done < $nodefile

    # Workaround Beeond stop umount issue
    ! mount | grep beeond || sudo umount -l /beeond

    echo
    echo "Is beeond Still mounted ?"
    mount | grep -i bee
    echo

    rm $nodefile
    echo "ok done"
  else
    echo "Single node job, so unlinking /beeond directory"
    unlink /beeond
  fi
fi
