# TRACKER - mirage-wifi-site (vetrina)

Tracciamento task del sito. Formato:
`- [ ] TODO/BUG: descrizione (data)` -> `- [x] FATTO: descrizione (data)`.

## Sessione 2026-11-08 - resa mobile + pagina installazione (branch feat/mobile-install)

- [x] FATTO: header mobile a scomparsa (hamburger) + scala titolo eroe su piccoli
  schermi (2026-11-08). VERIFICATO_EMPIRICO a viewport Android (412x915, IT):
  header 164px -> 69px, toggle apre/chiude/Escape, fallback no-JS tutto visibile,
  desktop 1280 identico prima/dopo. Impl Fable, verifica coordinatore.
- [x] FATTO: pagina install.html (quickstart) multilingue 5 lingue + wiring
  (voce nav "Installa", link eroe "Come si installa", sitemap) (2026-11-08).
  VERIFICATO_EMPIRICO: cambio lingua aggiorna titolo pagina (install._title) e
  contenuto in it/en/es/fr/de (parita' 189 chiavi), no overflow mobile, header
  hamburger ok, download -> /l/wzquev. Impl Fable, verifica coordinatore.
- [ ] TODO: QA mobile generale - sweep index + 10 moduli + install.html; include
  lo scanner dell'eroe clippato/tagliato su schermo stretto (2026-11-08)

## Note
- Push/merge su main restano gated all'operatore (branch di lavoro: feat/mobile-install).
- Download Free reale: https://miragewifi.gumroad.com/l/wzquev (cta.free nel sito).
