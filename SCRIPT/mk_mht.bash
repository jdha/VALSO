#!/bin/bash
#SBATCH --mem=1G
#SBATCH --time=20
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint BDW28

if [[ $# -ne 4 ]]; then echo 'mk_mht.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4
# load path and mask
. param.bash

# load config param
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd $DATPATH/

# check presence of input file
GRID=$GRIDV ; FILEV=`get_nemofilename`
if [ ! -f $FILEV ] ; then echo "$FILEV is missing; exit"; echo "E R R O R in : ./mk_mht.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_mht_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make mht
FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_mht.nc
set -x
$CDFPATH/cdfmhst -vt $FILEV ${VVL} -o tmp_$FILEOUT

# mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfmht; exit"; echo "E R R O R in : ./mk_mht.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_mht_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi

# extract only 26.5
case $CONFIG in
  eORCA1)
    jj=227
    ;;
  eORCA025*)
    jj=793
    ;;
  eORCA12)
    jj=2364
    ;;
  *)
    echo "Unrecognised configuration."
    echo "error when running cdfmht; exit"; echo "E R R O R in : ./mk_mht.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_mht_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt; exit 1
    ;;
esac
ncks -O -d y,$jj,$jj $FILEOUT ${CONFIG}-${RUNID}_${FREQ}_${TAG}_mht_265.nc
