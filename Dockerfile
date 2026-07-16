FROM confluentinc/cp-kafka-connect-base:7.7.0

# Install the verified Confluent MQTT connector
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-mqtt:1.7.9