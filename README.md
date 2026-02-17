
# 🦊 OrangeFox Android 14 Auto Builder  
### LG V30 H930DS (codename: joan)

Automated build system for compiling **OrangeFox Recovery (fox_14.1)**  
on **Android 14 (LineageOS 21 base)** for the LG V30 H930DS.

---

# ⚡ One-Line Installer (Windows)

Run in **PowerShell as Administrator**:

```powershell
irm https://raw.githubusercontent.com/AirysDark/OrangeFox-A14-LG-H930DS-AutoBuilder/main/bootstrap.ps1 | iex
The installer will:
Detect admin permissions
Enable WSL + required Windows features
Install Ubuntu automatically (if missing)
Configure WSL memory
Check disk space
Offer local or cloud build options
Launch build automatically
🧠 Build Modes
🖥 1️⃣ Local WSL Build
Builds recovery locally inside WSL.
Requirements:
Windows 10/11
WSL2
Ubuntu installed (auto-installed if missing)
120GB free disk space
6GB+ RAM allocated to WSL
1–3 hour build time
Output:
Copy code

~/android14/out/target/product/joan/
Artifacts generated:
OrangeFox-joan-<version>.zip
OrangeFox-joan-<version>.zip.sha256
build.log
☁ 2️⃣ Cloud GitHub Build
Triggers GitHub Actions workflow.
Features:
Ubuntu 22.04 build environment
Repo caching
ccache acceleration
Auto artifact upload
Auto GitHub Release creation
SHA256 checksum generation
After triggering:
Visit Actions tab
Download artifact from workflow
Or download from generated Release
📦 What This Project Automates
✔ LineageOS 21 base sync
✔ OrangeFox fox_14.1 injection
✔ LG V30 device tree integration
✔ Kernel + vendor integration
✔ Deterministic version naming
✔ Artifact packaging
✔ SHA256 checksum generation
✔ GitHub release publishing
✔ Resume-safe repo sync
✔ Logging
🧰 Repository Structure
Copy code

bootstrap.ps1
scripts/
  ├── build_orangefox_a14.sh
  └── setup_orangefox_a14.ps1
.github/workflows/build.yml
Dockerfile (optional reproducible builds)
🔧 Customization
To modify build behavior:
Change device:
Edit in:
Copy code

scripts/build_orangefox_a14.sh
Change Android branch:
Modify:
Copy code

repo init -b lineage-21.0
Change OrangeFox branch:
Modify:
Copy code

git clone -b fox_14.1
Change CI behavior:
Edit:
Copy code

.github/workflows/build.yml
🔐 Security & Safety
This repository:
Does NOT distribute prebuilt binaries
Does NOT include proprietary vendor blobs
Is intended for development and personal use
Flashing custom recovery can brick your device.
Proceed at your own risk.
📊 CI/CD Features
GitHub Actions automation
Repo metadata caching
ccache acceleration
Automatic release creation
Artifact signing-ready
Deterministic version tagging
🏁 Target Device
Device: LG V30 H930DS
Codename: joan
Chipset: Snapdragon 835 (msm8998)
Architecture: arm64
🏆 Status
✔ Fully Automated
✔ WSL Provisioning
✔ Cloud Build Enabled
✔ Release Publishing Enabled
✔ Final Boss Mode
💬 Contributions
Pull requests welcome.
Test builds before submitting changes.
Copy code

---

# 🧠 What Changed

Your README now:

- Reflects Elite-level automation
- Explains both build modes
- Shows artifact location
- Explains CI features
- Explains how to modify
- Looks professional
- Looks production-grade

---
