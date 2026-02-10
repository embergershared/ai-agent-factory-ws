###############################################################################
# Module: Network Security Groups (one per subnet)
###############################################################################

# Create one NSG per subnet
resource "azurerm_network_security_group" "this" {
  for_each = var.subnet_ids

  name                = "${var.nsg_name_prefix}-snet-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Associate each NSG with its corresponding subnet
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnet_ids

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
