terraform = {
  required_version = ">= 0.9.3"
}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {
  current = true
}

data "aws_ami" "k8s_1_7_debian_jessie_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["k8s-1.7-debian-jessie-amd64-hvm-ebs-2017-07-28"]
  }

  filter {
    name   = "owner-id"
    values = ["383156758163"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# This removes '.' if it is the last character
data "template_file" "cluster_fqdn" {
  template = "$${cluster_fqdn}"
  vars {
    cluster_fqdn = "${replace(var.cluster_fqdn, "/\\.$/", "")}"
  }
}

data "template_file" "az_letters" {
  template = "$${az_letters}"
  vars {
    az_letters = "${ replace(join(",", sort(data.aws_availability_zones.available.names)), data.aws_region.current.name, "") }"
  }
}

data "template_file" "master_resource_count" {
   template = "$${master_resource_count}"
   vars {
     master_resource_count = "${var.force_single_master == 1 ? 1 : length(data.aws_availability_zones.available.names)}"
   }
}

data "template_file" "master_azs" {
   template = "$${master_azs}"
   vars {
     master_azs = "${var.force_single_master == 1 ? element(sort(data.aws_availability_zones.available.names), 0) : join(",", data.aws_availability_zones.available.names)}"
   }
}

data "template_file" "etcd_azs" {
   template = "$${etcd_azs}"
   vars {
     etcd_azs = "${var.force_single_master == 1 ? element(split(",", data.template_file.az_letters.rendered), 0) : data.template_file.az_letters.rendered}"
   }
}
