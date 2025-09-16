##################################################
# standard deployment sizes are specified in 
# this object
##################################################

locals {
  deployment_size = {
    small = {
      db               = "db.r6g.large",
      min_nodes_per_az = 1,
      max_nodes_per_az = 4,
      node_instance    = "r6i.2xlarge"
      cache            = "cache.m6g.large"
      root_volume_size = 100
    },
    medium = {
      db               = "db.r6g.xlarge",
      min_nodes_per_az = 1,
      max_nodes_per_az = 4,
      node_instance    = "r6i.4xlarge"
      cache            = "cache.m6g.large"
      root_volume_size = 100
    },
    large = {
      db               = "db.r6g.2xlarge",
      min_nodes_per_az = 1,
      max_nodes_per_az = 4,
      node_instance    = "r6i.4xlarge"
      cache            = "cache.m6g.xlarge"
      root_volume_size = 256
    },
    xlarge = {
      db               = "db.r6g.4xlarge",
      min_nodes_per_az = 1,
      max_nodes_per_az = 4,
      node_instance    = "r6i.4xlarge"
      cache            = "cache.m6g.xlarge"
      root_volume_size = 256
    },
    xxlarge = {
      db               = "db.r6g.8xlarge",
      min_nodes_per_az = 1,
      max_nodes_per_az = 4,
      node_instance    = "r6i.4xlarge"
      cache            = "cache.m6g.2xlarge"
      root_volume_size = 256
    }
  }
}