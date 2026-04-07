# OpenCloud Notes – Das ultimative Handbuch

Dieses Dokument erklärt **jedes Detail** der OpenCloud Notes App, warum sie so gebaut ist, wie sie funktioniert und wie genau sie auf einem eigenen Server (insbesondere mit Docker Compose) installiert wird. Es sollen am Ende keine Fragen mehr offen bleiben.

---

## Inhaltsverzeichnis
1. [Die Grundidee: Was ist OpenCloud Notes?](#1-die-grundidee-was-ist-opencloud-notes)
2. [Das Datenmodell: Wie werden Notizen gespeichert?](#2-das-datenmodell-wie-werden-notizen-gespeichert)
3. [Die technische Architektur (Frontend)](#3-die-technische-architektur-frontend)
4. [Deployment-Wege: Wie kommt die App auf den Server?](#4-deployment-wege-wie-kommt-die-app-auf-den-server)
   - [Methode A: Statisches Kopieren (Empfohlen für Compose)](#methode-a-statisches-kopieren-empfohlen-f%C3%BCr-compose)
   - [Methode B: Docker Container & Reverse Proxy](#methode-b-docker-container--reverse-proxy)
5. [CI/CD: GitHub Actions & Releases](#5-cicd-github-actions--releases)
6. [Lokale Entwicklung (Codeänderungen)](#6-lokale-entwicklung-code%C3%A4nderungen)

---

## 1. Die Grundidee: Was ist OpenCloud Notes?
OpenCloud Notes ist eine Web-Applikation (Web Extension) für OpenCloud. Das Ziel ist es, einen aufgeräumten und modernen Workspace für Notizen anzubieten, ohne komplexe proprietäre Datenbanken vorauszusetzen. 

Anstatt einer App, die eine eigene Datenbank (wie MySQL oder MongoDB) für Notizen benötigt, nutzt OpenCloud Notes die **bereits existierende Dateistruktur von OpenCloud**. Das heißt: Die App ist ein reines Frontend-Interface. Alle Daten liegen ganz normal in deinem OpenCloud-Speicher.

**Vorteile dieses Ansatzes:**
- **Sicherheit & Backup:** Wenn du deine OpenCloud sicherst, sicherst du automatisch alle Notizen.
- **Teilen:** Du kannst Notizbücher wie ganz normale Ordner mit anderen Nutzern oder extern per Link teilen.
- **Versionierung:** Wenn du eine Notiz löschst, landet sie im OpenCloud-Papierkorb. Wenn du sie überschreibst, greift die normale Dateiversionierung von OpenCloud.

## 2. Das Datenmodell: Wie werden Notizen gespeichert?
Alles in der App basiert auf Standard-Formaten, um einem "Vendor Lock-in" (der Abhängigkeit von einer speziellen Software) vorzubeugen.

- **Das Notizbuch (`.ocnb`):** Ein Notizbuch ist technisch gesehen einfach nur ein ganz normaler Ordner auf deiner Festplatte bzw. in deiner Cloud. Der einzige Unterschied ist, dass der Ordnername auf `.ocnb` (OpenCloud NoteBook) endet, z. B. `Projektplanung.ocnb`.
- **Die Seiten (`.md`):** Jede einzelne Notiz in diesem Notizbuch ist eine einfache Markdown-Datei (z. B. `Meeting.md`). 
- **Struktur:** Du kannst in einem Notizbuch Unterordner anlegen, in die du wieder Markdown-Dateien legst. Die App liest diesen Baum aus und stellt ihn links als Navigationsoberfläche dar.

Wenn du OpenCloud über WebDAV an deinen PC anbindest (z. B. über den Dateiexplorer), siehst du einfach Ordner mit Textdateien. Du könntest sie sogar dort editieren.

## 3. Die technische Architektur (Frontend)
Früher waren Erweiterungen für Clouds oft PHP-Backends oder iframes. OpenCloud geht einen modernen Weg:
- **Frameworks:** Vue 3, TypeScript und Vite.
- **Module Federation:** Die OpenCloud Web Oberfläche (das "Hauptprogramm", was du im Browser siehst) lädt die Notes-Extension *dynamisch* zur Laufzeit hinzu. 
- Das bedeutet: Es gibt keinen iframe! Die Notes-App wird direkt Bestandteil der OpenCloud-Oberfläche. Sie teilt sich das Design, die Routing-Logik und die API-Clients mit dem Rest von OpenCloud.
- **Standalone Repo:** Ursprünglich war die App tief in einem großen OpenCloud Monorepo (`web-extensions`) versteckt. Dieses Repository (`opencloud-notes`) hat die App herausgelöst. Dadurch kannst du selbstständig bauen, versionieren und publizieren, ohne das riesige Haupt-Repository kompilieren zu müssen.
- **WebDAV & SSE:** Die App kommuniziert ausschließlich über die Standard-APIs von OpenCloud (WebDAV für Dateikreation, SSE/Server-Sent Events, damit die Liste der Notizen in Echtzeit aktualisiert wird, wenn ein anderer Nutzer etwas hinzufügt).

## 4. Deployment-Wege: Wie kommt die App auf den Server?
Weil die App ein "reines Frontend" ist, läuft auf dem Server **kein eigener Notes-Prozess** (wie ein Node.js-Server). Es müssen lediglich die fertigen, kompilierten HTML/JS/CSS-Dateien vom OpenCloud-Webserver an deinen Browser ausgeliefert werden.

Es gibt dafür zwei primäre Wege:

### Methode A: Statisches Kopieren (Empfohlen für Compose)
Dies ist der einfachste und fehlerärmste Weg, insbesondere wenn du das reguläre `opencloud-compose` Setup nutzt. 

**Das Prinzip:** Die Dateien der App werden auf deinem lokalen Rechner oder über GitHub Actions gebaut. Das Ergebnis (der Ordner `dist/`) wird einfach in das Apps-Verzeichnis des OpenCloud-Servers kopiert. OpenCloud Web scannt diesen Ordner beim Start und lädt die App (`manifest.json`) selbstständig.

**Schritt-für-Schritt:**
1. **Lokal bauen:**
   In deinem Repository auf deinem PC oder Laptop ausführst du:
   ```bash
   corepack pnpm install
   corepack pnpm build
   ```
   Ergebnis: Ein Ordner namens `dist/` taucht auf.
2. **Upload auf den Server:**
   Der Ordner `dist/` muss auf deinen Server. Im `opencloud-compose` Setup gibt es standardmäßig ein Volume-Verzeichnis für externe Apps. Meistens liegt es unter `./config/opencloud/apps`.
   Lege dort einen Ordner `notes` an und kopiere den Inhalt von `dist` hinein:
   ```bash
   scp -r dist/* user@dein-server:/pfad/zu/opencloud-compose/config/opencloud/apps/notes/
   ```
3. **OpenCloud neu starten:**
   Gehe auf deinem Server in den Ordner `opencloud-compose` und führe aus:
   ```bash
   docker compose down
   docker compose up -d
   ```
**Warum das gut ist:** Du brauchst keinen extra Webserver oder Docker-Container nur für Notizen. OpenCloud kümmert sich um alles.

### Methode B: Docker Container & Reverse Proxy
Wenn du in massiven, hochskalierbaren Umgebungen (Kubernetes o. ä.) arbeitest, vermeidet man das Kopieren von Dateien in Volumes ("State"). Stattdessen nutzt man Docker-Images.

**Das Prinzip:** Im Repository liegt ein `Dockerfile`. Dieser baut ein Docker-Image, welches einen winzigen Nginx-Webserver enthält, der nur die fertigen `dist/`-Dateien ausliefert.

**Der Haken bei OpenCloud Compose:** OpenCloud erwartet externe Apps via HTTP. Wenn du Methode B nutzt, musst du diesen neuen Docker-Container in deine `docker-compose.yml` einbinden und mit Labels für den Traefik-Reverse-Proxy versehen. Dann muss der OpenCloud Web-Container über eine Umgebungsvariable so konfiguriert werden, dass er die App unter der neuen internen URL (z.B. `http://notes-app/`) findet. 
*Aus diesem Grund ist für 95% der Nutzer Methode A wesentlich eleganter.*

## 5. CI/CD: GitHub Actions & Releases
Dieses Repository ist komplett automatisiert:
- **Build & Test (`ci.yml`):** Bei jedem Push auf `main` wird in den GitHub Actions automatisch `pnpm install`, `vue-tsc` (Typenprüfung), `vitest` (Security/Logic/Unit-Tests) und `vite build` ausgeführt. So merkst du sofort, wenn du unabsichtlich etwas kaputt gemacht hast.
- **Release-Automatisierung (`release.yml`):** Wenn du in GitHub einen neuen Tag erstellst (z. B. `v1.0.0`), bauen die GitHub Actions das Projekt automatisch und generieren ein ZIP-Archiv.
  **Dein Nutzen:** Wenn dir das lokale Bauen (`pnpm build`) zu nervig ist, kannst du in GitHub ein Release erstellen, das fertige `notes-v1.0.0.zip` herunterladen, auf dem Server entpacken und in deinen `config/opencloud/apps/notes` Ordner schieben.

## 6. Lokale Entwicklung (Codeänderungen)
Wenn du das Layout oder die Logik der Notizen ändern willst:
1. Klonen: `git clone https://github.com/zerox80/opencloud-notes.git`
2. Installieren: Node 22 verwenden und `corepack pnpm install` ausführen.
3. Komponenten: Unter `src/components/` findest du alle Bausteine (Sidebar, Empty States).
4. Code-Prüfung: Bevor du pusht, führe `corepack pnpm validate` aus. Das checkt, ob dein Code die OpenCloud-Standards nicht verletzt.

## Zusammenfassung
1. **Kein extra Datenbank-Setup** auf dem Server.
2. **Kein eigenes Backend**, alles sind `.ocnb`-Ordner und Markdown-Dateien.
3. **Deployment leicht gemacht:** Lokal bauen (`dist/`), auf den Server hochladen (`config/opencloud/apps/notes`), Docker Compose neustarten. Fertig.
4. **Zukunftssicher:** Unabhängig vom großen Monorepo, automatische Checks per GitHub Actions.