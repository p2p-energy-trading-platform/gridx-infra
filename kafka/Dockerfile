FROM confluentinc/cp-kafka:7.7.0

ADD --checksum=sha256:0ad843261c567d1924a017d542e14c40f2afff523d940c25ee000742fde4b3a9 \
    https://github.com/prometheus/jmx_exporter/releases/download/1.7.0/jmx_prometheus_javaagent-1.7.0.jar \
    /opt/jmx-exporter/jmx_prometheus_javaagent-1.7.0.jar

USER root
RUN chmod 644 /opt/jmx-exporter/jmx_prometheus_javaagent-1.7.0.jar
USER appuser

COPY kafka/jmx-exporter-config.yml /etc/kafka/jmx-exporter-config.yml
