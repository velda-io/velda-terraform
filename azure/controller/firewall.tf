resource "azurerm_network_security_group" "controller_nsg" {
  name                = "${var.name}-controller-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "api_public" {
  count                       = var.external_access.allow_direct_api_access ? 1 : 0
  name                        = "${var.name}-http-public"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443", "50051"]
  source_address_prefixes     = var.connection_source
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.controller_nsg.name
}

resource "azurerm_network_security_rule" "from_agent" {
  name                                  = "${var.name}-from-agent"
  priority                              = 200
  direction                             = "Inbound"
  access                                = "Allow"
  protocol                              = "Tcp"
  source_port_range                     = "*"
  destination_port_ranges               = ["80", "443", "50051", "2049", "7655"]
  source_application_security_group_ids = [azurerm_application_security_group.agent_asg.id]
  destination_address_prefix            = "*"
  resource_group_name                   = var.resource_group_name
  network_security_group_name           = azurerm_network_security_group.controller_nsg.name
}

resource "azurerm_network_security_rule" "agent_connect_direct" {
  count                       = var.external_access.use_proxy ? 0 : 1
  name                        = "${var.name}-agent-ssh-direct"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["2222", "22"]
  source_address_prefixes     = var.connection_source
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "controller_access" {
  name                        = "${var.name}-controller-access"
  priority                    = 301
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["2222", "22"]
  source_address_prefixes     = var.connection_source
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.controller_nsg.name
}
# Agent Network Security Group
resource "azurerm_network_security_group" "agent_nsg" {
  name                = "${var.name}-agent-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_application_security_group" "agent_asg" {
  name                = "${var.name}-agent-asg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_application_security_group" "controller_asg" {
  name                = "${var.name}-controller-asg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_interface_application_security_group_association" "controller_asg_assoc" {
  network_interface_id          = azurerm_network_interface.controller_nic.id
  application_security_group_id = azurerm_application_security_group.controller_asg.id
}

resource "azurerm_network_security_rule" "ssh_from_controller" {
  name                                       = "${var.name}-ssh-from-controller"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_ranges                    = ["22", "2222"]
  source_application_security_group_ids      = [azurerm_application_security_group.controller_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.agent_asg.id]
  resource_group_name                        = var.resource_group_name
  network_security_group_name                = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "between_agents" {
  name                                       = "${var.name}-between-agents"
  priority                                   = 110
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "*"
  source_port_range                          = "*"
  destination_port_range                     = "*"
  source_application_security_group_ids      = [azurerm_application_security_group.agent_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.agent_asg.id]
  resource_group_name                        = var.resource_group_name
  network_security_group_name                = azurerm_network_security_group.agent_nsg.name
}

resource "azurerm_network_security_rule" "outbound_controller" {
  name                        = "${var.name}-outbound-controller"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.controller_nsg.name
}

resource "azurerm_network_security_rule" "outbound_agent" {
  name                        = "${var.name}-outbound-agent"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.agent_nsg.name
}
