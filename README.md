# opencloud-notes

Modern, file-native notes for OpenCloud.

This repository contains a standalone OpenCloud web extension that turns `.ocnb` notebooks and Markdown pages into a focused notes workspace. It is based on the OpenCloud Notes app pattern, but packaged here as an independent project so you can build, release and deploy it without carrying the full `web-extensions` monorepo.

## What it does

- Treats each notebook as a `.ocnb` folder
- Stores each page as a plain Markdown file
- Loads directly into OpenCloud Web as an external app
- Keeps deployment predictable because the server only serves static app assets

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
