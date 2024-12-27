#!/bin/bash

# Check if NAMESPACE environment variable is set and not empty
if [ -z "${NAMESPACE}" ]; then
  echo "Error: NAMESPACE environment variable is not set or is empty."
  echo "Run: export NAMESPACE=adjective-noun to populate the NAMESPACE env variable"
  exit 1
fi

# Script depends on mqttx being in the system path. Tested with version mqttx 1.11.0

# Configuration
BROKER1="${NAMESPACE}.useast.lab-app.f5demos.com"    # Replace with your MQTT broker address
BROKER2="${NAMESPACE}.uswest.lab-app.f5demos.com"    # Replace with your MQTT broker address
BROKER3="${NAMESPACE}.europe.lab-app.f5demos.com"    # Replace with your MQTT broker address
PORT=8883                   # Replace with your MQTT broker port
TOPIC="system/stats"        # Replace with your desired MQTT topic
CLIENT_ID=$(hostname)       # Replace with your MQTT client ID
INTERVAL=1                  # Time interval between messages in seconds
NETWORK_INTERFACE="ens5"    # Replace with your network interface (e.g., eth0, wlan0)

# Function to get CPU usage
get_cpu_stats() {
  echo $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
}

# Function to get memory usage
get_memory_stats() {
  echo $(free | grep Mem | awk '{printf "%.2f", $3 / $2 * 100}')
}

# Function to get network throughput (incoming and outgoing)
get_network_throughput() {
  local interface="$1"
  local interval="$2"

  # Get initial RX and TX bytes
  RX_BYTES_1=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
  TX_BYTES_1=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)

  # Wait for the specified interval
  sleep "$interval"

  # Get RX and TX bytes again
  RX_BYTES_2=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
  TX_BYTES_2=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)

  # Calculate throughput in bits per second
  RX_BPS=$(( (RX_BYTES_2 - RX_BYTES_1) * 8 / interval ))
  TX_BPS=$(( (TX_BYTES_2 - TX_BYTES_1) * 8 / interval ))

  echo "$RX_BPS $TX_BPS"
}

# Function to get top 10 processes by CPU usage
get_top_processes() {
  top -bn1 | head -n 17 | tail -n 10 | awk '{print "\"" $12 "\": " $9}' | paste -sd, - | sed 's/,/,\\n/g' | sed 's/\\n/\n/g'
}

# Function to publish MQTT message
publish_mqtt() {
  local BROKER="$1"
  local PORT="$2"
  local TOPIC="$3"
  local PAYLOAD="$4"
  local CLIENT_ID="$5"

  echo "  Publishing $TOPIC to $BROKER"
  mqttx pub -h "$BROKER" --port "$PORT" --topic "$TOPIC" --message "$PAYLOAD" --client-id "$CLIENT_ID via $BROKER" --insecure --protocol mqtts
}

# Infinite loop to publish CPU and memory stats at intervals
while true; do
  # Get CPU and memory usage
  CPU=$(get_cpu_stats)
  MEMORY=$(get_memory_stats)

  # Get network throughput
  read RX_BPS TX_BPS < <(get_network_throughput "$NETWORK_INTERFACE" "$INTERVAL")

  # Get top 10 processes
  TOP_PROCESSES=$(get_top_processes)

  # Format the payload as Grafana-compatible JSON
  CPUMEM_PAYLOAD=$(cat <<EOF
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$CLIENT_ID",
  "broker": "$BROKER1",
  "cpu_usage": $CPU,
  "memory_usage": $MEMORY
}a
EOF
)

  NET_PAYLOAD=$(cat <<EOF
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$CLIENT_ID",
  "broker": "$BROKER2",
  "network_rx_bps": $RX_BPS,
  "network_tx_bps": $TX_BPS
}
EOF
)

  TOP10_PAYLOAD=$(cat <<EOF
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$CLIENT_ID",
  "broker": "$BROKER3",
  $TOP_PROCESSES
}
EOF
)

  # Publish the JSON payload using the MQTT function
  publish_mqtt "$BROKER1" "$PORT" "$TOPIC/cpumem" "$CPUMEM_PAYLOAD" "$CLIENT_ID"
  publish_mqtt "$BROKER2" "$PORT" "$TOPIC/network" "$NET_PAYLOAD" "$CLIENT_ID"
  publish_mqtt "$BROKER3" "$PORT" "$TOPIC/top10" "$TOP10_PAYLOAD" "$CLIENT_ID"


  # Wait for the specified interval
  sleep "$INTERVAL"
done
