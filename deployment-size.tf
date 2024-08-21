##################################################
# standard deployment sizes are specified in 
# this object
##################################################

locals {
  deployment_size = {
    small = {
      db            = "db.r6g.large",
      min_node_count    = 2,
      max_node_count    = 3,
      node_instance = "r6i.xlarge"
      cache         = "cache.m6g.large"
    },
    medium = {
      db            = "db.r6g.xlarge",
      min_node_count    = 2,
      max_node_count    = 4,
      node_instance = "r6i.xlarge"
      cache         = "cache.m6g.large"
    },
    large = {
      db            = "db.r6g.2xlarge",
      min_node_count    = 2,
      max_node_count    = 3,
      node_instance = "r6i.2xlarge"
      cache         = "cache.m6g.xlarge"
    },
    xlarge = {
      db            = "db.r6g.4xlarge",
      min_node_count    = 3,
      max_node_count    = 4,
      node_instance = "r6i.2xlarge"
      cache         = "cache.m6g.xlarge"
    },
    xxlarge = {
      db            = "db.r6g.8xlarge",
      min_node_count    = 3,
      max_node_count    = 5,
      node_instance = "r6i.4xlarge"
      cache         = "cache.m6g.2xlarge"
    }
  }
}