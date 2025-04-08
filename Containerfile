ARG KIND_VERSION
FROM docker.io/kindest/node:v${KIND_VERSION}
LABEL org.opencontainers.image.description="GHCRkindCluster" \
      org.opencontainers.image.version="${KIND_VERSION}"