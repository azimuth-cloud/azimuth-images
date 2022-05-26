# azimuth-images

This repository contains [Packer](https://www.packer.io/) template definitions
for building images for use with [Azimuth](https://github.com/stackhpc/azimuth).

Currently, templates are provided for building Ubuntu and Windows images that
provide web console functionality for Azimuth.

The templates work by provisioning machines in an [OpenStack](https://www.openstack.org/)
project and configuring them using [Ansible](https://www.ansible.com/) before
converting to an image. The result is a private image in the OpenStack project.

## Building an image

Before building an image, you must configure OpenStack authentication, using
either an RC file or `clouds.yaml`, e.g.:

```sh
export OS_CLOUD=openstack
```

Ansible must be installed on the machine that executes Packer, and the
[required collections](./requirements.yml) must be installed:

```sh
ansible-galaxy install -f -r ./requirements.yml
```

The Packer templates are in the [packer](./packer) directory of this repository.
To build an image, just run the following `packer` command:

```sh
packer build --on-error=ask -var-file=./inputs.pkvars.hcl packer/{linux,windows}-webconsole.pkr.hcl
```

Check the Packer template for the available/required inputs.
