namespace     = "operator-upgrade"
domain_name   = "sandbox-aws.wandb.ml"
zone_id       = "Z032246913CW32RVRY0WU"
subdomain     = "operator-upgrade"
wandb_license = "eyJh"
# wandb_version = "0.51.2" Is now coming from the Release Channel or set in the User Spec.

# Needed Operator Variables for Upgrade
size                 = "small"
enable_dummy_dns     = true
enable_operator_alb  = true
custom_domain_filter = "sandbox-aws.wandb.ml" 