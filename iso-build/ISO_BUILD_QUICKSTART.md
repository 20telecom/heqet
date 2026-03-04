# ISO Build Quick Start (Build Hosts Only)
This guide is only for generating a new Heqet ISO. For installation, use the main README.
## Quick Start (Generate ISO)
```bash
sudo bash iso-build/scripts/build-iso.sh 1-2-0
```
You can build a new ISO by running:
```bash
sudo bash iso-build/scripts/build-iso.sh [VERSION_NUMBER]
```
Replace [VERSION_NUMBER] with a version you want to build (e.g. 1-2-0).
Output:
- ISO: `iso-build/output/heqet_1-2-0.iso`
- Checksums: `.sha256` and `.md5` in the same folder
## Notes
- Edit only files in `iso-build/config/` (preseed, gate, isolinux)
- `iso-build/build/` is temporary and cleaned after a build
## More Detail
See [ISO_BUILD.md](../ISO_BUILD.md) for prerequisites, testing, and troubleshooting.
