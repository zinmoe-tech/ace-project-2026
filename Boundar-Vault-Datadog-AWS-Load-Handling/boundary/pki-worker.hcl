disable_mlock = true

hcp_boundary_cluster_id = "<HCP_BOUNDARY_CLUSTER_ID>"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  auth_storage_path = "/var/lib/boundary"
}

tags {
  type       = ["egress"]
  cloud      = ["aws"]
  pool       = ["aws-autoscaling"]
  target     = ["on-aws"]
  cred-store = ["vault"]
}

events {
  observations_enabled = true
  sysevents_enabled     = true

  sink "stderr" {
    name        = "all-events"
    description = "Boundary worker events"
    event_types = ["*"]
    format      = "cloudevents-json"
  }
}
