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

## Sessione 2026-11-08 - perf scroll mobile (branch perf/mobile-rendering)

- [x] FATTO (impl): alleggerire il rendering per scroll fluido su smartphone di
  fascia bassa (2026-11-08). 3 interventi: (1) niente backdrop-filter su mobile
  (header/menu, sfondo opaco 97%, desktop conserva il blur); (2)
  content-visibility:auto su sezioni below-fold (#edizioni/#perche/#faq/.final
  universale; #moduli SOLO mobile perche' su desktop e' scrollytelling pinnato
  500vh); (3) pausa animazioni scanner eroe offscreen (IntersectionObserver).
  VERIFICATO_EMPIRICO desktop: blur header conservato, #moduli intatto
  (content-visibility assente), ancora #edizioni a y=84 e sezione renderizzata,
  scroll-reveal opacity ~1. Mobile VERIFICATO_MOCK (media query + IO corretti).
- [x] FATTO: CAUSA RADICE della jank su fascia bassa trovata e corretta
  (2026-11-08). Diagnosi on-device A/B via server LAN (headless locale non misura
  lo scroll mobile: niente vsync): animazioni OFF scattava ancora, floor CSS
  scattava peggio, no-JS era liscio -> il colpevole era un loop JS continuo. Era
  `startParticles()` chiamato nel ramo mobile della net-section: avviava un rAF
  `drawParticles` (canvas 2D + shadowBlur + compositing "lighter" a ogni frame)
  anche se #particles e' display:none sotto i 760px. Fix: gating su
  `if (!mobileMQ.matches) startParticles()` (desktop/tablet invariati). Impl Fable.
  VERIFICATO_EMPIRICO on-device dall'operatore (Realme fascia bassa: scroll liscio;
  fascia alta gia' ok). Metodo riusabile: A/B on-device via LAN http.server.

## Sessione 2026-11-08 - nav laptop (branch ui/nav-laptop-lang-compact)

- [x] FATTO: nav laptop - lingua raccolta nel dropdown compatto nel range
  761-1200px (2026-11-08, richiesta operatore). La nav si affollava sui laptop
  (CTA "Accesso anticipato" tagliata, "Moduli Pro" a capo): le 5 bandiere inline
  occupavano troppo. Ora <=1200px la lingua diventa il toggle compatto "IT v"
  (stesso dropdown di mobile) tenendo la nav orizzontale; hamburger solo <=760,
  bandiere inline >1200 (desktop pieno invariato). Disaccoppiato il blocco
  media-query lang-compatto (<=1200) dall'hamburger (<=760). VERIFICATO_EMPIRICO
  a 800/960/1024/1100/1200/1280: niente clip/wrap (overflow 800px = 4px
  irrilevante), dropdown apre/cambia lingua a 1024. Solo css/site.css. Impl Fable.

## Sessione 2026-11-22 - i18n pagine dettaglio moduli

- [x] FIXED: le pagine di dettaglio dei moduli (modules/01..10) restavano in
  inglese a prescindere dalla lingua scelta sulla home (2026-11-22, segnalazione
  operatore). CAUSA: le pagine avevano gli attributi `data-i18n` con chiavi
  `mod.*` ma (a) non caricavano i18n.js ne' avevano la logica di apply, (b) le
  chiavi `mod.*` non esistevano in i18n.js. FIX: aggiunte 96 chiavi `mod.*` per
  lingua x5 (en/it/es/fr/de, parita' verificata, node -c OK), coerenti con le
  card `ars.c*`; aggiunto a ogni pagina modulo `<script src="../i18n.js">` + loader
  inline che legge localStorage("lang") e applica le traduzioni + aggiorna
  document.title dal titolo tradotto. Ristrutturato il link "Back" (freccia in
  span separato) perche' textContent non cancelli la freccia. VERIFICATO: parita'
  chiavi 5 lingue, tutte le chiavi di pagina presenti in en, campioni it/fr/de/es
  corretti. VERIFICATO_EMPIRICO (Chromium headless, localStorage lang preimpostato):
  reso corretto in it/es/fr/de su moduli 01/07/03/08, freccia Back preservata, title
  e html lang aggiornati; confermato anche sul sito live con profilo pulito.

- [x] FIXED: meta description delle pagine modulo tradotta nelle 5 lingue
  (2026-11-22, richiesta operatore). Aggiunte 50 chiavi `mod.<modulo>._description`
  (10x5, valore identico a `.desc`, convenzione come `install._description`);
  aggiunto `data-i18n-meta="mod.<modulo>._description"` sul tag meta e logica nel
  loader per applicarla. VERIFICATO_EMPIRICO (Chromium headless): meta description
  DE resa tradotta su modulo 02. Nota: la verifica i18n del contenuto visibile era
  fallita lato operatore solo per cache browser (sito live gia' corretto, confermato
  con profilo pulito it-IT -> reso in italiano); risolto con hard-refresh.

- [x] FATTO: cache-busting su i18n.js per evitare che la cache browser serva un
  dizionario vecchio dopo ogni aggiornamento (2026-11-22). Aggiunto `?v=<versione>`
  a tutti i 12 riferimenti (index, install, 10 moduli). Versione corrente:
  **`?v=20261122b`** (commit 5cd8a08). REGOLA: a ogni modifica di i18n.js bumpare
  la versione in tutti i riferimenti, es.
  `grep -rl 'i18n.js?v=' --include=*.html . | xargs sed -i 's/i18n\.js?v=[0-9a-z]*/i18n.js?v=NUOVA/g'`
  (stesso giorno -> suffisso lettera: 20261122b, c, ...). VERIFICATO_EMPIRICO:
  build Pages `built 5cd8a08`, riferimenti live a `?v=20261122b`, i18n.js live
  HTTP 200, render reale modulo 04 in IT sul sito live tutto tradotto.

## Note
- Push/merge su main: autorizzati dall'operatore in questa sessione. Lavoro
  mobile+install+perf+nav tutto su main.
- Download Free reale: https://miragewifi.gumroad.com/l/wzquev (cta.free nel sito).
