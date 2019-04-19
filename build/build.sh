#!/bin/bash
set -euo pipefail
sudo docker build -t $TEST_APP_IMAGE .
