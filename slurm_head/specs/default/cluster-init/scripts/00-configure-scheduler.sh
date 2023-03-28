#!/bin/bash
### Code from MS TechCommunity https://techcommunity.microsoft.com/t5/azure-compute-blog/automate-beeond-filesystem-on-azure-cyclecloud-slurm-cluster/ba-p/3625544

# Copy Prolog & Epilog from / to the right location:
cp /mnt/cluster-init/slurm_head/default/files/*.sh /sched/

# Make the scripts executable
chmod +x /sched/slurm_*.sh

# Add the logs directory if it doesn't exist
[ -d /sched/log ] || mkdir /sched/log

# add Prolog/Epilog configs to slurm.conf
cat <<EOF >>/sched/slurm.conf
Prolog=/sched/slurm_prolog.sh
Epilog=/sched/slurm_epilog.sh
EOF

# force cluster nodes to re-read the slurm.conf
scontrol reconfig
