FROM debian:bullseye-slim

USER root

RUN groupadd --gid 1000 boundary && \
    useradd --uid 1000 --gid 1000 --shell /bin/bash boundary

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg lsb-release ca-certificates && \
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y --no-install-recommends boundary-enterprise && \
    mkdir -p /opt/boundary/data && mkdir -p /opt/boundary/config && \
    cp /etc/boundary.d/worker.hcl /opt/boundary/config/

RUN chgrp -R 0 /usr/bin/boundary && \
    chmod -R g=u /usr/bin/boundary && \ 
    chown -R boundary:boundary /opt/boundary

EXPOSE 9202 9203

USER boundary

ENTRYPOINT ["boundary"]
CMD ["server", "-config=/opt/boundary/config/worker.hcl"]
