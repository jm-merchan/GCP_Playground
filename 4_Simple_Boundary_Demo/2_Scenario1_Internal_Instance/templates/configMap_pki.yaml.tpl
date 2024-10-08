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
    public_addr = "${public_addr}"
    initial_upstreams = ["${upstream}:9202"]
    recording_storage_minimum_available_capacity = "500MB"
    auth_storage_path = "/opt/boundary/data/"
    recording_storage_path="/tmp/boundary"
    controller_generated_activation_token = "${activation_token}"
    tags {
        type = ["${worker_type}", "${function}"]
    }
}