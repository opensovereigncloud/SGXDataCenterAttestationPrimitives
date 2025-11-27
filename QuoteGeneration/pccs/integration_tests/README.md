# Running Tests

Copy the sample configuration and update values as needed:

```bash
cp config.env .env
# edit .env with your preferred values
sudo su
source .env
```

Run all tests with:

```bash
bash tests/run-all.sh
```

What this script does:

1. Creates a temporary working directory under tests/tmp for intermediate files
1. Installs required dependencies if missing
1. Deploys PCCS at docker
1. Installs PCKIDRetrievalTool
1. Tests platform registration and package management
1. Runs PCCS API tests

## Teardown

To fully clean up your environment after testing, simply run:

```bash
bash ./tests/teardown.sh
```

This script will:

1. Clean up any `/etc/hosts` entries related to `$PCCS_URL`.
1. Delete the **k3d cluster**.
