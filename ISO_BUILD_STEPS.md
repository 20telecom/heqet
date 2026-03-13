# Building the Heqet ISO in GitHub Codespaces

A quickstart guide for building the Heqet ISO using GitHub Codespaces. For full technical details, build customisation, deployment options, and troubleshooting, see [ISO_BUILD.md](ISO_BUILD.md).

---

## 1. Fork and Create the Codespace

1. Go to https://github.com/20telecom/heqet and click **Fork** to create a copy under your own GitHub account.
2. On your fork, click the green **Code** button, select the **Codespaces** tab, and click **Create codespace on main** (or your desired branch).
3. Wait for the environment to load (1-2 minutes).

Verify you are in the right place:

```bash
pwd
# /workspaces/heqet
```

---

## 2. Remove the Yarn Repository

The Codespaces base image includes a Yarn APT repository with an expired GPG key. This causes `apt-get update` to fail during the build. Remove it first:

```bash
sudo rm /etc/apt/sources.list.d/yarn.list 2>/dev/null; sudo rm /etc/apt/sources.list.d/yarn.sources 2>/dev/null
```

---

## 3. Build the ISO

Run from the repository root:

```bash
sudo bash iso-build/scripts/build-iso.sh 1-3-2
```

Replace `1-3-2` with your desired version string.

The build script handles everything: installs dependencies, downloads the Debian 12.13.0 netinst ISO (~686MB, skipped if cached), extracts it using bsdtar, injects preseed.cfg, heqet-gate.sh, and IN1CLICK, configures the boot loaders, generates the hybrid ISO, validates the output, and cleans up the extraction directory.

Build time is under 1 minute if the Debian ISO is cached, or under 2 minutes including the download.

---

## 4. Verify the Build

The build ends with a summary:

```
╔═══════════════════════════════════════════════════════════════╗
║           You can download and use heqet_1-3-2.iso            ║
╚═══════════════════════════════════════════════════════════════╝

Build Summary:
Custom ISO: /workspaces/heqet/iso-build/output/heqet_1-3-2.iso
File size: 686M
```

Verify the checksum:

```bash
cd iso-build/output
sha256sum -c heqet_1-3-2.iso.sha256
```

Expected output: `heqet_1-3-2.iso: OK`

---

## 5. Download the ISO

In the VS Code sidebar, navigate to `iso-build/output/`, right-click `heqet_1-3-2.iso`, and select **Download**.

Also download the `.sha256` file so you can verify the download on your local machine.

---

## 6. Clean Up

The build script removes the extraction directory automatically after a successful build. The only large file left in `build/` is the cached Debian ISO (~686MB), which is reused on future builds.

To remove the cached Debian ISO and free that space:

```bash
cd iso-build
sudo rm -rf build/*
```

---

## 7. Next Steps

- Test the ISO in a VM or on hardware. See [ISO_BUILD.md](ISO_BUILD.md) for testing instructions.
- The Heqet gate generates a random root password at install time. There are no default credentials.
- For build customisation, preseed details, troubleshooting, and deployment guidance, see [ISO_BUILD.md](ISO_BUILD.md).

---

**Last Updated:** 13th March 2026
