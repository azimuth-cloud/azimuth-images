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

variable "floating_ip_network" {
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

source "openstack" "windows-webconsole" {
  image_name = "${source.name}-${local.timestamp}"
  image_visibility = "private"
  image_disk_format = "${var.disk_format}"
  image_min_disk = "${var.volume_size}"
  image_tags = ["azimuth_web_console_supported"]

  source_image_name = "${var.source_image_name}"
  flavor = "${var.flavor}"
  networks = ["${var.network}"]
  security_groups = "${var.security_groups}"
  floating_ip_network = "${var.floating_ip_network}"

  # In order to be able to specify an image disk format, we must be using a Cinder volume
  use_blockstorage_volume = true
  volume_size = "${var.volume_size}"

  communicator = "winrm"
  winrm_username = "${var.winrm_username}"
  winrm_use_ssl = true
  winrm_insecure = true
}

build {
  source "source.openstack.windows-webconsole" { }

  provisioner "ansible" {
    galaxy_file = "${path.root}/../requirements.yml"
    playbook_file = "${path.root}/../ansible/windows-webconsole.yml"
    use_proxy = false
    user = "${var.winrm_username}"
    extra_arguments = [
      "-vvv",
      "--extra-vars",
      "ansible_winrm_server_cert_validation=ignore"
    ]
  }

  post-processor "manifest" {
    custom_data = {
      source = "${source.name}"
    }
  }
}
