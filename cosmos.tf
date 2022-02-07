resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-centralindia-001"
  location = "centralindia"
}


resource "azurerm_cosmosdb_account" "db" {
  name                = "cosmos-cassandra-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
  capabilities    {
      name = "EnableCassandra"
  }
  
}

resource "azurerm_cosmosdb_cassandra_keyspace" "keyspace_sample" {
  name                = "keyspace_sample"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db.name  
  throughput          = 400  
}

resource "azurerm_cosmosdb_cassandra_table" "table_sample_events" {
  name                  = "events"
  cassandra_keyspace_id = azurerm_cosmosdb_cassandra_keyspace.keyspace_sample.id
  default_ttl = 3600
  #throughput          = 400
  schema {
    column {
      name = "id"
      type = "UUID"
    }
    column {
      name = "event_timestamp"
      type = "timestamp"
    }   
    partition_key {
      name = "id"            
    } 
   cluster_key {
        name = "event_timestamp"
        order_by = "Desc"
    }   
  }
}


# split the connection string to pass to custom shell script
# enumerated as host , username , secret and port
locals {
  host = [for s in split(";", azurerm_cosmosdb_account.db.connection_strings[4]) : split("=", s)[1] if s != ""]
}


resource "docker_image" "cassandra" {
  name         = "cassandra:latest"
  keep_locally = true
  depends_on = [ azurerm_cosmosdb_cassandra_table.table_sample_events]
  provisioner "local-exec" {
    command ="docker run --rm  -v $(pwd)/scripts.cql:/scripts.cql  --env SSL_VALIDATE=false --env SSL_VERSION=TLSv1_2 cassandra:latest cqlsh ${local.host[0]} ${local.host[3]} -u cosmos-cassandra-001 -p ${azurerm_cosmosdb_account.db.primary_master_key} --ssl -f /scripts.cql"
  }
}

