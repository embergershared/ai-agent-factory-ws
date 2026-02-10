###############################################################################
# Module: Entra ID Application Registration
###############################################################################

terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

resource "azuread_application" "this" {
  display_name = var.display_name

  owners = var.owners

  tags = var.tags
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id

  owners = var.owners

  tags = var.tags
}
