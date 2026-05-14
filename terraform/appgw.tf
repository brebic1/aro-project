resource "azurerm_application_gateway" "appgw" {
    name = "appgw"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    sku {
        name = "Standard_v2"
        tier = "Standard_v2"
        capacity = 1
    }
    gateway_ip_configuration {
        name = "appgw-ip-config"
        subnet_id = azurerm_subnet.appgw_subnet.id
    }
    frontend_port {
        name = "appgw-frontend-port"
        port = 443
    }
    frontend_ip_configuration {
        name = "appgw-frontend-ip"
        public_ip_address_id = azurerm_public_ip.appgw_pip.id
    }
    ssl_certificate {
        name = "appgw-ssl-cert"
        key_vault_secret_id = azurerm_key_vault_certificate.kv_cert.secret_id
    }


    http_listener {
        name = "appgw-http-listener"
        frontend_ip_configuration_name = "appgw-frontend-ip"
        frontend_port_name = "appgw-frontend-port"
        protocol = "Https"
        ssl_certificate_name = "appgw-ssl-cert"
    }

    backend_address_pool {
        name = "aks-backend-pool"
        ip_addresses = ["10.0.2.33"]
        
    }
    backend_http_settings {
        name = "aks-http-settings"
        cookie_based_affinity = "Disabled"
        port = 80
        protocol = "Http"
        request_timeout = 30
    }

    backend_address_pool {
        name = "func-backend-pool"
        fqdns = ["aro-windows-function-app.azurewebsites.net"]

    }
    
    backend_http_settings {
        name = "func-http-settings"
        cookie_based_affinity = "Disabled"
        port = 443
        protocol = "Https"
        request_timeout = 30
        pick_host_name_from_backend_address = true
        probe_name = "func-probe"
    }
    probe {
        name = "func-probe"
        protocol = "Https"
        host = "aro-windows-function-app.azurewebsites.net"
        path = "/api/HelloFunc"
        interval = 30
        timeout = 30
        unhealthy_threshold = 3
    }

    url_path_map {
        name = "pmap"
        default_backend_address_pool_name = "aks-backend-pool"
        default_backend_http_settings_name = "aks-http-settings"

        path_rule {
            name = "func-path-rule"
            paths = ["/functionap/*", "/functionap"]
            backend_address_pool_name = "func-backend-pool"
            backend_http_settings_name = "func-http-settings"
            rewrite_rule_set_name = "rewrite-set"
        }

        path_rule {
            name = "aks-path-rule"
            paths = ["/aks/*" , "/aks"]
            backend_address_pool_name = "aks-backend-pool"
            backend_http_settings_name = "aks-http-settings"
        }
    }


    request_routing_rule {
        name = "mrule"
        rule_type = "PathBasedRouting"
        http_listener_name = "appgw-http-listener"
        url_path_map_name = "pmap"
        priority = 100
    }

    identity {
            type = "UserAssigned"
            identity_ids = [
                azurerm_user_assigned_identity.appgw_identity.id
            ]
    }
        rewrite_rule_set {
        name = "rewrite-set"

        rewrite_rule {
            name          = "rewrite-func"
            rule_sequence = 100

            condition {
                variable    = "var_uri_path"
                pattern     = "^/functionap/?$" 
                ignore_case = true
            }

            url {
                path = "/api/HelloFunc"
                reroute = false
            }
        }
    }

    tags = local.tags

    depends_on = [ 
        azurerm_key_vault_access_policy.appgw_policy,
        azurerm_key_vault_certificate.kv_cert
    ]
}
