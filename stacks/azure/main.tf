provider "azurerm" {
  features {}
}

# 1. Resource group
resource "azurerm_resource_group" "rg" {
  name     = "monitoring-lab"
  location = "East US"
}

# 2. Log Analytics workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "cma-loganalytics"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 3. Public IP for VM
resource "azurerm_public_ip" "pip" {
  name                = "pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"       # <-- Required for Standard SKU
  sku                 = "Standard"

  tags = {
    environment = "Lab"
  }
}


# 4. Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "cma-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# 5. Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "cma-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 6. Network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "cma-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 7. NIC
resource "azurerm_network_interface" "nic" {
  name                = "cma-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# 8. SSH Key (local public key file)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "cma-azure-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/Sebastian Silva C/.ssh/lab10.pub") # Update path if needed
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# 9. Action group for alerts
resource "azurerm_monitor_action_group" "ag" {
  name                = "cma-alert-action"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "cmaalert"

  email_receiver {
    name                    = "sendtoadmin"
    email_address           = "sebastian@playbookvisualarts.com" # Change to your email
    use_common_alert_schema = true
  }
}

# 10. Metric alert for CPU
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "cma-cpu-high-azure"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "Alert when CPU > 5%"
  severity            = 3
  enabled             = true
  frequency           = "PT1M"
  window_size         = "PT1M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}
