# shiny-gallery project memory

## Project purpose
Shiny app that serves as a home-page gallery for all Shiny apps on a Linux server at /srv/shiny.

## Key files
- `app.R` — main Shiny gallery app (reads /srv/shiny, auto-refreshes every 60s)
- `www/styles.css` — MEDS-inspired design (teal #047C90, dark blue #003660, green #78A540; Sanchez headings, Nunito body)
- `shiny-gallery.qmd` — documentation only (not rendered as website)

## Design system
Matches https://github.com/UCSB-MEDS/EDS-website-template/blob/main/meds-website-styles.scss
- Colors: teal #047C90, dark-blue #003660, green #78A540, off-white #F7F7F7, baby-blue #d2e3f3
- Fonts: Sanchez (headings), Nunito (body, wt 300/800), Roboto Mono (tags/code)
- Button: teal outline, transparent bg; hover turns green border+text

## App discovery logic
Scans SHINY_BASE_DIR (/srv/shiny) for subdirs containing app.R or server.R, excluding the gallery itself.

## Per-app metadata
Each app can have app-info.yml with: title, description, icon (FA6 name), tags (list)

## Environment variables
- SHINY_BASE_DIR (default /srv/shiny)
- SHINY_BASE_URL (default /)

## Deployment
Clone into /srv/shiny/gallery, configure Shiny Server to serve it at root.
