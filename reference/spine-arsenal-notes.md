# spine-arsenal.html - note di motion

Prototipo isolato di UNA sezione landing: una spina dorsale verticale (il segnale
Wi-Fi) con 10 card "arsenale" che le GIRANO INTORNO a spirale DISCENDENTE (elica 3D),
rivelate durante lo scroll. Quella davanti e' a fuoco, le altre ruotano sui lati e
dietro la spina. Motore 2.5D vanilla: solo CSS 3D + un piccolo `<canvas>` per le
particelle. Niente WebGL, niente librerie, niente CDN, niente framework. Funziona da
`file://`.

NOTA COPY: le 10 card contengono ora il COPY REALE inserito dall'operatore (console,
cracking GPU, Evil Twin, WPA3 downgrade, WPA-Enterprise, MITM, DoS mirato, report,
AI advisor, catene). Il copy NON va toccato: le modifiche di motion non cambiano il
testo delle card.

GEOMETRIA ELICA (tarata dall'operatore): STEP = 54deg, RISE = 40px, SPAN = 486deg
(= 9*STEP). Con 10 card sono circa 1.5 giri, gap ampio tra vicini per non affollare.

## Architettura dei tre livelli (progressive enhancement)

Il CSS di base NON assume JS e NON assume motion. Senza JS (o con reduced-motion)
la sezione e' un normale blocco in flusso con le card impilate, dritte, piena
opacita', leggibili. Il JS "sale di livello" aggiungendo una classe al `<section>`:

1. **Statico (default / no JS)**: layout `net-section:not(.js-motion)`. Card in
   colonna centrata, spina nascosta, tutto leggibile. Baseline garantita.
2. **Mobile reveal (`<=760px`, motion ok)**: classe `.reveal`. Card impilate che
   fanno fade + slide-up quando entrano nel viewport (IntersectionObserver). Niente
   elica 3D: degrada a una rivelazione verticale pulita. La spina resta viva
   (archi/nodi/packet in CSS).
3. **Desktop elica (motion ok)**: classe `.js-motion`. Sezione alta 500vh con stage
   `position:sticky; height:100vh`. Lo stage resta inchiodato al centro mentre
   scorri; l'elica gira e porta le card a fuoco in sequenza.

La scelta del percorso avviene una volta al load leggendo due media-query
(`prefers-reduced-motion`, `max-width:760px`).

## L'elica 3D (il cuore della coreografia)

- **perspective**: `1100px` sullo `.stage` (unico contesto prospettico). La
  `.constellation` (spina + elica) e la `.helix` sono `transform-style:preserve-3d`,
  cosi' tutto vive nello stesso spazio 3D e il browser fa z-sorting reale.
- **.helix**: un wrapper a dimensione zero centrato ESATTAMENTE sulla spina
  (`left:50%;top:50%` dentro la costellazione, il cui centro coincide col centro
  della spina). Il JS gli applica `transform: rotateY(var spin)`: e' questo wrapper
  che ruota, trascinando tutte le card.
- **Seat di ogni card** (fisso, non cambia con lo scroll): nel loop la card riceve
  `rotateY(ang) translateZ(R) translateY(rise) scale(S)` con
  - `ang = i * STEP` (STEP = 36deg, passo angolare): le 10 card sono spaziate
    uniformemente, circa un giro completo, quindi NON si impilano e NON si
    sovrappongono mai (l'accavallamento verticale e' impossibile per costruzione).
  - `R = 340` (raggio): dopo `rotateY(ang)`, `translateZ(R)` porta la card frontale
    a world-Z = +R (chiaramente DAVANTI alla spina, ingrandita dalla prospettiva) e
    le card lontane dal fronte oltre la spina (world-Z negativo), rimpicciolite e
    parzialmente occluse = profondita'.
  - `rise = i*RISE - (N-1)/2*RISE` (RISE = 26px, N = numero card = cardEls.length,
    centratura DINAMICA valida per qualsiasi N): da' a ogni card un'altezza diversa,
    cosi' l'anello diventa una SPIRALE DISCENDENTE. Con N=10 la card 01 e' la piu' in
    alto (rise minimo) e la card 10 la piu' in bassa (rise massimo); scorrendo, la
    card a fuoco SCENDE lungo la spina.
- La card e' orientata verso l'esterno: quando il suo angolo mondo e' 0 guarda la
  camera ed e' upright e leggibile; ruotando si mostra di taglio e poi di spalle.

## Mappatura scroll -> spin, e drift

- `progress` 0..1 = quanto si e' scrollato dentro la sezione (da
  `getBoundingClientRect`).
