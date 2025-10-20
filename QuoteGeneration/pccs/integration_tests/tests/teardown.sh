#!/bin/bash

set -euo pipefail

source ./tests/utils.sh

info "--------------------------------------------------------------"
info "| SETUP ENVIRONMENT: Checking required environment variables |"
info "--------------------------------------------------------------"

check_required_envs

info "----------------------------------------------"
info "| TEARDOWN ENVIRONMENT: Stoping container    |"
info "----------------------------------------------"

docker stop pccs
docker rm pccs

echo -e "${GREEN}Teardown complete!${NC}"
