locals {
  bastion_host        = try(var.proxy_info.proxy_address, null)
  bastion_private_key = try(file(var.proxy_info.proxy_private_ssh_key_path), "")
  bastion_user        = try(var.proxy_info.proxy_ssh_user, null)

  instance_address = var.use_public_ip ? local.public_ip : local.private_ip
  display_name     = var.name

  script_path = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))
  install_script = templatefile("${path.module}/setup.tftpl", {
    resource_type                          = var.resource_type
    installation_s3_bucket                 = var.binaries_location.s3_bucket
    installation_s3_region                 = var.binaries_location.s3_region
    installation_s3_key                    = var.binaries_location.s3_key
    display_name                           = local.display_name
    password_secret                        = local.password_secret_name
    hub_sonarw_public_key                  = var.resource_type == "agentless-gw" ? var.hub_sonarw_public_key : ""
    primary_node_sonarw_public_key         = local.primary_node_sonarw_public_key
    primary_node_sonarw_private_key_secret = local.sonarw_secret_aws_name
    jsonar_uuid                            = random_uuid.jsonar_uuid.result
    additional_install_parameters          = var.additional_install_parameters
    access_tokens_array                    = local.access_tokens_array
  })
}

data "aws_region" "current" {}

resource "random_uuid" "jsonar_uuid" {}

resource "null_resource" "readiness" {
  count = var.skip_instance_health_verification == true ? 0 : 1
  connection {
    type        = "ssh"
    user        = local.ami_username
    private_key = file(var.ssh_key_path)
    host        = local.instance_address

    timeout = "5m"

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = [
      "if ! sudo timeout 900 cloud-init status --wait | grep done &>/dev/null; then",
      "  cat /var/log/user-data.log;",
      "  echo;",
      "  sudo cloud-init status;",
      "  exit 1;",
      "fi"
    ]
  }

  triggers = {
    instance_id = aws_instance.dsf_base_instance.id
  }

  depends_on = [
    aws_eip_association.eip_assoc
  ]
}
