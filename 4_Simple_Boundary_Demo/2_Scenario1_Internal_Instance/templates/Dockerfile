FROM debian:bullseye-slim

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg lsb-release ca-certificates && \
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y --no-install-recommends boundary-enterprise && \
    mkdir /opt/boundary/data /opt/boundary/config && \
    cp /etc/boundary.d/worker.hcl /opt/boundary/config/ && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Adjust permissions for boundary binary and directories
RUN chgrp -R 0 /usr/bin/boundary && \
    chmod -R g=u /usr/bin/boundary 

RUN chgrp -R 0 /etc/boundary.d && \
    chmod -R g=u /etc/boundary.d

# Ensure boundary user has ownership and permissions for /opt/boundary/data
RUN chown -R boundary:boundary /opt/boundary && \
    chmod -R 770 /opt/boundary && \
    chown -R boundary:boundary /opt && \
    chmod -R 770 /opt


USER boundary

ENTRYPOINT ["boundary"]
CMD ["server", "-config=/opt/boundary/config/worker.hcl"]
