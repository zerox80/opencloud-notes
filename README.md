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

The simplest deployment model is to build the app outside the server and copy the resulting `dist/` folder into your OpenCloud apps directory as `notes/`.

Typical flow with `opencloud-compose`:

1. Build this repository locally or in CI.
2. Copy the built files to your host app directory, for example into `${OC_APPS_DIR}/notes`.
3. Restart OpenCloud with your normal Docker Compose flow.

That keeps server operations limited to the same `docker compose pull`, `docker compose down` and `docker compose up -d` pattern you already use.

## Releases

The included GitHub workflows run type checks, unit tests and build validation on pushes and pull requests. Tagging a version like `v0.1.0` creates a GitHub release with a ready-to-deploy zip that contains the app under a top-level `notes/` directory.

## Container image

A minimal `Dockerfile` is included so the built extension can also be shipped as a static image later if you decide to mount or copy app assets through a Compose overlay.
