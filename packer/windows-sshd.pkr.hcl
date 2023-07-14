# Use like:
#  $ PACKER_LOG=1 packer build --on-error=ask -var-file=<something>.pkrvars.hcl openstack.pkr.hcl

# "timestamp" template function replacement:s
locals { timestamp = formatdate("YYMMDD-hhmm", timestamp())}

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

variable "winrm_username" {
  type = string
  default = "Admin"
}

variable "security_groups" {
  type = list(string)
}

variable "volume_size" {
  type = number
  default = 20
}

variable "disk_format" {
  type = string
  default = "qcow2"
}

variable "skip_create_image" {
  type = bool
  default = false
}

source "openstack" "windows-sshd" {
  # Allow image creation to be skipped for build tests
  skip_create_image = var.skip_create_image

  image_name = "${source.name}-${local.timestamp}"
  image_visibility = "private"
  image_disk_format = var.disk_format

  source_image_name = var.source_image_name
  flavor = var.flavor
  networks = [var.network]
  security_groups = var.security_groups
  floating_ip = var.floating_ip

  use_blockstorage_volume = true
  volume_size = var.volume_size

  communicator = "winrm"
  winrm_username = var.winrm_username
  winrm_use_ssl = true
  winrm_insecure = true
}

build {
  source "source.openstack.windows-sshd" { }

  provisioner "ansible" {
    galaxy_file = "${path.root}/../requirements.yml"
    playbook_file = "${path.root}/../ansible/windows-sshd.yml"
    use_proxy = false
    user = var.winrm_username
    extra_arguments = [
      "-vvv",
      "--extra-vars",
      "ansible_winrm_server_cert_validation=ignore"
    ]
  }

  post-processor "manifest" {
    custom_data = {
      source = source.name
    }
  }
}
