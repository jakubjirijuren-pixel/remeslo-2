# ŘEMESLO 2.0

Samostatný systém pro řemeslnou firmu: React, Vite, Supabase a GitHub Pages.

## Vývoj

```bash
npm install
npm run dev
```

## Publikace

GitHub → Settings → Pages → Build and deployment → Source: GitHub Actions.

Web: https://jakubjirijuren-pixel.github.io/remeslo-2/

Backend: Supabase projekt `eyqzyqruxdqxblosnfwz`. SQL schéma: `supabase/migrations/`.

## Stav

Funkční přihlášení, vytvoření pracovního prostoru, dashboard a základní evidence zákazníků, poptávek, nabídek, zakázek, pracovníků, skladu, vozidel a faktur. Ostatní moduly zatím představují připravené obrazovky. Produkční procesy fakturace, oprávnění a audit vyžadují další dopracování.

Pozor: repozitář je veřejný. Frontend obsahuje pouze veřejný publishable klíč Supabase. Přístup k datům chrání databázové RLS.
