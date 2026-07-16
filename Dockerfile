# Start from your exact Kafka Connect base image
FROM confluentinc/cp-kafka-connect-base:7.7.0

# Install the official MQTT source connector from Confluent Hub
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-mqtt:11.3.0