- `spin = -progress * SPAN + idleSpin`, con `SPAN = 324` (= 9*STEP): da progress 0 a
  1 l'elica ruota di 324deg, cioe' porta al fronte in sequenza le card 01..10
  (ognuna upright quando arriva davanti). Scroll = driver principale.
- `idleSpin = (now - start) * IDLE` con `IDLE = 0.004 deg/ms` (~4 deg/s): una
  rotazione IDLE lentissima e continua che tiene l'elica viva anche a pagina ferma
  (come activetheory). Si somma allo spin da scroll, non lo sostituisce.

## Focus, occlusione, leggibilita'

Per ogni card, dall'angolo mondo normalizzato in [-180,180):
- `t = (cos(world)+1)/2` -> 0 (dietro) .. 1 (davanti).
- `scale = 0.80 + 0.20*t`: le card ai lati/dietro rimpiccioliscono (oltre al
  rimpicciolimento prospettico dovuto al translateZ negativo).
- `opacity = 0.10 + 0.90*t^1.6`: la card frontale e' piena, quelle dietro sono
  ghost quasi trasparenti (floor abbassato a 0.10 perche' con 10 card il retro e'
  piu' affollato: cosi' la frontale domina e il testo speculare dietro quasi sparisce).
- **Focus** (`|world| < 18deg`, cioe' mezzo passo angolare del nuovo STEP=36): una
  SOLA card per volta ha bordo + hairline a gradiente + glow (classe `is-focus`),
  dritta e leggibile.
- **Occlusione**: spina (z=0) ed elica condividono lo spazio 3D della costellazione,
  quindi le card con world-Z negativo sono renderizzate DIETRO la spina e dai suoi
  nodi/label dove si sovrappongono. Profondita' reale, non simulata.
- **pointer-events**: solo le card frontali (`t>0.45`) o quella sotto il cursore
  catturano il puntatore; i ghost dietro non rubano l'hover.
- La card a fuoco (o quella hovered) aggiorna il contatore mono `0X / 10` in alto a
  destra e accende un nodo sulla spina. I nodi sulla spina sono 5 ma le card 10:
  la card attiva e' mappata PROPORZIONALMENTE sui nodi con
  `nodeAttivo = round(activeIdx / (N-1) * (nodi-1))`, cosi' il nodo acceso (verde
  phosphor = live) SCENDE lungo la spina man mano che avanzi tra le 10 card.

## Hover / focus da tastiera (swing to front)

Hover del mouse e focus da tastiera settano `c.hovered`. Un valore `c.hv` (0..1)
interpola morbido (`HLERP = 0.18`) verso 1. Con hv che sale, la card viene tirata al
fronte: l'angolo locale `A` interpola da `ang` verso `frontAng = -spin` (cosi'
annulla lo spin del wrapper e la card finisce dritta davanti alla camera, percorso
angolare piu' corto via `norm180`), `translateZ` R -> R+46 (pop in avanti),
`translateY` -> -8 (si solleva), `scale` -> 1.07, `opacity` -> 1, glow intenso
(classe `is-hover`). Rilasciando, `hv` torna a 0 e la card ri-prende il suo seat
sull'elica con la stessa morbidezza (niente snap).

## Parallax cursore

`pointermove` sullo stage salva l'offset del cursore dal centro (-0.5..0.5).
Interpolato (lerp, `LERP = 0.085`) e applicato a TUTTA la costellazione (spina +
elica insieme): pochi px di `translate3d` (22/16) e ~2.2deg di `rotateX/rotateY`, che
si SOMMANO alla perspective. Lo spin dell'elica resta separato (sul wrapper interno),
quindi parallax e rotazione non si disturbano. Su `pointerleave` il target torna a 0.

