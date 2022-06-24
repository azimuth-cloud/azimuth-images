#!/usr/bin/env bash

set -exo pipefail

# This script executes the playbooks from /etc/ansible-init/playbooks in lexicographical order

for file in $(find /etc/ansible-init/playbooks -maxdepth 1 -type f -name '*.yml' | sort -n); do
    ansible-playbook --connection local --inventory 127.0.0.1, "$file"
done
