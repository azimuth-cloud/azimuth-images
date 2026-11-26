# LVM images

By default, the Kubernetes images use the partition layout of the Ubuntu cloud image: one
root partition that cloud-init grows on first boot. Some customizations need separate filesystems for
`/var`, `/var/log`, `/tmp` and so on, for example to meet the CIS benchmark, or so that a
full `/var/lib/containerd` cannot fill `/`.

The `lvm` var file builds a Kubernetes image with an LVM layout instead. The layout is set
in a Packer var file, so each customization can change it without changing any code.

> **Warning:** This feature has not been built on a real cloud yet.

## How it works

The disk that the build server runs from cannot be repartitioned, so the image is written
to a second disk:

1. `bin/build-image` creates an empty Cinder volume of `LVM_DISK_SIZE_GB`.
2. Packer attaches the volume to the build server (a `shell-local` provisioner in
   `packer/kubernetes.pkr.hcl`).
3. `ansible/kubernetes.yml` runs as usual, including image-builder's sysprep.
4. The last play runs the `linux-lvm` role. It:
   - partitions the volume: BIOS boot, ESP, `/boot`, and an LVM physical volume
   - creates the volume group and the logical volumes in `lvm_volumes`
   - copies the finished system onto them and writes a new `/etc/fstab`
   - installs GRUB for both BIOS and UEFI, and rebuilds the initramfs
   - checks that the disk will boot, then deactivates the volume group
5. Packer detaches the volume and saves its usual image of the build server's disk.
6. `bin/build-image` deletes that image and creates one from the LVM volume instead, with the
   same name. The rest of the script (download, convert to qcow2) is unchanged.

Builds without `lvm` in their var files are not affected: `lvm_volume_id` is empty, so the
provisioners do nothing and the role is skipped.

The image boots with BIOS (the OpenStack default) or with UEFI
(`hw_firmware_type=uefi`), like the Ubuntu cloud image.

## Building an LVM image

Add `lvm` as the **last** var file:

```yaml title=".github/builds.yaml"
- name: kubernetes-1-37-noble-lvm
  template: kubernetes
  var-files: common,kvm,linux,ubuntu-noble,kubernetes,kubernetes_1_37,lvm
```

The CI workflow needs a grype config for each build name, so there is also a
`grype-config/kubernetes-1-37-noble-lvm.yaml`.

To build one by hand:

```sh
ENVIRONMENT=arcus \
PACKER_TEMPLATE=kubernetes \
ENV_VAR_FILES=common,kvm,linux,ubuntu-noble,kubernetes,kubernetes_1_37,lvm \
./bin/build-image
```

## Configuration

The defaults are in `env/base/lvm.env` and `vars/base/lvm.json`.

```sh title="env/base/lvm.env"
LVM_DISK_SIZE_GB=20

PACKER_VAR_FILES="$PACKER_VAR_FILES,vars/base/lvm.json"
```

`LVM_DISK_SIZE_GB`
: The size of the image disk, in GiB. This setting turns the LVM build on.

`LVM_VOLUME_TYPE`
: The Cinder volume type for the build volume. If it is not set, the cloud's default is
used. It is set in `env/arcus/lvm.env` for CI.

```json title="vars/base/lvm.json"
{
  "extra_debs": "nfs-common lvm2 parted rsync dosfstools grub-pc-bin",
  "lvm_vg_name": "vg0",
  "lvm_esp_size_mib": 512,
  "lvm_boot_size_mib": 1024,
  "lvm_volumes": [
    {
      "name": "root",
      "size": "5G",
      "mount": "/",
      "fstype": "ext4",
      "options": "defaults"
    },
    {
      "name": "var",
      "size": "5G",
      "mount": "/var",
      "fstype": "ext4",
      "options": "defaults,nodev,nosuid"
    },
    {
      "name": "containerd",
      "size": "8G",
      "mount": "/var/lib/containerd",
      "fstype": "ext4",
      "options": "defaults,nodev"
    }
  ]
}
```

