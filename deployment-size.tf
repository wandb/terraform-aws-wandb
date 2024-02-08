##################################################
# standard deployment sizes are specified in 
# this object
##################################################

locals {
  deployment_size = {
    small = {
      db            = "db.r6g.large",
      node_count    = 2,
      node_instance = "r6i.large"
      cache         = "cache.m6g.large"
    },
    medium = {
      db            = "db.r6g.xlarge",
      node_count    = 2,
      node_instance = "r6i.xlarge"
      cache         = "cache.m6g.large"
    },
    large = {
      db            = "db.r6g.2xlarge",
      node_count    = 2,
      node_instance = "r6i.2xlarge"
      cache         = "cache.m6g.xlarge"
    },
    xlarge = {
      db            = "db.r6g.4xlarge",
      node_count    = 3,
      node_instance = "r6i.4xlarge"
      cache         = "cache.m6g.xlarge"
    },
    xxlarge = {
      db            = "db.r6g.8xlarge",
      node_count    = 3,
      node_instance = "r6i.8xlarge"
      cache         = "cache.m6g.2xlarge"
    }
  }
}