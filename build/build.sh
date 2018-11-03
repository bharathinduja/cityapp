#!/bin/bash
set -euo pipefail
docker build -t $TEST_APP_IMAGE .
