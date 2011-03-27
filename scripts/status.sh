#!/bin/bash

. common.sh

execCommand "S"
beamStatus
alarmStatus
people
event

echo "People count: "$PEOPLE