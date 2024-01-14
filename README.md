# Fedian

My custom Fedora Silverblue setup.

Work in progress.

## Installation

Download and install Fedora Silverblue first.

### Rebase the image

First, reset your layers:

```bash
rpm-ostree reset
```

Now rebase onto the new image:

```bash
rpm-ostree rebase --experimental ostree-unverified-registry:ghcr.io/iantriggs/fedian
```

And reboot:

```bash
systemctl reboot
```

You're now booted into the new image. Now you can switch to the signed image:

```bash
rpm-ostree rebase --experimental ostree-image-signed:docker://ghcr.io/iantriggs/fedian
```

And reboot again:

```bash
systemctl reboot
```

You're now on the signed image.

## Rebasing to a dev branch

You can also rebase to a dev branch for testing. Just add the dev branch name as a tag:

```bash
rpm-ostree rebase --experimental ostree-image-signed:docker://ghcr.io/iantriggs/fedian:dev-signing
```

And reboot again:

```bash
systemctl reboot
```
