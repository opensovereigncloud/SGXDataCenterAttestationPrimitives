#!/bin/bash

set -euo pipefail

source ./tests/utils.sh

info "----------------------------------------------------------"
info "| SETUP ENVIRONMENT: Ensuring dependencies are installed |"
info "----------------------------------------------------------"

# ensure_installed checks if a program ($cmd_friendly_name)
# is installed using $check_cmd. If not installed,
# it installs the program with help of $install_cmd.
function ensure_installed {
    local cmd_friendly_name=$1
    local check_cmd=$2
    local install_cmd=$3
    echo "Ensuring $cmd_friendly_name is installed..."
    if ! $check_cmd >> /dev/null; then
        echo "$cmd_friendly_name not installed... Installing..."
        apt update
        $install_cmd
    fi
    echo -e "${GREEN}$cmd_friendly_name Installed.${NC}"
}

ensure_installed "Docker" "docker --version" "bash install/docker.sh"
ensure_installed "csvtool" "csvtool -help" "apt install -y csvtool"
ensure_installed "curl" "curl --version" "apt install -y curl"
ensure_installed "xxd" "xxd -v" "apt install -y xxd"
ensure_installed "jq" "jq --version" "apt install -y jq"

info "------------------------------------------------------"
info "| Installing Intel SGX runtime libraries (sgx_urts.so) |"
info "------------------------------------------------------"

if ldconfig -p 2>/dev/null | grep -q "sgx_urts"; then
    echo "SGX runtime already installed."
elif find /usr/lib /usr/lib64 /opt/intel /lib /lib64 -name "libsgx_urts.so*" 2>/dev/null | grep -q "sgx_urts.so"; then
    echo "SGX runtime already installed (detected via filesystem)."
else
    echo "SGX runtime not found. Installing..."
    apt update -y
    apt install -y lsb-release wget gnupg

    UBUNTU_CODENAME=$(lsb_release -cs)
    echo "Detected Ubuntu codename: $UBUNTU_CODENAME"

    # Try to install from Ubuntu repositories first
    if ! apt install -y libsgx-enclave-common libsgx-urts libsgx-epid libsgx-quote-ex; then
        echo "Falling back to Intel repository for $UBUNTU_CODENAME..."
        wget -qO - https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key | apt-key add -
        echo "deb [arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu $UBUNTU_CODENAME main" \
            > /etc/apt/sources.list.d/intel-sgx.list
        apt update -y
        apt install -y libsgx-enclave-common libsgx-urts libsgx-epid libsgx-quote-ex
    fi

    echo "SGX runtime installation completed successfully."
fi

info "---------------------------------------"
info "| SETUP ENVIRONMENT: Deploying PCCS   |"
info "---------------------------------------"

warn "Creating TLS key pair..."
openssl genrsa -out "$TMP_WORKDIR/private.pem" 2048

openssl req -new -key "$TMP_WORKDIR/private.pem" \
  -subj "/C=US/ST=California/L=San Francisco/O=Confidential Computing/OU=PCCS/CN=localhost" \
  -out "$TMP_WORKDIR/csr.pem"

openssl x509 -req -days 365 \
  -in "$TMP_WORKDIR/csr.pem" \
  -signkey "$TMP_WORKDIR/private.pem" \
  -out "$TMP_WORKDIR/file.crt"

cp ../config/default.json $TMP_WORKDIR/default.json

USER_TOKEN_HASH=$(echo -n "$PCCS_USER_TOKEN" | sha512sum | awk '{print $1}')
ADMIN_TOKEN_HASH=$(echo -n "$PCCS_ADMIN_TOKEN" | sha512sum | awk '{print $1}')

warn "Updating config with user/admin tokens and DCAP key..."
jq \
  --arg user_hash "$USER_TOKEN_HASH" \
  --arg admin_hash "$ADMIN_TOKEN_HASH" \
  --arg api_key "$DCAP_KEY" \
  '.UserTokenHash = $user_hash
  | .AdminTokenHash = $admin_hash
  | .ApiKey = $api_key' \
  $TMP_WORKDIR/default.json > $TMP_WORKDIR/default.json.tmp && mv $TMP_WORKDIR/default.json.tmp $TMP_WORKDIR/default.json

export ABS_TMP_WORKDIR=$(realpath "$TMP_WORKDIR")

chmod 644 $ABS_TMP_WORKDIR -R

docker run \
  --user "pccs:pccs" \
  -v "$ABS_TMP_WORKDIR/private.pem:/opt/intel/pccs/ssl_key/private.pem" \
  -v "$ABS_TMP_WORKDIR/file.crt:/opt/intel/pccs/ssl_key/file.crt" \
  -v "$ABS_TMP_WORKDIR/default.json:/opt/intel/pccs/config/default.json" \
  -p 8081:8081 --name pccs --network=host \
  -d "ghcr.io/opensovereigncloud/sgxdatacenterattestationprimitives/pccs:$IMAGE_TAG"