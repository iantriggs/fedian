FROM quay.io/fedora-ostree-desktops/silverblue:39

# Delete some silly repos
RUN rm /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    rm /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo && \
    rm /etc/yum.repos.d/rpmfusion-nonfree-steam.repo

# Copy some configs from ublue
COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-udev-rules /
COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-update-services /
COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-signing /

# Handle some additional repo files
COPY files/vscode.repo /etc/yum.repos.d/

# Setup RPM fusion
RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-39.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-39.noarch.rpm && \
    ostree container commit

# Remove packages we don't want
COPY removals .

# Strip comments and remove packages
RUN sed -i -e 's/\s*#.*$//' -e '/^[[:space:]]*$/d' removals && \
    cat removals | xargs rpm-ostree override remove && \
    rm removals && \
    ostree container commit

# Layer some packages
COPY layers .

# Strip comments and install packages
RUN sed -i -e 's/\s*#.*$//' -e '/^[[:space:]]*$/d' layers && \
    cat layers | xargs rpm-ostree install -y && \
    rm layers && \
    ostree container commit

# Override some packages
COPY overrides .

# Strip comments and override packages
RUN sed -i -e 's/\s*#.*$//' -e '/^[[:space:]]*$/d' overrides && \
    cat overrides | xargs -d ',' -n 2 sh -c 'rpm-ostree override remove $0 --install $1' && \
    rm overrides && \
    ostree container commit

# Remove RPM fusion
# RUN rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release && \
#     ostree container commit


# Install Chrome from the Google repo
# We will use this until an official Flatpak from Google is available
# RUN sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/yum.repos.d/google-chrome.repo && \
#     sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/google-chrome.repo && \
#     rpm-ostree install google-chrome-stable && \
#     ostree container commit

# Add cosign public key to image and setup the container policy
COPY cosign.pub /usr/etc/pki/containers/fedian.pub
COPY files/container-policy-additions.json /tmp/
COPY files/fedian.yaml /usr/etc/containers/registries.d/
RUN cat /tmp/container-policy-additions.json /usr/etc/containers/policy.json \
    | jq -s '.[0] * .[1]' > /usr/etc/containers/policy_new.json && \
    mv /usr/etc/containers/policy_new.json /usr/etc/containers/policy.json && \
    rm /tmp/container-policy-additions.json


# Install Firefox from Flatpak
# RUN flatpak install -y flathub org.mozilla.firefox

# Start up some services
# RUN systemctl enable rpm-ostreed-automatic.timer && \
#     systemctl enable rpm-ostree-countme.timer && \
#     systemctl enable flatpak-system-update.timer
