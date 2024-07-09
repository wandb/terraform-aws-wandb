##################################################
# standard deployment sizes are specified in 
# this object
##################################################

locals {
  deployment_size = {
    small = {
      db             = "db.r6g.large",
      node_count     = 2,
      node_instance  = "r6i.xlarge",
      cache          = "cache.m6g.large",
      min_node_count = 1,
      max_node_count = 3
    },
    medium = {
      db             = "db.r6g.xlarge",
      node_count     = 2,
      node_instance  = "r6i.xlarge",
      cache          = "cache.m6g.large",
      min_node_count = 2,
      max_node_count = 5
    },
    large = {
      db             = "db.r6g.2xlarge",
      node_count     = 2,
      node_instance  = "r6i.2xlarge",
      cache          = "cache.m6g.xlarge",
      min_node_count = 2,
      max_node_count = 6
    },
    xlarge = {
      db             = "db.r6g.4xlarge",
      node_count     = 3,
      node_instance  = "r6i.2xlarge",
      cache          = "cache.m6g.xlarge",
      min_node_count = 2,
      max_node_count = 8
    },
    xxlarge = {
      db             = "db.r6g.8xlarge",
      node_count     = 3,
      node_instance  = "r6i.4xlarge",
      cache          = "cache.m6g.2xlarge",
      min_node_count = 3,
      max_node_count = 10
    }
  }
}