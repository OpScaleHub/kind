#!/bin/bash

set -e

# This script mirrors required images for the NGINX ingress controller to GHCR.

# Define the images to mirror.
# Format: <source_image> <target_image_name> <target_tag>
IMAGES_TO_MIRROR=(
  "registry.k8s.io/ingress-nginx/controller:v1.8.1 ghcr.io/opscalehub/kind/ingress-nginx/controller v1.8.1"
  "registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20230407 ghcr.io/opscalehub/kind/ingress-nginx/kube-webhook-certgen v20230407"
)

for image_info in "${IMAGES_TO_MIRROR[@]}"; do
  read -r source_image target_image target_tag <<<"$image_info"
  
  echo "Mirroring image: $source_image"
  
  # Pull the source image
  docker pull "$source_image"
  
  # Tag the image for GHCR
  docker tag "$source_image" "${target_image}:${target_tag}"
  
  # Push the image to GHCR
  docker push "${target_image}:${target_tag}"
  
  echo "Successfully mirrored ${target_image}:${target_tag}"
  echo
done

echo "All images mirrored successfully."