`lvm_volumes`
: The logical volumes. Each one has a `name`, a `size` in `lvcreate -L` syntax, a `mount`
point, an `fstype` and the fstab `options`. Exactly one must be mounted at `/`. `/boot` and
`/boot/efi` are always plain partitions, so they cannot be in this list.

`lvm_vg_name`, `lvm_esp_size_mib`, `lvm_boot_size_mib`
: The volume group name, and the sizes of the ESP and `/boot` partitions.

`extra_debs`
: The packages the role needs. They must be installed before sysprep runs, so they are
installed through image-builder. This value replaces the one in
`vars/base/kubernetes.json`, which is why it repeats `nfs-common`, and why `lvm` must be
the last var file.

The default layout follows the two filesystems that the kubelet knows about:

| Volume       | Mount                 | Kubernetes role | Holds                                                    |
| ------------ | --------------------- | --------------- | -------------------------------------------------------- |
| `root`       | `/`                   |                 | The OS                                                   |
| `var`        | `/var`                | nodefs          | `/var/lib/kubelet` (emptyDir volumes), pod and node logs |
| `containerd` | `/var/lib/containerd` | imagefs         | Container images and writable layers                     |

### Customising the layout

`bin/env-vars` reads `env/base/lvm.env` and then `env/$ENVIRONMENT/lvm.env`. So a customization can
override the defaults with its own files, without editing the base ones:

```sh title="env/something/lvm.env"
LVM_DISK_SIZE_GB=64
LVM_VOLUME_TYPE=fast-ssd

PACKER_VAR_FILES="$PACKER_VAR_FILES,vars/something/lvm.json"
```

```json title="vars/something/lvm.json"
{
  "lvm_volumes": [
    {
      "name": "root",
      "size": "8G",
      "mount": "/",
      "fstype": "ext4",
      "options": "defaults"
    },
    {
      "name": "var",
      "size": "20G",
      "mount": "/var",
      "fstype": "ext4",
      "options": "defaults,nodev,nosuid"
    },
    {
      "name": "var_log_audit",
      "size": "2G",
      "mount": "/var/log/audit",
      "fstype": "ext4",
      "options": "defaults,nodev,nosuid,noexec"
    },
    {
      "name": "tmp",
      "size": "2G",
      "mount": "/tmp",
      "fstype": "ext4",
      "options": "defaults,nodev,nosuid,noexec"
    },
    {
      "name": "containerd",
      "size": "28G",
      "mount": "/var/lib/containerd",
      "fstype": "ext4",
      "options": "defaults,nodev"
    }
  ]
}
```

This uses 60 GiB of the 64 GiB disk. It keeps nodefs and imagefs as in the default, gives
images the most space, and adds the `/tmp` and `/var/log/audit` filesystems that the CIS
benchmark asks for. Neither of these holds pod data, so ephemeral storage is still measured
correctly. On control-plane nodes, a separate `/var/lib/etcd` volume also protects etcd from
the rest of `/var`, but the same image is used for workers, where it would be wasted.

To build two layouts in the same environment, give the second one its own var filename
(for example `lvm_large`, listed after `lvm`) and its own entry in `.github/builds.yaml`.

### Disk size

An LVM image cannot boot from a disk smaller than `LVM_DISK_SIZE_GB`. In `azimuth-config`,
make sure that cluster nodes get a root volume at least that big:

```yaml title="environments/something/inventory/group_vars/all/variables.yml"
azimuth_capi_operator_capi_helm_root_volume_size: 64
```

## Files

| File                                     | What it does                                                                                |
| ---------------------------------------- | ------------------------------------------------------------------------------------------- |
| `bin/build-image`                        | Creates the volume, swaps it in for Packer's image, and deletes it at the end               |
| `packer/kubernetes.pkr.hcl`              | The `lvm_*` variables, attaching and detaching the volume, and the `-lvm` image name suffix |
| `ansible/kubernetes.yml`                 | Runs the `linux-lvm` role as the last play                                                  |
| `ansible/roles/linux-lvm/`               | Partitions the volume, copies the system and installs GRUB                                  |
| `env/base/lvm.env`, `vars/base/lvm.json` | The default size and layout                                                                 |
| `env/arcus/lvm.env`                      | The volume type for CI                                                                      |
