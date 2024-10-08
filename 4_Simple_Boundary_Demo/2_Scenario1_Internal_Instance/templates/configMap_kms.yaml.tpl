disable_mlock = true

listener "tcp" {
    address = "0.0.0.0"
    purpose = "proxy"
    tls_disable = true
}

listener "tcp" {
    address = "0.0.0.0"
    purpose = "ops"
    tls_disable = true
}

worker {
    name = "${instance_id}"
    initial_upstreams = ["${upstream}:9202"]
    recording_storage_minimum_available_capacity = "500MB"
    recording_storage_path="/tmp/boundary"
    tags {
        type = ["${worker_type}", "${function}"]
    }
}

kms "gcpckms" {
    purpose     = "worker-auth"
    key_ring    = "${key_ring}"
    crypto_key  = "${cryto_key_worker}"
    project     = "${project}"
    region      = "${location}"
}