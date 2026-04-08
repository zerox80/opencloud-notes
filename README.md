# OpenCloud Notes

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![OpenCloud Awesome](https://img.shields.io/badge/Awesome-OpenCloud_Apps-fc5185.svg)](https://github.com/opencloud-eu/awesome-apps)

Modern, file-native notes for OpenCloud. 

This repository contains a standalone OpenCloud web extension that turns `.ocnb` notebooks and Markdown pages into a focused, distraction-free notes workspace. It is built to integrate natively into the OpenCloud Web app and operates entirely on your existing OpenCloud files—no separate proprietary database needed!

> 📖 **Check out our full architecture and deployment guide in [documentation.md](documentation.md)**.

## ✨ Features

- **Standard formats:** Treats each notebook as a standard `.ocnb` folder.
- **Markdown-native:** Stores each page as a plain `.md` file, preventing vendor lock-in.
- **Seamless integration:** Loads directly into OpenCloud Web as an external, natively-integrated app.
- **Simple hosting:** Keeps deployment predictable because the server only serves static app assets without a dedicated Node.js backend.

## Development

Requirements:
- Node.js 22+
- pnpm 10+

Install and validate:

```bash
pnpm install
pnpm validate
```

Build only:

```bash
pnpm build
```

The production bundle is written to `dist/`.

## Deploy to OpenCloud

The recommended deployment model is to build the app directly on the Linux host that runs `opencloud-compose`, then copy the generated `dist/` files into the OpenCloud apps directory with regular local filesystem commands.

Typical server-side flow:

```bash
git clone https://github.com/zerox80/opencloud-notes.git
cd opencloud-notes
corepack pnpm install
corepack pnpm build

mkdir -p /path/to/opencloud-compose/config/opencloud/apps/notes
cp -r dist/. /path/to/opencloud-compose/config/opencloud/apps/notes/
```

Then restart OpenCloud from your `opencloud-compose` checkout:

```bash
cd /path/to/opencloud-compose
docker compose down
docker compose up -d
```

This keeps the complete deployment on the server itself and matches the way OpenCloud expects external apps to be served as static assets from `notes/`.

## Releases

The included GitHub workflows run type checks, unit tests and build validation on pushes and pull requests. Tagging a version like `v0.1.0` creates a GitHub release with a ready-to-deploy zip. If you use a release artifact, unpack it on the Linux server and copy the extracted app files into your OpenCloud apps directory with `cp`.

## Container image

A minimal `Dockerfile` is included so the built extension can also be shipped as a static image later if you decide to mount or copy app assets through a Compose overlay.

## 📄 License

This software is released under the **[GNU Affero General Public License v3.0 (AGPL-3.0)](https://www.gnu.org/licenses/agpl-3.0)**. 
Please refer to the `LICENSE` file for more details.

---
_Built for the OpenCloud web ecosystem. Explore more awesome applications at [opencloud-eu/awesome-apps](https://github.com/opencloud-eu/awesome-apps)._
