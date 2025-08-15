provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "k8s-monitoring-lab"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "cma-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "cmaaks"

default_node_pool {
  name       = "default"
  node_count = 2
  vm_size    = "Standard_B2ms"
}

  identity {
    type = "SystemAssigned"
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
