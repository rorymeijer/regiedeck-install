# Regiedeck — Promo

Een korte promovideo (±37 s, 1080p) die Regiedeck in beeld brengt: van intro en
"waarom" tot een live-ogend dashboard, de belangrijkste onderdelen, beveiliging,
rollen en een afsluiter. Volledig in de huisstijl (navy sidebar, blauw/sky-accent,
RAG-kleuren) en met echte productteksten.

## Bestanden

| Bestand | Wat |
|---------|-----|
| `regiedeck-promo.mp4` | De gerenderde video (H.264, 1920×1080, 30 fps) |
| `regiedeck-promo.html` | De bron: één zelfstandige, geanimeerde HTML-reel |
| `record.mjs` | Playwright-script dat de HTML afspeelt en opneemt |

## De HTML bekijken

Open `regiedeck-promo.html` in een browser — de animatie speelt automatisch af
(±41 s tijdlijn). Handig om teksten of scènes aan te passen.

## Opnieuw renderen

Na een aanpassing aan de HTML de video opnieuw opnemen en transcoderen:

```bash
# 1) Opnemen met Playwright (Chromium) -> video/*.webm
node record.mjs

# 2) Transcoderen naar mp4 (H.264). Elke volledige ffmpeg werkt:
ffmpeg -y -i video/*.webm -movflags +faststart -pix_fmt yuv420p \
  -c:v libx264 -crf 20 -preset medium -r 30 regiedeck-promo.mp4
```

De opname draait realtime; de HTML zet `window.__promoDone = true` als de
tijdlijn klaar is, waarna `record.mjs` de opname netjes afsluit.

## Scènes

1. **Intro** — logo + tagline "Eén dashboard voor de volledige regie op je IV-portfolio"
2. **Waarom** — verspreide spreadsheets/mailtjes die samenkomen op één plek
3. **Dashboard** — een live-ogend Portfolio Dashboard met tellende KPI's
4. **Onderdelen** — risico's, besluiten, kanban, roadmap, budgetten, stakeholders, brainstorm, rapportages
5. **Beveiliging** — Argon2id, passkeys/2FA, SSO (Entra ID), CSRF/CSP, prepared statements, auditlog
6. **Rollen** — MT · IV Manager · Projecteigenaar · Projectlid · Beheerder
7. **Afsluiter** — "Alles wat je nodig hebt om regie te voeren. Op één plek."
