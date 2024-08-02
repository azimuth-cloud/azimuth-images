#!/usr/lib/ansible-init/bin/python

import json
import logging
import os
import pathlib
import subprocess

import requests


logging.basicConfig(level = logging.INFO, format = "[%(levelname)s] %(message)s")


logger = logging.getLogger(__name__)


def assemble_list(data, prefix):
    """
    Assembles a list of items based on keys in data with the format "<prefix>_<idx>_<key>".
    """
    list_items = {}
    for key, value in data.items():
        if not key.startswith(prefix):
            continue
        idx, item_key = key.removeprefix(prefix).split("_", maxsplit = 1)
        list_items.setdefault(idx, {})[item_key] = value
    return [list_items[k] for k in sorted(list_items.keys())]


def ansible_exec(cmd, *args, **kwargs):
    """
    Execute an Ansible command with the appropriate environment.
    """
    environ = os.environ.copy()
    environ["ANSIBLE_CONFIG"] = "/etc/ansible-init/ansible.cfg"
    cmd = f"/usr/lib/ansible-init/bin/ansible-{cmd}"
    subprocess.run([cmd, *args], env = environ, check = True, **kwargs)


logger.info("fetching instance metadata")
METADATA_URL = "http://169.254.169.254/openstack/latest/meta_data.json"
response = requests.get(METADATA_URL)
response.raise_for_status()
user_metadata = response.json().get("meta", {})


logger.info("extracting user collections, playbooks and exclusions from metadata")
user_collections = assemble_list(user_metadata, "ansible_init_coll_")
user_playbooks = assemble_list(user_metadata, "ansible_init_pb_")
user_exclusions = assemble_list(user_metadata, "ansible_init_xpb_")


logger.info("listing system playbooks and exclusions")
playbooks = sorted(pathlib.Path("/etc/ansible-init/playbooks").glob("*.yml"))
exclusions = (
    {}
    if len(user_exclusions) == 0
    else [
        pathlib.Path("/etc/ansible-init/playbooks/" + playbook)
        for v in user_exclusions.values()
        for playbook in [v.get("name")]
    ]
)


logger.info(f"  found {len(playbooks)} baked-in playbooks")
logger.info(f"  found {len(exclusions)} excluded playbooks")
logger.info(f"  found {len(user_collections)} user collections")
logger.info(f"  found {len(user_playbooks)} user playbooks")


logger.info("installing collections")
ansible_exec(
    "galaxy",
    "collection",
    "install",
    "--force",
    "--requirements-file",
    "/dev/stdin",
    input = json.dumps({ "collections": user_collections }).encode()
)


logger.info("executing remote playbooks for stage - pre")
for playbook in user_playbooks:
    if playbook.get("stage", "post") == "pre":
        logger.info(f"  executing playbook - {playbook['name']}")
        ansible_exec(
            "playbook",
            "--connection",
            "local",
            "--inventory",
            "127.0.0.1,",
            playbook["name"]
        )


logger.info("executing playbooks from /etc/ansible-init/playbooks")
for playbook in [x for x in playbooks if x not in exclusions]:
    logger.info(f"  executing playbook - {playbook}")
    ansible_exec(
        "playbook",
        "--connection",
        "local",
        "--inventory",
        "127.0.0.1,",
        str(playbook)
    )


logger.info("executing remote playbooks for stage - post")
for playbook in user_playbooks:
    if playbook.get("stage", "post") == "post":
        logger.info(f"  executing playbook - {playbook['name']}")
        ansible_exec(
            "playbook",
            "--connection",
            "local",
            "--inventory",
            "127.0.0.1,",
            playbook["name"]
        )
