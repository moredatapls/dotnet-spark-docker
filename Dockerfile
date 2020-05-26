FROM maven:3.6.3-openjdk-8 AS build-java

RUN mkdir -p /build/
RUN git clone https://github.com/dotnet/spark.git /build/dotnet-spark

# Add the patch files
COPY patches/*.patch /build/dotnet-spark/patches/

WORKDIR /build/dotnet-spark
RUN git config --global user.email "you@example.com" \
    && git config --global user.name "Your Name" \
    && git am patches/ip-address.patch \
    && git am patches/clean-up-stdin.patch

# TODO should cache the mvn dependencies
WORKDIR /build/dotnet-spark/src/scala
RUN mvn install


# TODO build Microsoft.Spark.Worker as well


FROM bde2020/spark-submit:2.4.5-hadoop2.7 AS run

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
# Use this when you have additional jars, e.g. jdbc drivers 
COPY jars/* /app/jars/

# Copy the patched jar
COPY --from=build-java /build/dotnet-spark/src/scala/microsoft-spark-2.4.x/target/microsoft-spark-2.4.x-0.11.0.jar /app/Microsoft.Spark-patched/jars/microsoft-spark-2.4.x-0.11.0.jar

# Backend config
ENV DOTNET_WORKER_DIR /app/Microsoft.Spark.Worker-0.11.0/
ENV DOTNETBACKEND_DEBUG_PORT 12345
ENV SPARK_MASTER_URL local

# Spark config
ENV ENABLE_INIT_DAEMON false
ENV SPARK_APPLICATION_MAIN_CLASS org.apache.spark.deploy.dotnet.DotnetRunner

# use the unpatched one
#ENV DOTNETBACKEND_JAR /app/Microsoft.Spark/jars/microsoft-spark-2.4.x-0.11.0.jar
# use the patched one
ENV DOTNETBACKEND_JAR /app/Microsoft.Spark-patched/jars/microsoft-spark-2.4.x-0.11.0.jar

CMD /app/run-debug.sh
