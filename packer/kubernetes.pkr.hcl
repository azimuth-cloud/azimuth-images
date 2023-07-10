#####
# General variables
#####

variable "source_image_name" {
  type = string
}

variable "network" {
  type = string
}

variable "floating_ip_network" {
  type = string
}

variable "flavor" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "volume_size" {
  type = number
  default = 10
}

variable "disk_format" { # Same thing as build_target?
  type = string
  default = "qcow2"
}

variable "distro_name" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

#####
# Kubernetes-specific variables
#####

variable "additional_executables" {
  type = string
  default = ""
}

variable "additional_executables_list" {
  type = string
  default = ""
}

variable "additional_executables_destination_path" {
  type = string
  default = ""
}

variable "additional_registry_images" {
  type = string
  default = ""
}

variable "additional_registry_images_list" {
  type = string
  default = ""
}

variable "additional_url_images" {
  type = string
  default = ""
}

variable "additional_url_images_list" {
  type = string
  default = ""
}

variable "build_target" {
  type = string
  default = ""
}

variable "containerd_additional_settings" {
  type = string
  default = ""
}

variable "containerd_arch" {
  type = string
  default = "amd64"
}

variable "containerd_cri_socket" {
  type = string
}

variable "containerd_sha256" {
  type = string
}

variable "containerd_url" {
  type = string
  default = ""
}

variable "containerd_version" {
  type = string
}

variable "containerd_wasm_shims_arch" {
  type = string
  default = ""
}

variable "containerd_wasm_shims_runtimes" {
  type = string
  default = ""
}

variable "containerd_wasm_shims_sha256" {
  type = string
  default = ""
}

variable "containerd_wasm_shims_url" {
  type = string
  default = ""
}

variable "containerd_wasm_shims_version" {
  type = string
  default = ""
}

variable "crictl_arch" {
  type = string
  default = "amd64"
}

variable "crictl_sha256" {
  type = string
  default = ""
}

variable "crictl_source_type" {
  type = string
}

variable "crictl_url" {
  type = string
  default = ""
}

variable "crictl_version" {
  type = string
}

variable "disable_public_repos" {
  type = string
  default = ""
}

variable "extra_debs" {
   type = string
   default = ""
}

variable "extra_repos" {
  type = string
  default = ""
}

variable "extra_rpms" {
  type = string
  default = ""
}

variable "firstboot_custom_roles_post" {
  type = string
  default = ""
}

variable "firstboot_custom_roles_pre" {
  type = string
  default = ""
}

variable "http_proxy" {
  type = string
  default = ""
}

variable "https_proxy" {
  type = string
  default = ""
}

variable "load_additional_components" {
  type = string
  default = ""
}

variable "kubeadm_template" {
  type = string
  default = "etc/kubeadm.yml"
}

variable "kubernetes_cni_version" {
  type = string
}

variable "kubernetes_cni_http_checksum" {
  type = string
  default = ""
}

variable "kubernetes_cni_http_checksum_arch" {
  type = string
  default = ""
}

variable "kubernetes_cni_http_source" {
  type = string
  default = ""
}

variable "kubernetes_cni_rpm_version" {
  type = string
  default = ""
}

variable "kubernetes_cni_source_type" {
  type = string
  default = ""
}

variable "kubernetes_container_registry" {
  type = string
  default = ""
}

variable "kubernetes_deb_gpg_key" {
  type = string
  default = ""
}

variable "kubernetes_deb_repo" {
  type = string
  default = ""
}

variable "kubernetes_http_source" {
  type = string
  default = ""
}

variable "kubernetes_load_additional_imgs" {
  type = string
  default = ""
}

variable "kubernetes_rpm_gpg_check" {
  type = string
  default = ""
}

variable "kubernetes_rpm_gpg_key" {
  type = string
  default = ""
}

variable "kubernetes_rpm_repo" {
  type = string
  default = ""
}

variable "kubernetes_rpm_repo_arch" {
  type = string
  default = "x86_64"
}

variable "kubernetes_rpm_version" {
  type = string
  default = ""
}

variable "kubernetes_source_type" {
  type = string
}

variable "node_custom_roles_post" {
  type = string
  default = ""
}

variable "node_custom_roles_pre" {
  type = string
  default = ""
}

variable "no_proxy" {
  type = string
  default = ""
}

variable "pause_image" {
  type = string
  default = ""
}

variable "pip_conf_file" {
  type = string
  default = ""
}

variable "python_path" {
  type = string
  default = ""
}

variable "redhat_epel_rpm" {
  type = string
  default = ""
}

variable "reenable_public_repos" {
  type = string
  default = ""
}

variable "remove_extra_repos" {
  type = string
  default = ""
}

variable "systemd_prefix" {
  type = string
  default = "/etc/systemd"
}

variable "sysusr_prefix" {
  type = string
  default = "/usr"
}