## Pacchetto effetti stile Active Theory (studiati, non copiati)

Cinque effetti aggiunti in vanilla puro (solo transform/opacity/filter + canvas 2D),
tutti con knob dedicati in cima al blocco JS cosi' sono tarabili.

### 1) Scroll-jacking con inerzia pesante (solo desktop con-motion)
- Un listener `wheel` NON passive intercetta la rotella SOLO mentre lo stage sticky e'
  "agganciato" (pinned: `rect.top<=0 && rect.bottom>=innerHeight`) e il progress
  virtuale e' strettamente dentro (0,1). `vTarget` accumula `deltaY * WHEEL_STEP`
  (clamp 0..1); ogni frame `vCurrent += (vTarget - vCurrent) * INERTIA_K` (K=0.07,
  ease-out con coda lunga, niente overshoot). `progress = vCurrent` guida lo spin
  dell'elica al posto del vecchio getBoundingClientRect.
- **Rilascio ai bordi (anti-trappola)**: quando `vTarget` raggiunge 0 (cima) o 1
  (fondo) e la rotella spinge oltre in quella direzione, NON si fa preventDefault:
  lo scroll nativo riprende e porta l'utente all'intro sopra / alla "fine sezione"
  sotto, e si puo' rientrare. Al rilascio si imposta `engaged=false` e una finestra
  `releasedUntil = now + 450ms` in cui il re-aggancio e' bloccato, cosi' lo scroll
  nativo fa in tempo a uscire dalla zona pinned senza essere risucchiato indietro.
