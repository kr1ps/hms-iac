provider "vsphere" {
  vsphere_server = var.vsphere_server
  user           = var.vsphere_user
  password       = var.vsphere_password

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

# data "vsphere_compute_cluster" "cluster" {
#   name          = var.cluster
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

data "vsphere_resource_pool" "pool" {
  name          = "esx-02.kr1ps.com/Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "vm_template" {
  name          = var.ubuntu_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = terraform.workspace == "default" ? "hms-prod.kr1ps.com" : "hms-${terraform.workspace}.kr1ps.com" #"${terraform.workspace}-vm-terraform"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 6
  memory   = 4096

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = 5

  disk {
    label            = "disk0"
    thin_provisioned = true
    size             = 120
  }

  guest_id = "ubuntu64Guest"

  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id
  }

  # #this block its for auto excecute ansible playbook on new ambient. this particular one its for the intial config (nameserver, static ip, etc)
   provisioner "local-exec" {
    command = "ansible-playbook -u '${var.ssh_user}' -i '${vsphere_virtual_machine.vm.default_ip_address},' ./ansible-hms/host-pre.yml -e 'tf_env=${terraform.workspace}' --key-file '~/.ssh/id_ed25519'"
   }
}

output "vm_ip" {
  value = vsphere_virtual_machine.vm.guest_ip_addresses
}


# output "web_url" {
#   value = "http://${vsphere_virtual_machine.vm.default_ip_address}"
# }

# example for output variable
# output.tf
# output "tf_gh_deployment_status_token" {
#   value       = var.GH_DEPLOYMENT_STATUS_TOKEN
#   sensitive   = true
# }