variable "sysusrlocal_prefix" {
  type = string
  default = "/usr/local"
}

#####
# Locals
#####

locals {
    build_timestamp = formatdate("YYMMDD-hhmm", timestamp())

    kubernetes_semver = "v${var.kubernetes_version}"
    kubernetes_cni_semver = "v${var.kubernetes_cni_version}"

    # Debian based
    kubernetes_deb_version = "${var.kubernetes_version}-00"
    kubernetes_cni_deb_version = "${var.kubernetes_cni_version}-00"

    # Red Hat based

    containerd_url_default = "https://github.com/containerd/containerd/releases/download/v${var.containerd_version}/cri-containerd-cni-${var.containerd_version}-linux-${var.containerd_arch}.tar.gz"
    containerd_url = element([for e in [var.containerd_url, local.containerd_url_default]: e if e != ""], 0)

    containerd_wasm_shims_url_default = "https://github.com/deislabs/containerd-wasm-shims/releases/download/${var.containerd_wasm_shims_version}/containerd-wasm-shims-v1-linux-${var.containerd_wasm_shims_arch}.tar.gz"
    containerd_wasm_shims_url = element([for e in [var.containerd_wasm_shims_url, local.containerd_wasm_shims_url_default]: e if e != ""], 0)

    crictl_sha256_default = "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${var.crictl_version}/crictl-v${var.crictl_version}-linux-${var.crictl_arch}.tar.gz.sha256"
    crictl_sha256 = element([for e in [var.crictl_sha256, local.crictl_sha256_default]: e if e != ""], 0)

    crictl_url_default = "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${var.crictl_version}/crictl-v${var.crictl_version}-linux-${var.crictl_arch}.tar.gz"
    crictl_url = element([for e in [var.crictl_url, local.crictl_url_default]: e if e != ""], 0)

    kubernetes_cni_http_checksum_default = "sha256:https://storage.googleapis.com/k8s-artifacts-cni/release/${local.kubernetes_cni_semver}/cni-plugins-linux-${var.kubernetes_cni_http_checksum_arch}-${local.kubernetes_cni_semver}.tgz.sha256"
    kubernetes_cni_http_checksum = element([for e in [var.kubernetes_cni_http_checksum, local.kubernetes_cni_http_checksum_default]: e if e != ""], 0)

    kubernetes_rpm_repo_default = "https://packages.cloud.google.com/yum/repos/kubernetes-el7-${var.kubernetes_rpm_repo_arch}"
    kubernetes_rpm_repo = element([for e in [var.kubernetes_rpm_repo, local.kubernetes_rpm_repo_default]: e if e != ""], 0)
}

#####
# Build
#####

source "openstack" "kubernetes" {
  image_name = "${var.distro_name}-kube-${local.kubernetes_semver}-${local.build_timestamp}"
  image_visibility = "private"
  image_disk_format = "${var.disk_format}"

  source_image_name = "${var.source_image_name}"
  flavor = "${var.flavor}"
  networks = ["${var.network}"]
  security_groups = "${var.security_groups}"
  floating_ip_network = "${var.floating_ip_network}"

  use_blockstorage_volume = true
  volume_size = "${var.volume_size}"

  communicator = "ssh"
  ssh_username = "${var.ssh_username}"
}

