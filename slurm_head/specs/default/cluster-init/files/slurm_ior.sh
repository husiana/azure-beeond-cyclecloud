#!/bin/bash
FILESYSTEM="/beeond"
SHARED_APP="/shared/apps"
SUMMARY_FORMAT=${SUMMARY_FORMAT:-JSON}
HOST=`hostname`
NUMPROCS=`cat $PBS_NODEFILE | wc -l`

source /etc/profile.d/modules.sh # so we can load modules

module use ${SHARED_APP}/modulefiles
module load ior

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
if [ "$AZHPC_VMSIZE" = "" ]; then
    echo "Unable to retrieve VM Size - Exiting"
    exit 1
fi

case "$AZHPC_VMSIZE" in
    standard_hb120rs_v2 | standard_hb120rs_v3)
        module load mpi/hpcx
        ;;
    *)
        module load mpi/mpich-3.2-x86_64
        ;;
esac

NODEFILE="/shared/home/$SLURM_JOB_USER/nodefile-$SLURM_JOB_ID"

function drop_all_caches {
for HOST in `cat $NODEFILE | uniq`
do
   ssh $HOST 'sudo bash -c "sync; echo 3 > /proc/sys/vm/drop_caches"'
done

}

if [[ -n $NODEFILE ]]; then
    CORES=$(cat $NODEFILE | wc -l)
    NODES=$(cat $NODEFILE | sort -u)
    MPI_OPTS="-np $NODES*120 --hostfile $NODEFILE"
fi

cd 

for TRANSFER_SIZE in 32m 4k
do
 if [ $TRANSFER_SIZE == "4k" ]; then
    SIZE=128M
 else
    SIZE=2G
 fi
 for IO_API in POSIX MPIIO
 do
  if [ $IO_API == "POSIX" ]; then
     IO_API_ARG="-F"
  else
     IO_API_ARG=""
  fi
  for TYPE_IO in direct_io buffered_io
  do
   if [ $TYPE_IO == "direct_io" ]; then
      TYPE_IO_ARG="-B"
   else
      TYPE_IO_ARG="-k"
   fi
drop_all_caches
mpirun  -bind-to hwthread $MPI_OPTS $IOR_BIN/ior -a $IO_API -v -i 1 $TYPE_IO_ARG -m -d 1 $IO_API_ARG -w -r -t $TRANSFER_SIZE -b $SIZE -o ${FILESYSTEM}/test -O summaryFormat=$SUMMARY_FORMAT -O summaryFile=ior_${IO_API}_${TYPE_IO}_${TRANSFER_SIZE}_${SIZE}_${HOST}_${NUMPROCS}.out_$$
rm ${FILESYSTEM}/test.*
sleep 2
done
done
done