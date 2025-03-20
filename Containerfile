ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="42"
ARG SOURCE_ORG="${SOURCE_ORG:-fedora-ostree-desktops}"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-main"
ARG BASE_IMAGE="quay.io/${SOURCE_ORG}/${BASE_IMAGE_NAME}"
ARG IMAGE_REGISTRY=ghcr.io/ublue-os

FROM scratch AS ctx
COPY / /

## bluefin image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG AKMODS_FLAVOR="coreos-stable"
ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="42"
ARG IMAGE_NAME="silverblue"
ARG IMAGE_VENDOR="iitzrohan"
ARG KERNEL="6.13.6-200.fc41.x86_64"
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""

# Build, cleanup, commit.
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/shared/build-base.sh

## bluefin-dx developer edition image section
FROM base AS dx

ARG AKMODS_FLAVOR="coreos-stable"
ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="42"
ARG IMAGE_NAME="silverblue-dx"
ARG IMAGE_VENDOR="iitzrohan"
ARG KERNEL="6.13.6-200.fc41.x86_64"
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""

# Build, Clean-up, Commit
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/shared/build-dx.sh