build {
  sources = [
      "openstack.kubernetes"
  ]

  provisioner "ansible" {
    galaxy_file = "${path.root}/../requirements.yml"
    playbook_file = "${path.root}/../vendor/image-builder/images/capi/ansible/node.yml"
    command = "ansible-playbook"
    only = ["openstack.kubernetes"]
    user = "ubuntu"
    use_proxy = false
    extra_arguments = [
      "-v",
      "--extra-vars",
      "additional_executables=${var.additional_executables}",
      "--extra-vars",
      "additional_executables_list=${var.additional_executables_list}",
      "--extra-vars",
      "additional_executables_destination_path=${var.additional_executables_destination_path}",
      "--extra-vars",
      "additional_registry_images=${var.additional_registry_images}",
      "--extra-vars",
      "additional_registry_images_list=${var.additional_registry_images_list}",
      "--extra-vars",
      "additional_url_images=${var.additional_url_images}",
      "--extra-vars",
      "additional_url_images_list=${var.additional_url_images_list}",
      "--extra-vars",
      "build_target=${var.build_target}",
      "--extra-vars",
      "containerd_additional_settings=${var.containerd_additional_settings}",
      "--extra-vars",
      "containerd_cri_socket=${var.containerd_cri_socket}",
      "--extra-vars",
      "containerd_sha256=${var.containerd_sha256}",
      "--extra-vars",
      "containerd_url=${local.containerd_url}",
      "--extra-vars",
      "containerd_version=${var.containerd_version}",
      "--extra-vars",
      "containerd_wasm_shims_runtimes=\"${var.containerd_wasm_shims_runtimes}\"",
      "--extra-vars",
      "containerd_wasm_shims_sha256=${var.containerd_wasm_shims_sha256}",
      "--extra-vars",
      "containerd_wasm_shims_url=${local.containerd_wasm_shims_url}",
      "--extra-vars",
      "containerd_wasm_shims_version=${var.containerd_wasm_shims_version}",
      "--extra-vars",
      "crictl_sha256=${local.crictl_sha256}",
      "--extra-vars",
      "crictl_source_type=${var.crictl_source_type}",
      "--extra-vars",
      "crictl_url=${local.crictl_url}",
      "--extra-vars",
      "disable_public_repos=${var.disable_public_repos}",
      "--extra-vars",
      "extra_debs=\"${var.extra_debs}\"",
      "--extra-vars",
      "extra_repos=\"${var.extra_repos}\"",
      "--extra-vars",
      "extra_rpms=\"${var.extra_rpms}\"",
      "--extra-vars",
      "firstboot_custom_roles_post=\"${var.firstboot_custom_roles_post}\"",
      "--extra-vars",
      "firstboot_custom_roles_pre=\"${var.firstboot_custom_roles_pre}\"",
      "--extra-vars",
      "http_proxy=${var.http_proxy}",
      "--extra-vars",
      "https_proxy=${var.https_proxy}",
      "--extra-vars",
      "load_additional_components=${var.load_additional_components}",
      "--extra-vars",
      "kubeadm_template=${var.kubeadm_template}",
      "--extra-vars",
      "kubernetes_cni_deb_version=${local.kubernetes_cni_deb_version}",
      "--extra-vars",
      "kubernetes_cni_http_checksum=${local.kubernetes_cni_http_checksum}",
      "--extra-vars",
      "kubernetes_cni_http_source=${var.kubernetes_cni_http_source}",
      "--extra-vars",
      "kubernetes_cni_rpm_version=${var.kubernetes_cni_rpm_version}",
      "--extra-vars",
      "kubernetes_cni_semver=${local.kubernetes_cni_semver}",
      "--extra-vars",
      "kubernetes_cni_source_type=${var.kubernetes_cni_source_type}",
      "--extra-vars",
      "kubernetes_container_registry=${var.kubernetes_container_registry}",
      "--extra-vars",
      "kubernetes_deb_gpg_key=${var.kubernetes_deb_gpg_key}",
      "--extra-vars",
      "kubernetes_deb_repo=${var.kubernetes_deb_repo}",
      "--extra-vars",
      "kubernetes_deb_version=${local.kubernetes_deb_version}",
      "--extra-vars",
      "kubernetes_http_source=${var.kubernetes_http_source}",
      "--extra-vars",
      "kubernetes_load_additional_imgs=${var.kubernetes_load_additional_imgs}",
      "--extra-vars",
      "kubernetes_rpm_gpg_check=${var.kubernetes_rpm_gpg_check}",
      "--extra-vars",
      "kubernetes_rpm_gpg_key=${var.kubernetes_rpm_gpg_key}",
      "--extra-vars",
      "kubernetes_rpm_repo=${local.kubernetes_rpm_repo}",
      "--extra-vars",
      "kubernetes_rpm_version=${var.kubernetes_rpm_version}",
      "--extra-vars",
      "kubernetes_semver=${local.kubernetes_semver}",
      "--extra-vars",
      "kubernetes_source_type=${var.kubernetes_source_type}",
      "--extra-vars",
      "node_custom_roles_post=\"${var.node_custom_roles_post}\"",
      "--extra-vars",
      "node_custom_roles_pre=\"${var.node_custom_roles_pre}\"",
      "--extra-vars",
      "no_proxy=${var.no_proxy}",
      "--extra-vars",
      "pause_image=${var.pause_image}",
      "--extra-vars",
      "pip_conf_file=${var.pip_conf_file}",
      "--extra-vars",
      "python_path=${var.python_path}",
      "--extra-vars",
      "redhat_epel_rpm=${var.redhat_epel_rpm}",
      "--extra-vars",
      "reenable_public_repos=${var.reenable_public_repos}",
      "--extra-vars",
      "remove_extra_repos=${var.remove_extra_repos}",
      "--extra-vars",
      "systemd_prefix=${var.systemd_prefix}",
      "--extra-vars",
      "sysusr_prefix=${var.sysusr_prefix}",
      "--extra-vars",
      "sysusrlocal_prefix=${var.sysusrlocal_prefix}",
    ]
    groups = ["all"]
    ansible_env_vars = [
      "ANSIBLE_SSH_RETRIES=10", 
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=60s'",
      "ANSIBLE_PIPELINING=true",
    ]
  }

  post-processor "manifest" {
    custom_data = {
      source = "${source.name}"
    }
  }
}
