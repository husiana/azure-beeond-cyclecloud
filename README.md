Azure BeeGFS Ondemand integration to Azure Cyclecloud 8.3 on AlmaLinux-HPC-8.6

This set of projects, known as cluster-init scripts, will help you automate configuration of an ephemeral BeeOnd filesystem on your compute nodes.
In short:
- it creates a RAID0 target out of the 2 x NVMe-SSD drives present on our of HBv3 node;
- it configures / compiles BeeGFS on the HBv3 nodes;
- it configures slurm with pro and epilog scripts;
- it mounts BeeOnd on HBv3 nodes across the selected nodes for your job to run on local parallel filesystem;
- it supports single node job case where we don't build beeond, but instead leverage local NVMe-SSD.

Note: This has been tested on CycleCloud 8.3, AlmaLinux-HPC-8.6 and HBv3 compute nodes (including constraints SKU's)

In addition, you may want to stage-in and stage-out data from and to an NFS ober Blob storage for best cost/performance efficiency. This can be done using the command beeond-cp as part of your job script (no example presented in this repository)

The scripts contain dependencies on the naming of each of cloud-init projects, respectively slurm_execute and slurm_head, be careful not to change the name or to adapt the scripts accordinly.

Performance benchmarks will follow.