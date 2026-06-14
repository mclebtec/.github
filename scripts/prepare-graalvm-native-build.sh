#!/usr/bin/env bash
# Prepare Linux CI runners for GraalVM native Docker images (Paketo + spring-boot:build-image).
# Consumer POMs activate native publish via -DskipImage=false (docker-image profile).

set -euo pipefail

SWAP_GB="${NATIVE_IMAGE_SWAP_GB:-8}"

echo "== GraalVM native image build prep =="
echo "    Native compile runs inside Paketo (spring-boot-maven-plugin build-image-no-fork)."
echo "    Consumer must set publishImage/nativeImage when skipImage=false."

if [[ "${SWAP_GB}" == "0" || -z "${SWAP_GB}" ]]; then
  echo "== Skipping swap (NATIVE_IMAGE_SWAP_GB=${SWAP_GB}) =="
  free -h || true
  exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "== Non-Linux host: skipping swap (ensure Docker Desktop has 10GB+ RAM for local native builds) =="
  exit 0
fi

if swapon --show | grep -q /swapfile; then
  echo "== Swap already enabled =="
  free -h
  exit 0
fi

echo "== Adding ${SWAP_GB}G swap for GraalVM native image compile =="
sudo fallocate -l "${SWAP_GB}G" /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
free -h
