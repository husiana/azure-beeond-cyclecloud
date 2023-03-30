 d#!/bin/bash
## Code inspired by azhpc : https://github.com/Azure/azurehpc/blob/master/apps/ior/build_ior.sh

APP_NAME=ior
SHARED_APP="/shared/apps"
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}
PARALLEL_BUILD=8
IOR_VERSION=3.2.1
INSTALL_DIR=${SHARED_APP}/${APP_NAME}-${IOR_VERSION}

# Add the install directory if it doesn't exist
[ -d $INSTALL_DIR ] || mkdir -p $INSTALL_DIR
[ -d $MODULE_DIR ] || mkdir -p $MODULE_DIR

source /etc/profile.d/modules.sh # so we can load modules
module load gcc-9.2.1

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
echo "Running on $AZHPC_VMSIZE"
if [ "$AZHPC_VMSIZE" = "" ]; then
    echo "unable to retrieve VM Size - Exiting"
    exit 1
fi

case "$AZHPC_VMSIZE" in
    standard_hb120rs_v2 | standard_hb120rs_v3)
        module load mpi/hpcx
        ;;
    *)
        sudo yum install -y mpich-3.2-devel
        module load mpi/mpich-3.2-x86_64
        ;;
esac

module list
function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF > ${MODULE_DIR}/${MODULE_NAME}
#%Module
prepend-path    PATH            ${INSTALL_DIR}/bin;
prepend-path    LD_LIBRARY_PATH ${INSTALL_DIR}/lib;
prepend-path    MAN_PATH        ${INSTALL_DIR}/share/man;
setenv          IOR_BIN         ${INSTALL_DIR}/bin
EOF
}

cd $SHARED_APP

IOR_PACKAGE=ior-$IOR_VERSION.tar.gz
wget https://github.com/hpc/ior/releases/download/$IOR_VERSION/$IOR_PACKAGE
tar xvf $IOR_PACKAGE
rm $IOR_PACKAGE

cd ior-$IOR_VERSION

CC=`which mpicc`
echo ./configure --prefix=${INSTALL_DIR} >> /sched/outputiorconf.log
./configure --prefix=${INSTALL_DIR}

make -j ${PARALLEL_BUILD}
make install

create_modulefile