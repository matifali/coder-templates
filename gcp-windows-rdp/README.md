---
name: WIndows VM on GCP with web RDP
description: Run workspaces as Windows VMs on GCP with easy RDP access from the browser
tags: [gcp, windows, rdp]
icon: /icon/windows.svg
---

# Coder GCP Windows VM Template

This template provisions a Windows VM on GCP with easy RDP access from the browser.

## Prerequisites

- Google Cloud Platform account and project already setup.
- Coder host should have the google cloud auth credentials setup. See [here](https://cloud.google.com/docs/authentication/getting-started) for more details.

## Getting started

1. Clone the template repository.

   ```bash
   git clone https://github.com/matifali/gcp-windows-rdp.git
   ```

2. Create the new template by running:

   ```bash
   cd gcp-windows-rdp
   coder templates create gcp-windows-rdp \
   --variable project_id=<your-gcp-project-id>
   ```

3. Navigate to the Coder dashboard and create a new workspace using the template.

## Notes

- The first time you run the template, it will take a few minutes to create the VM and install the necessary software. subsequent runs will be much faster.
