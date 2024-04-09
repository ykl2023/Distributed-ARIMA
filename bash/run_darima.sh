#! /bin/bash

# https://help.aliyun.com/document_detail/28124.html

# Tiny EXECUTORS: one executor per core
EC=1
EM=2g
#EXECUTORS=30

# MODEL_FILE
MODEL_DESCRIPTION=$1
MODEL_FILE=run_darima
OUTPATH=gs://bucket-st446-project-ykl/
SERIES_NAME=TOTAL

# Get current dir path for this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#echo Run the DARIMA model from $DIR

cd $DIR/..
rm -rf darima.zip
zip -r darima.zip darima/ setup.py -x "**/__pycache__/*" ".git/*"

tic0=`date +"%Y-%m-%d-%T"`
for EXECUTORS in 1 2 4 8 16 32 64
do 
    echo ${EXECUTORS}
    tic=`date +%s`
    PYSPARK_PYTHON=/usr/local/bin/python3.7 spark-submit  \
                  --master yarn  \
                  --driver-memory 10g  \
                  --executor-memory ${EM}  \
                  --executor-cores ${EC}  \
                  --num-executors ${EXECUTORS} \
                  --conf spark.rpc.message.maxSize=2000 \
                  $DIR/${MODEL_FILE}.py \
    	      > ${OUTPATH}${MODEL_DESCRIPTION}_${MODEL_FILE}.$SERIES_NAME.NE${EXECUTORS}.EC${EC}_${tic0}.out 2> ${OUTPATH}${MODEL_DESCRIPTION}_${MODEL_FILE}.$SERIES_NAME.NE${EXECUTORS}.EC${EC}_${tic0}.log
    
    toc=`date +%s`
    runtime=$((toc-tic))
    echo ${MODEL_FILE}.NE${EXECUTORS}.EC${EC} finished, "Time used (s):" $runtime
done

exit 0;
