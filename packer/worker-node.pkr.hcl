packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami_name" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-22.04-lts-amd64-server-*"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "worker-node" {
  ami_name      = "swimlane-k8s-worker-${local.timestamp}"
  instance_type = var.instance_type
  region        = var.aws_region
  source_ami_filter {
    filters = {
      name                = var.source_ami_name
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  ssh_username = var.ssh_username
  tags = {
    Name        = "Swimlane K8s Worker Node"
    Environment = "production"
    Project     = "devops-practical"
  }
}

build {
  name = "swimlane-worker-node"
  sources = [
    "source.amazon-ebs.worker-node"
  ]

  provisioner "file" {
    source      = "../ansible/"
    destination = "/tmp/ansible"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip ansible",
      "cd /tmp/ansible",
      "sudo ansible-playbook -i 'localhost,' -c local playbooks/ntp-setup.yml",
      "sudo ansible-playbook -i 'localhost,' -c local playbooks/kubernetes-deps.yml",
      "sudo rm -rf /tmp/ansible"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo cloud-init clean",
      "sudo rm -f /var/log/cloud-init.log",
      "sudo rm -f /var/log/cloud-init-output.log",
      "sudo rm -rf /var/lib/cloud/instances",
      "sudo rm -rf /var/lib/cloud/instance",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "sudo rm -rf /var/cache/apt/archives/*",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo sync"
    ]
  }
}
