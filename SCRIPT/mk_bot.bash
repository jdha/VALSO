#!/bin/bash
#SBATCH --mem=1G
#SBATCH --time=10
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint HSW24

write_err() {
echo "error when running cdfmean ($1)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt
}

if [[ $# -ne 4 ]]; then echo 'mk_bot.bash [CONFIG (eORCA12, eORCA025 ...)] [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

CONFIG=$1
RUNID=$2
TAG=$3
FREQ=$4
TBOTvar='|sosbt|sbt|'
SBOTvar='|sosbs|sbs|'

# load path and mask
. param.bash

# load config param
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd $DATPATH/

# check presence of input file
GRID=$GRIDT
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_bottom-${GRID}.nc

set -x
# Amundsen avg (CDW)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -109.640 -102.230  -75.800  -71.660 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILE -v $TBOTvar -p T -w ${ijbox} 0 0 -o AMU_thetao_$FILEOUT 
if [ $? -ne 0 ] ; then write_err AMU ; fi

# WRoss avg (bottom water)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w 157.100  173.333  -78.130  -74.040 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILE -v $SBOTvar -p T -w ${ijbox} 0 0 -o WROSS_so_$FILEOUT 
if [ $? -ne 0 ] ; then write_err WROS ; fi

# ERoss avg (CDW)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -176.790 -157.820  -78.870  -77.520 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILE -v $TBOTvar -p T -w ${ijbox} 0 0 -o EROSS_thetao_$FILEOUT 
if [ $? -ne 0 ] ; then write_err EROSS ; fi

# Weddell Avg (bottom water)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -65.130  -53.020  -75.950  -72.340 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILE -v $SBOTvar  -p T -w ${ijbox} 0 0 -o WED_so_$FILEOUT 
if [ $? -ne 0 ] ; then write_err WWED ; fi

for AREA in FRIS ROSS AMUS GETZ ; do
   echo "$AREA ..."
   $CDFPATH/cdfmean -f $FILE -v $TBOTvar  -p T  -o ${AREA}_thetao_$FILEOUT -B msk_${AREA}_shelf.nc tmask
   if [ $? -ne 0 ] ; then write_err $AREA ; fi

   $CDFPATH/cdfmean -f $FILE -v $SBOTvar  -p T  -o ${AREA}_so_$FILEOUT     -B msk_${AREA}_shelf.nc tmask
   if [ $? -ne 0 ] ; then write_err $AREA ; fi
done
