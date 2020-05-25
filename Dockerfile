FROM bde2020/spark-submit:2.4.5-hadoop2.7

RUN mkdir -p /app/

# Download the Worker
RUN wget https://github.com/dotnet/spark/releases/download/v0.11.0/Microsoft.Spark.Worker.netcoreapp3.1.linux-x64-0.11.0.tar.gz -O /tmp/Microsoft.Spark.Worker.tar.gz \
    && tar -C /app/ -zxvf /tmp/Microsoft.Spark.Worker.tar.gz \
    && rm /tmp/Microsoft.Spark.Worker.tar.gz

RUN wget https://www.nuget.org/api/v2/package/Microsoft.Spark/0.11.0 -O /tmp/microsoft.spark.0.11.0.nupkg \
    && mkdir /app/Microsoft.Spark \
    && unzip /tmp/microsoft.spark.0.11.0.nupkg -d /app/Microsoft.Spark \
    && rm /tmp/microsoft.spark.0.11.0.nupkg

# Copy stuff
COPY run-debug.sh /app/
# COPY Resources/Jars/*.jar /app/Jars/ - use this when you have additional jars, e.g. jdbc drivers 

# Backend config
ENV DOTNET_WORKER_DIR /app/Microsoft.Spark.Worker-0.11.0/
ENV DOTNETBACKEND_DEBUG_PORT 12345
ENV SPARK_MASTER_URL local

# Spark config
ENV ENABLE_INIT_DAEMON false
ENV DOTNETBACKEND_JAR /app/Microsoft.Spark/jars/microsoft-spark-2.4.x-0.11.0.jar
ENV SPARK_APPLICATION_MAIN_CLASS org.apache.spark.deploy.dotnet.DotnetRunner

CMD /app/run-debug.sh
