#!/usr/bin/env bash

# Copyright 2018, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -evu

source lib/functions.sh

export RPC_BRANCH=${RPC_BRANCH:-'rocky'}
export OSA_SHA="stable/rocky"
export SKIP_INSTALL=${SKIP_INSTALL:-'no'}
export RPC_PRODUCT_RELEASE="rocky"
export RPC_ANSIBLE_VERSION="2.5.5"

echo "Starting Queens to Rocky Upgrade..."

checkout_rpc_openstack
configure_rpc_openstack
set_secrets_file
disable_hardening
bootstrap_ansible
prepare_rocky
run_upgrade

echo "Queens to Rocky Upgrade completed..."