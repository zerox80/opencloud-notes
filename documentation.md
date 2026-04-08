# OpenCloud Notes - Architecture and Deployment Guide

This document explains what OpenCloud Notes is, how its data model works, how the frontend is structured, and how to deploy it on a Linux server, especially when you run OpenCloud with Docker Compose.

---

## Table of contents
1. [Core idea: what is OpenCloud Notes?](#1-core-idea-what-is-opencloud-notes)
2. [Data model: how notes are stored](#2-data-model-how-notes-are-stored)
3. [Technical architecture](#3-technical-architecture)
4. [Deployment paths](#4-deployment-paths)
   - [Method A: build on the Linux server and copy `dist/` locally](#method-a-build-on-the-linux-server-and-copy-dist-locally)
   - [Method B: container image and reverse proxy](#method-b-container-image-and-reverse-proxy)
5. [CI/CD and releases](#5-cicd-and-releases)
6. [Local development](#6-local-development)

---

## 1. Core idea: what is OpenCloud Notes?

OpenCloud Notes is a web extension for OpenCloud. The goal is to provide a clean, focused workspace for notes without requiring a separate proprietary database or backend service.

Instead of storing notes in a custom database, OpenCloud Notes uses the existing OpenCloud file structure. The app is a frontend interface that works on top of files already stored in OpenCloud.

Benefits of this approach:
- Backups stay simple because notes live inside normal OpenCloud storage.
- Sharing stays simple because notebooks are just folders that can be shared like any other resource.
- Versioning stays simple because deletion and overwrite behavior follows the normal OpenCloud recycle bin and file versioning mechanisms.

## 2. Data model: how notes are stored

The app uses standard file formats to avoid vendor lock-in.

- Notebooks: a notebook is a normal folder whose name ends with `.ocnb`, for example `Project Planning.ocnb`.
- Pages: every note inside a notebook is a plain Markdown file such as `Meeting Notes.md`.
- Structure: notebooks can contain nested folders and additional Markdown files, and the app renders that tree as the navigation panel.

If you mount OpenCloud over WebDAV on your workstation, the notebooks look like normal folders containing text files, and those files can still be edited with standard tools.

## 3. Technical architecture

OpenCloud Notes follows the modern OpenCloud web extension model.

- Frameworks: Vue 3, TypeScript, and Vite.
- Runtime integration: OpenCloud Web loads the extension dynamically at runtime.
- No iframe: the notes UI becomes part of the OpenCloud web interface and shares routing, design system pieces, and API clients with the rest of the application.
- Standalone repository: this project extracts the notes extension from the larger `web-extensions` monorepo so it can be built, released, and deployed independently.
- APIs: the app uses OpenCloud APIs such as WebDAV for file operations and SSE for live updates when notebook contents change.

## 4. Deployment paths

Because the app is a static frontend bundle, the server does not run a dedicated Notes backend process. OpenCloud only needs to serve the compiled HTML, JavaScript, and CSS files.

There are two practical deployment patterns.

### Method A: build on the Linux server and copy `dist/` locally

This is the recommended path for a typical `opencloud-compose` installation.

The idea is simple: clone this repository on the Linux server, build the extension there, and copy the generated `dist/` files into the external apps directory with `cp`.

Step by step:

1. Clone the repository on the Linux host that runs OpenCloud:

   ```bash
   git clone https://github.com/zerox80/opencloud-notes.git
   cd opencloud-notes
   ```

2. Install dependencies and build the extension:

   ```bash
   corepack pnpm install
   corepack pnpm build
   ```

   Result: Vite writes the production bundle to `dist/`.

3. Copy the built files into the OpenCloud apps directory. In a standard `opencloud-compose` checkout this is commonly under `./config/opencloud/apps`:

   ```bash
   export OC_APPS_DIR=/path/to/opencloud-compose/config/opencloud/apps
   mkdir -p "${OC_APPS_DIR}/notes"
   cp -r dist/. "${OC_APPS_DIR}/notes/"
   ```

4. Restart OpenCloud from the Compose project directory:

   ```bash
   cd /path/to/opencloud-compose
   docker compose down
   docker compose up -d
   ```

Why this is recommended:
- The entire workflow stays on the Linux server.
- The deployment uses normal local filesystem operations such as `cp`.
- OpenCloud can serve the app directly from `notes/` without another service in between.

### Method B: container image and reverse proxy

For larger or more opinionated environments, you can also ship the built assets inside a container image.

This repository includes a `Dockerfile` that packages the app assets into a minimal image layout. That approach can fit environments where every deployable unit is managed as an image instead of a copied volume.

The tradeoff is that OpenCloud Compose then needs additional wiring:
- a container that serves the static app files,
- reverse proxy or internal routing for that container,
- OpenCloud configuration that points to the app at its internal HTTP location.

For most self-hosted Compose setups, Method A is simpler, easier to debug, and easier to maintain.

## 5. CI/CD and releases

The repository already includes automated validation and release support.

- Build and test: pushes and pull requests run type checks, unit tests, and build validation.
- Release artifacts: tagging a version creates a release archive that can be unpacked on the Linux server.

If you use a release archive instead of building from a Git checkout, keep the final deployment step the same: unpack the archive on the server and copy the extracted app files into the OpenCloud apps directory with `cp`.

## 6. Local development

For code changes and UI work:

1. Clone the repository.
2. Use Node.js 22 or newer.
3. Install dependencies with `corepack pnpm install`.
4. Run `corepack pnpm validate` before pushing changes.

Useful locations in the repository:
- `src/components/` contains the main Vue UI building blocks.
- `src/composables/` contains reusable state and action logic.
- `tests/unit/` contains the unit tests.

## Summary

1. OpenCloud Notes stores notebooks as `.ocnb` folders and pages as Markdown files.
2. The app is a static frontend extension, not a separate backend service.
3. The recommended deployment flow is: build on the Linux server, copy `dist/` into `config/opencloud/apps/notes` with `cp`, then restart OpenCloud.
4. The project is independent from the larger monorepo and already includes automated validation and release support.