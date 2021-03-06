#!/bin/sh

# use this when you want to submit additional drivers
# the tr command gives us a list of comma-separated jars
export SPARK_JARS=$(ls /app/jars/*.jar | tr '\n' ',')

/spark/bin/spark-submit \
    --class ${SPARK_APPLICATION_MAIN_CLASS} \
    --master ${SPARK_MASTER_URL} \
    --jars ${SPARK_JARS} \
    ${DOTNETBACKEND_JAR} debug ${DOTNETBACKEND_DEBUG_PORT}
