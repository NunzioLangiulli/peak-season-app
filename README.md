# Peak Season – App della frutta e verdura di stagione

**Peak Season** ti dice cosa è di stagione **nella tua zona, questo mese**, quando un prodotto è al **picco**, come sceglierlo, come conservarlo e quanto pesa sull'ambiente. L'app funziona **interamente offline**, in **italiano o inglese**, ed è costruita sul database *Peak Season – Database della frutta e verdura di stagione* ([peak-season-database](https://github.com/NunzioLangiulli/peak-season-database)): 153 prodotti, 46 fonti ufficiali e nessun dato inventato.

App Flutter per Android (iOS previsto in seguito). **Versione attuale: 1.0.0 beta.**

---

## Funzionalità

### Home: cosa è di stagione adesso

- **Selettore del mese**, che parte da oggi, e un riepilogo veloce ("12 al picco della stagione · 38 di stagione").
- **Tre viste:**
  - **Griglia** con foto e stato stagionale;
  - **Lista** compatta, con badge di climaterico/non climaterico e impronta di carbonio e idrica;
  - **Calendario 12 Mesi**: tutti i prodotti a colpo d'occhio, con il mese scelto al centro.
- **Ricerca** per nome (italiano, inglese, sinonimi).
- **Categorie** a selezione multipla: Tutti, Frutta, Verdura, Altro (erbe e spezie, funghi, cereali).
- **Filtri avanzati:** stato stagionale nel mese scelto, solo DOP/IGP, solo preferiti, solo lista della spesa, prodotti nascosti.
- **Ordinamento per stagionalità**: prima ciò che è al picco, poi di stagione, primizie, fine stagione.

### Sette stati stagionali, con icone di crescita

| Stato | Significato |
|---|---|
| **Primizia** | inizio stagione, prime raccolte |
| **In Stagione** | disponibilità regolare |
| **Picco** | i mesi centrali su cui tutte le fonti concordano |
| **Fine Stagione** | ultime raccolte o prodotto da conservazione |
| **Fuori Stagione** | serra riscaldata o importazione |
| **Non Coltivato Qui** | frutti esotici senza produzione nella zona |
| **Dati Non Disponibili** (grigio, "?") | nessuna fonte per la tua zona: **non** vuol dire fuori stagione |

Quando manca il dato della tua zona, l'app può mostrare la **stima dalla zona climatica vicina**, marcata con **≈**. La stima viene dal database, non è calcolata dall'app, e si può disattivare nelle Impostazioni.

### La tua zona

- **Area italiana (Km 0):** Nord, Centro (con l'Abruzzo), Sud e Isole, oppure la zona Mediterranea generica.
- **Zona climatica europea (EUFIC):** Mediterranea, Continentale, Atlantica, Boreale, Alpina, Pannonica, con la **mappa delle regioni biogeografiche** EEA e l'elenco dei Paesi di ogni zona.
- Se scegli una zona senza calendario proprio, l'app dice quale **calendario di riferimento** sta usando.

### Scheda prodotto

Una scheda completa, divisa in blocchi che puoi **riordinare, chiudere o nascondere** dalle Impostazioni:

- **Galleria** con più tipi di foto (principale, pianta in campo, tavola botanica, sezione), anche a schermo intero, con autore e licenza.
- **Calendario stagionale** dell'anno per la tua zona, con legenda e la spiegazione di *come è stata calcolata la stagionalità* per quel prodotto.
- **Varietà e territori:** varietà note, **DOP/IGP** verificate sul registro UE, Prodotti Agroalimentari Tradizionali per regione, Presìdi Slow Food.
- **Acquisto, maturazione e conservazione:**
  - come sceglierlo;
  - **climaterico / non climaterico**, cioè se continua a maturare dopo la raccolta;
  - come farlo maturare e come rallentare il deperimento;
  - **dove conservarlo** (frigo, ambiente, dispensa…) e **quanto dura** in casa, in frigo e in freezer;
  - **deperibilità** su 6 livelli;
  - **cosa tenergli lontano** (prodotti che emettono etilene).
- **Valori nutrizionali** per 100 g, **vitamine e minerali in % VNR**, **indicazioni nutrizionali UE** raggruppate e colorate secondo il Reg. CE 1924/2006, allergeni e porzioni.
- **Sostenibilità:** impronta di carbonio e idrica, confronto con la carne bovina.
- **Calendario dell'orto:** semina, trapianto e raccolta per Nord, Centro e Sud.
- **Informazioni aggiuntive:** benefici, curiosità, consigli antispreco.
- **Fonti e link utili:** ogni fonte con sigla o logo e link diretto alla pagina usata.
- **Famiglia botanica:** gli altri prodotti della stessa famiglia, ordinati per stagionalità.
- Pulsanti **"?"** con glossario e spiegazioni dei termini tecnici.

### Le tue liste

- **❤️ Preferiti**, **🚫 Non lo mangio** (nascosto dalla Home, ma recuperabile) e **📋 Lista della spesa**.
- La **Lista Spesa** mostra per ogni prodotto se è di stagione nel mese corrente.

### Notifiche (Android)

- **Modalità spesa:** una notifica fissa, visibile anche dalla schermata di blocco, con ciò che è di stagione. Se hai una lista, la notifica evidenzia i tuoi prodotti oppure mostra solo quelli.
- **Consigli dopo la spesa:** quando chiudi la modalità spesa arriva una notifica, subito o dopo un ritardo da 0 a 60 minuti, che apre i **consigli di conservazione** dei prodotti comprati.
- **Avvisi "Picco di Stagione":** il primo di ogni mese alle 9, cosa entra nel picco. Puoi scegliere tra nessuna notifica, solo i preferiti, oppure tutti tranne quelli che non mangi.

### More Sustainable Diet

Una pagina che spiega, con i punti chiave di EUFIC, perché mangiare di stagione conta e quando non basta, per esempio con le serre riscaldate, il trasporto aereo o la lunga conservazione in cella.

### Personalizzazione

- **Lingua:** italiano o inglese. Tutta l'app, dati compresi, passa nella lingua scelta.
- **Tema:** chiaro, scuro (nero AMOLED) o di sistema.
- **Effetto vetro satinato** regolabile e **sfumature dello sfondo** (Verde, Verde e Acqua, Verde e Ambra, Nessuna).
- **Ordine e visibilità** dei blocchi della scheda prodotto (tieni premuto e trascina).

---

## Installazione su Android

1. Scarica il file `.apk` dall'ultima versione nella sezione **Releases** di questo repository.
2. Aprilo sul telefono. Se Android lo chiede, consenti l'installazione da questa fonte.
3. Nelle Impostazioni scegli lingua e zona (all'inizio è impostato il Nord Italia).

L'app non ha bisogno di internet. Serve solo per aprire i link alle fonti.

---

## Per sviluppatori

### Requisiti

- Flutter 3.47 (Dart 3.13), Android SDK con le licenze accettate (`flutter doctor --android-licenses`)

### Comandi

```bash
flutter pub get
flutter analyze
flutter test              # test sul database reale, resolver, filtri, testi e icone
flutter run               # telefono o emulatore collegato
flutter run -d chrome     # anteprima veloce nel browser (senza notifiche)
flutter build apk --release
```

### Architettura

```
lib/
  main.dart                avvio, provider, tema
  models/                  FoodItem (lettura null-safe del JSON), SeasonState, enum di zone e aree, claim, glossario
  data/                    FoodRepository (carica il database in un isolate e risolve il corpus condiviso),
                           SeasonalityResolver (dato esatto → stima ≈ se attiva → non coltivato → non noto)
  providers/               impostazioni, preferiti/liste, Home, layout della scheda, notifiche, navigazione
  screens/                 Home, scheda prodotto, famiglia, lista spesa, consigli di conservazione,
                           More Sustainable Diet, impostazioni
  widgets/                 card, calendari, mappa delle zone, filtri, galleria, badge delle fonti…
  notifications/           contenuto e programmazione delle notifiche
  l10n/                    CopyService + facciata S: tutti i testi vengono da assets/data/ui_copy.json
  theme/                   tema Material 3, palette degli stati, IconService (icone da ui_config.json)
assets/
  data/                    database.json (minificato), ui_copy.json, ui_config.json
  images/thumb, full       foto in WebP (600 px per le card, 1080 px per la galleria)
  icons/, maps/, sources/  icone degli stati, mappe, loghi delle fonti
```

**Principi:**

- **L'app non inventa dati.** Ogni regola di visualizzazione (colori, soglie, ordine dei calendari, regole dei claim, ordine della conservazione) viene da `metadata` del database.
- **Nessun testo scritto nel codice.** Tutti i testi stanno in `assets/data/ui_copy.json` (IT/EN) e tutte le icone in `assets/data/ui_config.json`. Si modificano senza programmare con l'Admin Studio del repository del database; i test controllano che le chiavi coincidano.
- **Gli asset si generano dal database.** Dopo ogni modifica del database o delle foto si rilancia `scripts/build_app_assets.py` nel repository del database, che aggiorna `assets/data/` e le immagini WebP.

### Crediti

- Dati: vedi le fonti elencate nel database (CREA, BDA-IEO, EUFIC, UC Davis, USDA, SU-EATABLE LIFE e altre).
- Foto: Wikimedia Commons, USDA ARS, Unsplash, Pixabay, iNaturalist. Autore e licenza di ogni foto sono indicati nell'app.
- Mappa delle zone: EEA Biogeographical Regions 2016 (CC BY 4.0) e Natural Earth.

### Licenza (open source)

- **Codice dell'app:** licenza [MIT](LICENSE).
- **Dati** (`assets/data/database.json`): CC BY 4.0, come nel repository del database, con i termini delle singole fonti per i valori di terzi.
- **Foto** (`assets/images/`): ogni foto ha la licenza del suo autore (pubblico dominio, CC0, CC BY, CC BY-SA, Unsplash, Pixabay), indicata nell'app e nel repository del database.
- **Loghi delle fonti** (`assets/sources/`): appartengono ai rispettivi enti e sono usati solo per indicare la fonte.

Progetto senza scopo commerciale. Le informazioni hanno scopo divulgativo e non sostituiscono il parere di un medico o di un nutrizionista.
