#####
# General variables
#####

variable "source_image_name" {
  type = string
}

variable "network" {
  type = string
}

variable "floating_ip" {
  type = string
}

variable "flavor" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "volume_type" {
  type = string
}

variable "volume_size" {
  type = number
  default = 10
}

variable "disk_format" {
  type = string
  default = "qcow2"
}

variable "distro_name" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "skip_create_image" {
  type = bool
  default = false
}

#####
# Kubernetes-specific variables
#####

variable "additional_executables" {
  type = string
}

variable "additional_executables_list" {
  type = string
}

variable "additional_executables_destination_path" {
  type = string
}

variable "additional_registry_images" {
  type = string
}

variable "additional_registry_images_list" {
  type = string
}

variable "additional_url_images" {
  type = string
}

variable "additional_url_images_list" {
  type = string
}

variable "build_target" {
  type = string
}

variable "containerd_additional_settings" {
  type = string
}

variable "containerd_arch" {
  type = string
}

variable "containerd_cri_socket" {
  type = string
}

variable "containerd_sha256" {
  type = string
}

variable "containerd_url" {
  type = string
}

variable "containerd_version" {
  type = string
}

variable "containerd_wasm_shims_arch" {
  type = string
}

variable "containerd_wasm_shims_runtimes" {
  type = string
}

variable "containerd_wasm_shims_sha256" {
  type = string
}

variable "containerd_wasm_shims_url" {
  type = string
}

variable "containerd_wasm_shims_version" {
  type = string
}

variable "crictl_arch" {
  type = string
}

variable "crictl_sha256" {
  type = string
}

variable "crictl_source_type" {
  type = string
}

variable "crictl_url" {
  type = string
}

variable "crictl_version" {
  type = string
}

variable "disable_public_repos" {
  type = string
}

variable "ecr_credential_provider" {
  type = string
}

variable "enable_containerd_audit" {
  type = string
}

variable "extra_debs" {
  type = string
}

variable "extra_repos" {
  type = string
}

variable "extra_rpms" {
  type = string
}

variable "firstboot_custom_roles_post" {
  type = string
}

variable "firstboot_custom_roles_pre" {
  type = string
}

variable "http_proxy" {
  type = string
}

variable "https_proxy" {
  type = string
}

variable "load_additional_components" {
  type = string
}

variable "kubeadm_template" {
  type = string
}

variable "kubernetes_cni_deb_version" {
  type = string
}

variable "kubernetes_cni_http_checksum" {
  type = string
}

variable "kubernetes_cni_http_checksum_arch" {
  type = string
}

variable "kubernetes_cni_http_source" {
  type = string
}

variable "kubernetes_cni_rpm_version" {
  type = string
}

variable "kubernetes_cni_semver" {
  type = string
}

variable "kubernetes_cni_source_type" {
  type = string
}

variable "kubernetes_container_registry" {
  type = string
}

variable "kubernetes_deb_gpg_key" {
  type = string
}

variable "kubernetes_deb_repo" {
  type = string
}

variable "kubernetes_deb_version" {
  type = string
}

variable "kubernetes_enable_automatic_resource_sizing" {
  type = string
}

variable "kubernetes_goarch" {
  type = string
}

variable "kubernetes_http_source" {
  type = string
}

variable "kubernetes_load_additional_imgs" {
  type = string
}

variable "kubernetes_rpm_gpg_check" {
  type = string
}

variable "kubernetes_rpm_gpg_key" {
  type = string
}

variable "kubernetes_rpm_repo" {
  type = string
}

variable "kubernetes_rpm_repo_arch" {
  type = string
}

variable "kubernetes_rpm_version" {
  type = string
}

variable "kubernetes_semver" {
  type = string
}

variable "kubernetes_series" {
  type = string
}

variable "kubernetes_source_type" {
  type = string
}

variable "node_custom_roles_post" {
  type = string
}

variable "node_custom_roles_pre" {
  type = string
}

variable "no_proxy" {
  type = string
}

variable "pause_image" {
  type = string
}

variable "pip_conf_file" {
  type = string
}

variable "python_path" {
  type = string
}

variable "redhat_epel_rpm" {
  type = string
}

variable "reenable_public_repos" {
  type = string
}

variable "remove_extra_repos" {
  type = string
}

variable "systemd_prefix" {
  type = string
}

variable "sysusr_prefix" {
  type = string
}

variable "sysusrlocal_prefix" {
  type = string
}

variable "ubuntu_repo" {
  type = string
}

variable "ubuntu_security_repo" {
  type = string
}

#####
# Locals
#####