- **Lockstep con lo scroll nativo**: mentre agganciati, ogni frame
  `window.scrollTo(0, top + progress*maxRange)` tiene la posizione nativa allineata
  al progress eased. Lo stage e' sticky e resta fermo, quindi questo spostamento e'
  invisibile, ma garantisce che al rilascio la pagina sia nel punto giusto. La
  sezione occupa quindi 500vh di scroll REALE (non e' un pin finto).
- **Velocita' istantanea** `v = progress - lastProgress` per frame e' esposta e
  alimenta l'aberrazione cromatica.
- reduced-motion: il JS esce prima (return), nessun scroll-jacking, scroll nativo +
  layout statico. Mobile (<=760px): percorso reveal attuale, scroll nativo, nessun
  jacking (il loop desktop non parte).

### 2) Grana / noise cinematografica
- Un `<canvas id="grain">` FISSO a tutta pagina, `pointer-events:none`, `z-index:9999`,
  `mix-blend-mode:overlay`, opacita' `GRAIN_OPACITY` (0.05). Un tile di rumore 128x128
  (ImageData random) viene rigenerato ogni `GRAIN_EVERY` frame (2) e tilato con un
  pattern `repeat` su tutta la viewport: economico. Opacita' 0 di default in CSS,
  accesa dal JS -> senza JS / reduced-motion niente grana. reduced-motion: `#grain`
  display:none.

### 3) Aberrazione cromatica velocity-driven sui titoli
- Niente duplicazione del testo (il copy delle card non va toccato): la CA e' resa con
  due `text-shadow` colorati (rosso e ciano) offset di `+/- var(--ca)` px, su
  `.section-head h2` e sul titolo della card A FUOCO (`.card.is-focus h3`). A riposo
  `--ca = 0` (nessuno split). Il JS calcola `caTarget = |v| * CA_GAIN`, clamp a
  `CA_MAX` (6px), con smoothing, e aggiorna `--ca` ogni frame: fermo ~0px, scroll
  veloce fino a ~6px. reduced-motion: `--ca` resta 0 e i `text-shadow` sono annullati.

### 4) Profondita' atmosferica (blur + dim sulle card dietro)
- Nel loop, le card con front-factor `t < DEPTH_T` (0.60) e non a fuoco ricevono
  `filter: blur() brightness()` crescenti con `(DEPTH_T - t)/DEPTH_T`: blur fino a
  `DEPTH_BLUR_MAX` (4px), brightness fino a `DEPTH_DIM_MIN` (0.60). La card a fuoco (o
  hovered) resta nitida (`filter:none`). reduced-motion: nessun blur (JS off +
  `.card{filter:none!important}`).

### 5) Particelle additive + bloom mirato
- Il campo particelle passa a blending additivo (`globalCompositeOperation='lighter'`),
  tinte di palette (ciano / viola / verde phosphor), un filo piu' dense (`PART_COUNT`),
  con `shadowBlur` morbido scalato da `BLOOM`. Bloom sulla SPINA via pseudo
  `.spine::before` (radiale ciano/viola sfocato, opacita' da `--bloom`). Glow extra sul
  titolo della card a fuoco (il terzo `text-shadow` di `.card.is-focus h3`).
  reduced-motion/mobile: particelle come prima (ferme/nascoste in reduced).

## Manopole chiave (in cima al blocco JS)

Effetti AT (blocco "AT-STYLE EFFECT KNOBS", condiviso in cima all'IIFE):
- `PART_COUNT` (90): densita' particelle (clamp alto).
- `BLOOM` (1.0): intensita' glow spina + particelle.
- `GRAIN_OPACITY` (0.05) / `GRAIN_EVERY` (2): forza grana / ogni quanti frame rigenera.
- `INERTIA_K` (0.07): durezza dell'inerzia dello scroll-jack (piu' basso = piu' pesante).
- `WHEEL_STEP` (0.00065): progress aggiunto per pixel di deltaY (peso della rotella).
- `CA_MAX` (6) / `CA_GAIN` (110): CA massima in px / guadagno da |velocita'|.
- `DEPTH_T` (0.60) / `DEPTH_BLUR_MAX` (4) / `DEPTH_DIM_MIN` (0.60): soglia e intensita'
  del blur/dim atmosferico.

Elica (tarata dall'operatore, blocco "helix geometry"):

- `R` (340): raggio dell'elica. Piu' grande = card frontale piu' avanti e piu' stacco
  davanti/dietro.
- `STEP` (54): passo angolare tra le card (10 card ~ 1.5 giri, vicini distanziati).
- `RISE` (40): discesa verticale per card = quanto "spirale" e' l'elica.
- `SPAN` (486 = 9*STEP): gradi di rotazione totale sullo scroll (porta tutte e 10 al
  fronte, in sequenza 01..10).
- `IDLE` (0.004 deg/ms): velocita' dell'auto-rotazione a riposo.
- `LERP` (0.085) / `HLERP` (0.18): morbidezza di parallax / swing hover.
- `perspective` (1100px, su `.stage`): forza della prospettiva 3D.
- Particelle: `count` autoscala con l'area (cap 36..66), lente.

## Reduced motion

`@media (prefers-reduced-motion:reduce)` azzera ogni durata di animazione/transizione,
nasconde spina/particelle/packet/archi, forza `.helix` e card in colonna statica,
dritte, piena opacita', leggibili. In piu' il JS, se rileva reduced-motion al load,
**esce subito** (`return`): niente elica, niente scroll-binding, niente idle, niente
parallax, niente canvas, niente loop. Doppia difesa (CSS + JS). Il contenuto resta
pienamente leggibile anche senza JS (il JS e' solo enhancement).

## Responsive

- Desktop 1280-1920: elica piena.
- `<=760px`: niente elica 3D. Reveal verticale pulito (card impilate centrate,
  fade+slide-up via IntersectionObserver), spina ancora viva. Nessuno scroll
  orizzontale di pagina (`overflow-x:hidden` sul body, stage `overflow:hidden`).

## Accessibilita'

- `h2` titolo sezione (spostato in alto a sinistra come intro, non piu' a fine
  sezione), `h3` per ogni card, paragrafi reali. Card `tabindex="0"`; al focus da
  tastiera la card viene portata al fronte (stesso swing dell'hover) e
  `aria-labelledby` la lega al suo titolo. Il `:focus-visible` del browser mostra il
  focus ring nativo sulla card.
- Spina, archi, particelle, contatore e label chrome sono `aria-hidden="true"`.
- Rispetto pieno di `prefers-reduced-motion`.

## Performance

- Un solo `requestAnimationFrame` per elica + placement card + parallax; scroll e
  pointer non lavorano nel listener, settano solo valori letti nel frame.
- Si animano SOLO `transform` e `opacity` (niente layout/paint), con `will-change`
  su costellazione, helix e card.
- Canvas particelle economico (poche decine di cerchi, dpr cap 2).

## GDPR / dati

Solo dati sintetici: ESSID di fantasia (Residence-Lab6, Officina-Mesh,
Caffe-Nord_5G, Studio-Test, Rete-di-prova) e MAC **locally-administered** (secondo
nibble del primo ottetto in {2,6,A,E}): CA:4C:75:11:0A:F2, 7A:1B:3D:09:C4:22,
AE:90:2C:77:51:0B, 06:2F:A1:88:3C:D4, E2:55:19:B0:6A:7D. Nessun OUI reale, nessun
nome di rete reale. Metriche nelle card (1.2 MH/s, ecc.) sono placeholder.

## Tradeoff e limiti

- Le card di spalle mostrano il testo speculare, ma a opacita' ~0.14 e rimpicciolite
  leggono come ghost di profondita'. Scelta consapevole: NON uso
  `backface-visibility:hidden` perche' il coordinatore vuole le card dietro
  "parzialmente visibili/occluse dalla spina", non sparite.
- Con `R=340` e `perspective=1100`, la card frontale e' ingrandita di ~1.45x dalla
  prospettiva: bella e dominante, ma su viewport molto stretti (verso 760px, prima
  di passare al reveal) potrebbe avvicinarsi ai bordi. Target desktop 1280+ ok; da
  rifinire eventualmente su monitor reale abbassando R o la perspective.
- Il percorso (statico / reveal / elica) e' scelto una volta al load: un resize che
  attraversa 760px non ricommuta a caldo (un refresh lo risolve). Scelta voluta per
  semplicita' e robustezza.
- Il loop rAF gira in continuo (serve a idle + parallax). E' cheap (solo transform);
  volendo si potrebbe sospendere con un IntersectionObserver quando la sezione esce
  dal viewport.
- Timing di idle, SPAN, RISE e raggio sono "a orecchio": da affinare nel collaudo
  visivo sul monitor reale.

## Verificato

- `node --check` sul blocco script: sintassi JS OK.
- Parsing HTML ok (html.parser, 0 errori).
- 0 occorrenze di em dash (U+2014) o en dash (U+2013) in tutto il file.
- Tutti i MAC restano locally-administered; ESSID di fantasia invariati.
- 10 card seat a 54deg l'una dall'altra -> impossibile l'accavallamento verticale.
- Copy reale delle 10 card NON toccato (verificato: 10 h3 id c1t..c10t invariati; la
  profondita' usa solo `filter` via JS, nessuna modifica al testo/attributi di copy).
- Mappatura nodi N=10 -> 5 nodi: card 0..9 accendono nodi 0,0,1,1,2,2,3,3,4,4.
- Effetti AT aggiunti e verificati staticamente: `#grain` presente, `updateScroll`,
  listener `wheel` non-passive, `--ca`/`--bloom`, particelle additive, grana,
  depth-filter nel loop. `node --check` dopo l'aggiunta: OK.

NON verificato (serve occhio su browser reale, non ho pilotato il browser): resa a
60fps con grana + particelle additive + blur atmosferico (carico combinato da
osservare), qualita' percepita dello scroll-jacking e dell'inerzia, correttezza del
rilascio ai bordi (su / giu / rientro), entita' giusta della CA e della grana. Da
collaudare in Firefox/Chromium desktop + emulazione mobile. Nota: lo scroll-jacking
fa lockstep con `window.scrollTo`, quindi trascinare la scrollbar o usare la tastiera
dentro la sezione agganciata viene riportato al progress virtuale (comportamento
tipico AT); se indesiderato, si puo' limitare il jacking alla sola rotella.
