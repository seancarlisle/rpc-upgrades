#!/bin/bash

## Deploy virtualenv for testing environment molecule/ansible-playbook/infratest

## Shell Opts ----------------------------------------------------------------

set -ev
set -o pipefail

## Variables -----------------------------------------------------------------

# Release metadata required for qTest export
if [[ -f /opt/rpc-openstack/scripts/artifacts-building/derive-artifact-version.sh ]]; then
    export RPC_RELEASE="$(/opt/rpc-openstack/scripts/artifacts-building/derive-artifact-version.sh)"
elif [[ -f /opt/rpc-openstack/scripts/get-rpc_release.py ]]; then
    export RPC_RELEASE="$(/opt/rpc-openstack/scripts/get-rpc_release.py -f /opt/rpc-openstack/playbooks/vars/rpc-release.yml)"
else
    export RPC_RELEASE=''
fi
export RPC_PRODUCT_RELEASE="${RE_JOB_UPGRADE_TO:-newton}"

RE_HOOK_ARTIFACT_DIR="${RE_HOOK_ARTIFACT_DIR:-/tmp/artifacts}"
export RE_HOOK_RESULT_DIR="${RE_HOOK_RESULT_DIR:-/tmp/results}"
SYS_WORKING_DIR=$(mktemp  -d -t system_test_workingdir.XXXXXXXX)
export SYS_VENV_NAME="${SYS_VENV_NAME:-venv-molecule}"
SYS_TEST_SOURCE_BASE="${SYS_TEST_SOURCE_BASE:-https://github.com/rcbops}"
SYS_TEST_SOURCE="${SYS_TEST_SOURCE:-rpc-openstack-system-tests}"
SYS_TEST_SOURCE_REPO="${SYS_TEST_SOURCE_BASE}/${SYS_TEST_SOURCE}"
SYS_TEST_BRANCH="${RE_JOB_BRANCH:-master}"
export SYS_INVENTORY="/opt/rpc-openstack/openstack-ansible/playbooks/inventory"

## Main ----------------------------------------------------------------------

# 1. Clone test repository into working directory.
pushd "${SYS_WORKING_DIR}"
git clone "${SYS_TEST_SOURCE_REPO}"
pushd "${SYS_TEST_SOURCE}"

# Checkout defined branch
git checkout "${SYS_TEST_BRANCH}"
echo "${SYS_TEST_SOURCE} at SHA $(git rev-parse HEAD)"

# Gather submodules
git submodule init
git submodule update --recursive

# fail softly if the tests or artifact gathering fails
set +e

# 2. Execute script from repository
./execute_tests.sh
[[ $? -ne 0 ]] && RC=$?  # record non-zero exit code

# 3. Collect results from script
mkdir -p "${RE_HOOK_RESULT_DIR}" || true  # ensure that result directory exists
tar -xf test_results.tar -C "${RE_HOOK_RESULT_DIR}"
# record non-zero exit code if not already recorded
[[ $? -ne 0 ]] && [[ ! -z ${RC+x} ]] && RC=$?

# 4. Collect logs from script
mkdir -p "${RE_HOOK_ARTIFACT_DIR}" || true  # ensure that artifact directory exists
# Molecule does not produce logs outside of STDOUT
# record non-zero exit code if not already recorded
[[ $? -ne 0 ]] && [[ ! -z ${RC+x} ]] && RC=$?
popd

# if exit code is recorded, use it, otherwise let it exit naturally
[[ -z ${RC+x} ]] && exit ${RC}