locals {
    build_timestamp = formatdate("YYMMDD-hhmm", timestamp())

    containerd_url_default = "https://github.com/containerd/containerd/releases/download/v${var.containerd_version}/cri-containerd-cni-${var.containerd_version}-linux-${var.containerd_arch}.tar.gz"
    containerd_url = element([for e in [var.containerd_url, local.containerd_url_default]: e if e != ""], 0)

    containerd_wasm_shims_url_default = "https://github.com/deislabs/containerd-wasm-shims/releases/download/${var.containerd_wasm_shims_version}/containerd-wasm-shims-v1-linux-${var.containerd_wasm_shims_arch}.tar.gz"
    containerd_wasm_shims_url = element([for e in [var.containerd_wasm_shims_url, local.containerd_wasm_shims_url_default]: e if e != ""], 0)

    crictl_sha256_default = "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${var.crictl_version}/crictl-v${var.crictl_version}-linux-${var.crictl_arch}.tar.gz.sha256"
    crictl_sha256 = element([for e in [var.crictl_sha256, local.crictl_sha256_default]: e if e != ""], 0)

    crictl_url_default = "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${var.crictl_version}/crictl-v${var.crictl_version}-linux-${var.crictl_arch}.tar.gz"
    crictl_url = element([for e in [var.crictl_url, local.crictl_url_default]: e if e != ""], 0)

    kubernetes_cni_http_checksum_default = "sha256:https://storage.googleapis.com/k8s-artifacts-cni/release/${var.kubernetes_cni_semver}/cni-plugins-linux-${var.kubernetes_cni_http_checksum_arch}-${var.kubernetes_cni_semver}.tgz.sha256"
    kubernetes_cni_http_checksum = element([for e in [var.kubernetes_cni_http_checksum, local.kubernetes_cni_http_checksum_default]: e if e != ""], 0)

    kubernetes_deb_gpg_key_default = "https://pkgs.k8s.io/core:/stable:/${var.kubernetes_series}/deb/Release.key"
    kubernetes_deb_gpg_key = element([for e in [var.kubernetes_deb_gpg_key, local.kubernetes_deb_gpg_key_default]: e if e != ""], 0)

    kubernetes_deb_repo_default = "https://pkgs.k8s.io/core:/stable:/${var.kubernetes_series}/deb/"
    kubernetes_deb_repo = element([for e in [var.kubernetes_deb_repo, local.kubernetes_deb_repo_default]: e if e != ""], 0)

    kubernetes_rpm_gpg_key_default = "https://pkgs.k8s.io/core:/stable:/${var.kubernetes_series}/rpm/repodata/repomd.xml.key"
    kubernetes_rpm_gpg_key = element([for e in [var.kubernetes_rpm_gpg_key, local.kubernetes_rpm_gpg_key_default]: e if e != ""], 0)

    kubernetes_rpm_repo_default = "https://pkgs.k8s.io/core:/stable:/${var.kubernetes_series}/rpm/"
    kubernetes_rpm_repo = element([for e in [var.kubernetes_rpm_repo, local.kubernetes_rpm_repo_default]: e if e != ""], 0)
}

#####
# Build
#####

source "openstack" "kubernetes" {
  # Allow image creation to be skipped for build tests
  skip_create_image = var.skip_create_image

  image_name = "${var.distro_name}-kube-${var.kubernetes_semver}-${local.build_timestamp}"
  image_visibility = "private"
  image_disk_format = var.disk_format

  source_image_name = var.source_image_name
  flavor = var.flavor
  networks = [var.network]
  security_groups = var.security_groups
  floating_ip = var.floating_ip

  use_blockstorage_volume = true
  volume_type = var.volume_type
  volume_size = var.volume_size

  communicator = "ssh"
  ssh_username = var.ssh_username
}

build {
  source "source.openstack.kubernetes" { }

  provisioner "ansible" {
    galaxy_file = "${path.root}/../requirements.yml"
    playbook_file = "${path.root}/../ansible/kubernetes.yml"
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
      "ecr_credential_provider=${var.ecr_credential_provider}",
      "--extra-vars",
      "enable_containerd_audit=${var.enable_containerd_audit}",
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
      "kubernetes_cni_deb_version=${var.kubernetes_cni_deb_version}",
      "--extra-vars",
      "kubernetes_cni_http_checksum=${local.kubernetes_cni_http_checksum}",
      "--extra-vars",
      "kubernetes_cni_http_source=${var.kubernetes_cni_http_source}",
      "--extra-vars",
      "kubernetes_cni_rpm_version=${var.kubernetes_cni_rpm_version}",
      "--extra-vars",
      "kubernetes_cni_semver=${var.kubernetes_cni_semver}",
      "--extra-vars",
      "kubernetes_cni_source_type=${var.kubernetes_cni_source_type}",
      "--extra-vars",
      "kubernetes_container_registry=${var.kubernetes_container_registry}",
      "--extra-vars",
      "kubernetes_deb_gpg_key=${local.kubernetes_deb_gpg_key}",
      "--extra-vars",
      "kubernetes_deb_repo=${local.kubernetes_deb_repo}",
      "--extra-vars",
      "kubernetes_deb_version=${var.kubernetes_deb_version}",
      "--extra-vars",
      "kubernetes_enable_automatic_resource_sizing=${var.kubernetes_enable_automatic_resource_sizing}",
      "--extra-vars",
      "kubernetes_goarch=${var.kubernetes_goarch}",
      "--extra-vars",
      "kubernetes_http_source=${var.kubernetes_http_source}",
      "--extra-vars",
      "kubernetes_load_additional_imgs=${var.kubernetes_load_additional_imgs}",
      "--extra-vars",
      "kubernetes_rpm_gpg_check=${var.kubernetes_rpm_gpg_check}",
      "--extra-vars",
      "kubernetes_rpm_gpg_key=${local.kubernetes_rpm_gpg_key}",
      "--extra-vars",
      "kubernetes_rpm_repo=${local.kubernetes_rpm_repo}",
      "--extra-vars",
      "kubernetes_rpm_version=${var.kubernetes_rpm_version}",
      "--extra-vars",
      "kubernetes_semver=${var.kubernetes_semver}",
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
      "--extra-vars",
      "ubuntu_repo=${var.ubuntu_repo}",
      "--extra-vars",
      "ubuntu_security_repo=${var.ubuntu_security_repo}",
    ]
    ansible_env_vars = ["ANSIBLE_SSH_RETRIES=10"]
  }

  post-processor "manifest" {
    custom_data = {
      kubernetes_version = var.kubernetes_semver
    }
  }
}
