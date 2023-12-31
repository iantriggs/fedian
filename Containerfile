FROM quay.io/fedora-ostree-desktops/silverblue:38

# Delete some silly repos

RUN rm /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    rm /etc/yum.repos.d/google-chrome.repo && \
    rm /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo && \
    rm /etc/yum.repos.d/rpmfusion-nonfree-steam.repo

# Copy some configs from ublue

COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-udev-rules /
COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-update-services /
COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-signing /


# Setup RPM fusion

RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-38.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-38.noarch.rpm && \
    ostree container commit

# Remove some stuff

COPY removals .

# Strip comments
RUN sed -i -e 's/\s*#.*$//' -e '/^[[:space:]]*$/d' removals

RUN cat removals | xargs rpm-ostree override remove && \
    ostree container commit && \
    rm removals

# Layer some packages

COPY layers .

# Strip comments
RUN sed -i -e 's/\s*#.*$//' -e '/^[[:space:]]*$/d' layers

RUN cat layers | xargs rpm-ostree install -y && \
    ostree container commit && \
    rm layers


# Remove RPM fusion
RUN rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release && \
    ostree container commit


# Add cosign public key to image and setup the container policy
COPY cosign.pub /usr/etc/pki/containers/fedian.pub
COPY files/container-policy-additions.json /tmp/
COPY files/fedian.yaml /usr/etc/containers/registries.d/
RUN cat /tmp/container-policy-additions.json /usr/etc/containers/policy.json \
    | jq -s '.[0] * .[1]' > /usr/etc/containers/policy.json && \
    rm /tmp/container-policy-additions.json

# Install Distrobox
RUN rpm-ostree install distrobox && \
    ostree container commit

# Start up some services

RUN systemctl enable rpm-ostreed-automatic.timer && \
    systemctl enable rpm-ostree-countme.timer && \
    systemctl enable flatpak-system-update.timer

