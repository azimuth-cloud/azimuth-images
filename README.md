# azimuth-images

This repository contains [Packer](https://www.packer.io/) template definitions
for building images for use with [Azimuth](https://github.com/stackhpc/azimuth).

The templates work by provisioning machines in an [OpenStack](https://www.openstack.org/)
project and configuring them using [Ansible](https://www.ansible.com/) before
converting to an image. These images are then downloaded from OpenStack and uploaded
to S3 for distribution in an Azimuth release.

## Building an image manually

Before building an image, you must configure OpenStack authentication, using either
an RC file or `clouds.yaml`, e.g.:

```sh
export OS_CLOUD=openstack
```

This repository has a concept of "environments", allowing builds to be customised for
different clouds if required, for example in a fork. These manifest as directories
under `env`, where environment are set that in turn can specify Packer var files
under `var`.

Currently, the repository contains a `base` environment with cloud-agnostic configuration
and an `arcus` environment that contains configuration for the continuous integration
environment, which is kindly hosted on the Arcus cloud at the University of Cambridge.

To build images manually, outside of CI, first ensure you have Packer installed and
the required providers installed:

```sh
packer init ./config.pkr.hcl
```

Next, create a [Python virtual environment](https://docs.python.org/3/library/venv.html)
to use and install the Python and Ansible dependencies:

```sh
python -m venv .venv
source .venv/bin/activate

pip install -r ./requirements.txt

ansible-galaxy install -f -r requirements.yml
```

Finally, set up an environment using the `arcus` environment for inspiration.

You can then build images using the `./bin/build-image` script. This script expects the
following environment variables to be set:

  * `ENVIRONMENT` - the environment to use
  * `PACKER_TEMPLATE` - the Packer template in `packer` to use
  * `ENV_VAR_FILES` - the environment variable files to include

The values for `PACKER_TEMPLATE` and `ENV_VAR_FILES` can be determined by looking at
[the defined builds](./.github/builds.yaml).

For example, to build a workstation image, the following command can be used:

```sh
ENVIRONMENT=myenv \
PACKER_TEMPLATE=linux-desktop \
ENV_VAR_FILES=common,kvm,linux,ubuntu-jammy \
./bin/build-image
```

This will result in a private image being built in the target OpenStack project.
