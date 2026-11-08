# TRACKER - mirage-wifi-site (vetrina)

Tracciamento task del sito. Formato:
`- [ ] TODO/BUG: descrizione (data)` -> `- [x] FATTO: descrizione (data)`.

## Sessione 2026-11-08 - resa mobile + pagina installazione (branch feat/mobile-install)

- [x] FATTO: header mobile a scomparsa (hamburger) + scala titolo eroe su piccoli
  schermi (2026-11-08). VERIFICATO_EMPIRICO a viewport Android (412x915, IT):
  header 164px -> 69px, toggle apre/chiude/Escape, fallback no-JS tutto visibile,
  desktop 1280 identico prima/dopo. Impl Fable, verifica coordinatore.
- [x] FATTO: menu lingua dedicato (dropdown) nella barra mobile, fuori
  dall'hamburger (2026-11-08, richiesta utente). VERIFICATO_EMPIRICO: toggle
  bandiera+codice+chevron, dropdown 5 lingue apre/chiude, scelta aggiorna
  indicatore e titolo, Escape/click-fuori, no overflow fino a 360px, desktop
  identico (bandiere inline), indipendente dall'hamburger. index.html+install.html.
- [x] FATTO: pagina install.html (quickstart) multilingue 5 lingue + wiring
  (voce nav "Installa", link eroe "Come si installa", sitemap) (2026-11-08).
  VERIFICATO_EMPIRICO: cambio lingua aggiorna titolo pagina (install._title) e
  contenuto in it/en/es/fr/de (parita' 189 chiavi), no overflow mobile, header
  hamburger ok, download -> /l/wzquev. Impl Fable, verifica coordinatore.
- [x] FATTO: QA mobile generale - sweep index + 10 moduli + install.html
  (2026-11-08). VERIFICATO_EMPIRICO a viewport Android: NESSUN overflow
  orizzontale su alcuna pagina. Scanner eroe = swipeable per design
  (.scan-view overflow-x:auto, 9 colonne raggiungibili, scrollbar accent):
  non e' un bug, nessun fix. Arsenale/spina -> lista card verticale pulita
  su mobile; edizioni Free/Pro -> 1 colonna; navigazione per ancora ok
  (scroll-padding-top:84px sotto header 69px). Nessuna modifica di codice
  necessaria.

## Note
- Push/merge su main restano gated all'operatore (branch di lavoro: feat/mobile-install).
- Download Free reale: https://miragewifi.gumroad.com/l/wzquev (cta.free nel sito).
