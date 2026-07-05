#!/bin/bash

# Get connectors list
connectors=$(curl -s http://localhost:8083/connectors | jq -r '.[]')

# return error code if any connector is not in a running state
for connector in $connectors; do
    tasksState=$(curl -s http://localhost:8083/connectors/$connector/status | jq -r '.tasks[].state')

    for state in $tasksState; do
        if [ "$state" != "RUNNING" ]; then
            echo "Connector $connector is in state $state, exiting 1."
            exit 1
        fi
    done
done

exit 0