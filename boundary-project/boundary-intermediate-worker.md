disable_mlock = true
listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr        = "10.2.15.218"
  auth_storage_path  = "/home/ubuntu/boundary/worker1"
  initial_upstreams  = ["10.1.15.31:9202"]
  tags {
    type = ["worker1", "private", "ingress", "zone-a", "downstream"]
  }
}
events {
  audit_enabled        = true
  observations_enabled = true
  sysevents_enabled    = true
  telemetry_enabled    = false

  sink "stderr" {
    name        = "all-events"
    event_types = ["*"]
    format      = "cloudevents-json"
  }
}
