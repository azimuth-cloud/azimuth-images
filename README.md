# azimuth-images

This repository contains [Packer](https://www.packer.io/) pipeline definitions
for building images for use with [Azimuth](https://github.com/stackhpc/azimuth).

Currently, pipelines are provided for building Ubuntu and Windows images that
provide web console functionality for Azimuth.

The pipelines work by provisioning machines in an [OpenStack](https://www.openstack.org/)
project and configuring them using [Ansible](https://www.ansible.com/) before
converting to an image. The result is a private image in the OpenStack project.
