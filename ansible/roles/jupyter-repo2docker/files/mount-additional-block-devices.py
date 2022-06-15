#!/usr/bin/env python3

import argparse
import csv
import io
from pathlib import Path
import shlex
import subprocess
import sys
import time

'''
Use the device name of the block device that holds the partition
mounted at / to detect whether block devices attached to this
instance are virtualised (/dev/sda) or paravirtualised (/dev/vda).

Examine connected block devices for a additional block devices
format it, mount it, and add it to /etc/fstab so that it survives
a reboot.
'''


def get_block_devices():
    
    lsblk_out = subprocess.run(
        [
            "lsblk",
            "-pro",
            "NAME,MOUNTPOINTS"
            ], 
            capture_output=True, 
            text=True
        ).stdout

    block_device_list = []

    for row in csv.DictReader(io.StringIO(lsblk_out), delimiter=' '):
        block_device_list.append(row)

    return block_device_list

def get_root_block_device(block_device_list):
    
    root_part = [
        i for i in block_device_list 
        if i['MOUNTPOINTS'] == "/"
        ][0]

    root_block_device = subprocess.run(
        [
            "lsblk",
            "-pno",
            "pkname",
            root_part['NAME']
            ],
            capture_output=True, 
            text=True
        ).stdout.strip()
    
    return root_block_device

def get_additional_block_devices():

    block_device_list = get_block_devices()
    
    root_block_device = get_root_block_device(block_device_list)

    return sorted(
        [
            i['NAME'] for i in block_device_list 
            if len(i['MOUNTPOINTS']) == 0 and 
            root_block_device not in i['NAME']
            ]
        )

def format_and_mount_block_device(mountpoint, block_device, filesystem_builder, builder_args):

    mkfs_command = filesystem_builder+ " " +builder_args+ " " +block_device
    mkfs_command_shlex = shlex.split(mkfs_command)
    print(f"mkfs command: {mkfs_command_shlex}")

    # Make the filesystem
    subprocess.run(mkfs_command_shlex)
    
    # Get its UUID
    fs_uuid = subprocess.run(
        [
            "blkid",
            "-s", "UUID",
            "-o", "value",
            block_device
            ],
            capture_output=True, 
            text=True
        ).stdout.strip()

    # Mount the filesystem
    p = Path(mountpoint)
    if not p.is_dir:
        print(f"Mountpoint {mountpoint} does not exist")
        sys.exit(1)

    subprocess.run(
        [
            "mount",
            block_device,
            mountpoint
        ]
    )

    # Add the filesystem to fstab with its UUID
    with open('/etc/fstab', 'a') as fn:
        fn.write(f"UUID={fs_uuid} {mountpoint} auto defaults,nofail 0 0\n")

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-t", "--tries",
                    type=int,
                    default=10,
                    help="Number of tries to detect additional block devices. [Default: 10]")
    parser.add_argument("-f", "--filesystem-builder",
                    type=str,
                    default="mkfs.ext4",
                    help="Filesystem builder used to add a filesystem to block devices. [Default: mkfs.ext4]")
    parser.add_argument("-b", "--builder-args",
                    type=str,
                    default="",
                    help="Arguments to pass through to the Filesystem builder program.")
    parser.add_argument("mountpoints", type=str,  
                    help="Comma separated list of paths to mount block devices. Devices are \
                    mounted in alphabetical order, which usually reflects the order in which \
                    they are attached to the instance. MOUNTPOINTS MUST ALREADY EXIST.")
    return parser.parse_args()

def main(args):

    mountpoints = args.mountpoints.split(",")
    no_mountpoints = len(mountpoints)

    for retry in range(1, 1 + args.tries):
        
        additional_block_devices = get_additional_block_devices()
        no_found_block_devices = len(additional_block_devices)
    
        if len(additional_block_devices) != no_mountpoints:
            print(f"[Retry: {retry}] Additional block devices found: {no_found_block_devices} "
                  f"doesn't match the mountpoints requested: {no_mountpoints} "
                  f"sleeping for 10s before retrying...")
            time.sleep(10)

        else:
            print(f"[Retry: {retry}] Successfully found {no_found_block_devices} "
                  f"additional block devices")
            
            for mountpoint,device in dict(zip(mountpoints, additional_block_devices)).items():
                
                print(f"Mounting {device} at {mountpoint}")
                
                format_and_mount_block_device(
                    mountpoint, 
                    device, 
                    args.filesystem_builder, 
                    args.builder_args
                )
            
            break
        
if __name__ == '__main__':
    args = parse_args()
    main(args)