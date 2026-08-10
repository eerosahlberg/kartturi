# Maanmittauslaitoksen Karttamerkkien Tyylimäärittelyt (Mapbox GL / MapLibre)

Tämä dokumentti sisältää kootusti maastokarttojen vektorityylien spesifikaatiot. Määrittelyt on jaoteltu teemoittain alueisiin (fill), viivoihin (line) ja symboleihin/teksteihin (symbol), jotta ne on helppo siirtää `style.json`-muotoon.

---

## 1. Liikenneverkot ja johtoyhteydet

### Tiet ja moottoriajoneuvojen väylät

| Kohde (FI)                  | Kohde (EN)          | Väri (Hex) | Leveys        | Tyyli / Kuvaus                                                                                         |
| :-------------------------- | :------------------ | :--------- | :------------ | :----------------------------------------------------------------------------------------------------- |
| **I a luokan moottoritie**  | I a class motorway  | `#CC3333`  | `4.0 - 6.0px` | Punainen keskusta, valkoinen sisäviiva, tummanharmaat reunukset (`casing`). Magentanvärinen tienumero. |
| **I b luokan autotie**      | I b class road      | `#CC3333`  | `3.0 - 4.5px` | Punainen viiva tummanharmailla reunuksilla.                                                            |
| **II a, b luokan autotie**  | II a, b class road  | `#993333`  | `2.5 - 3.5px` | Ruosteenruskea viiva tummanharmailla reunuksilla.                                                      |
| **III a, b luokan autotie** | III a, b class road | `#660000`  | `1.5 - 2.0px` | Tummanpunainen/ruskea viiva.                                                                           |
| **Autoliikennealue**        | Motor traffic area  | `#F3D09D`  | Alue          | Vaaleanruskea/beige alue, katkoviivareunus (`[4, 2]`).                                                 |

### Pienemmät kulkuväylät ja raiteet

| Kohde (FI)                  | Kohde (EN)            | Väri (Hex) | Leveys  | Tyyli / Kuvaus                                    |
| :-------------------------- | :-------------------- | :--------- | :------ | :------------------------------------------------ |
| **Ajotie**                  | Drive                 | `#404040`  | `1.0px` | Yhtenäinen tummanharmaa ohut viiva.               |
| **Ajopolku**                | Drive path            | `#404040`  | `1.0px` | Katkoviiva: `dasharray: [4, 3]`.                  |
| **Polku**                   | Path                  | `#808080`  | `0.8px` | Lyhyt katkoviiva / piste: `dasharray: [2, 2]`.    |
| **Pitkospuut**              | Causeway              | `#808080`  | `2.0px` | Viiva, jossa toistuvia poikkiviivoja (`++++`).    |
| **Pyörätie**                | Bicycle path          | `#404040`  | `1.0px` | Piste-katkoviiva: `dasharray: [5, 2, 1, 2]`.      |
| **Talvitie**                | Winter road           | `#404040`  | `1.0px` | Pitkä katkoviiva: `dasharray: [6, 4]`.            |
| **Rautatie (sähköistetty)** | Railway (electrified) | `#1A1A1A`  | `1.5px` | Musta viiva, jossa 'Z' (salama) symboleja välein. |
| **Rautatie (muu)**          | Railway               | `#1A1A1A`  | `1.5px` | Musta viiva, jossa toistuvia poikkiviivoja.       |

### Vesiliikenne ja turvalaitteet

| Kohde (FI)           | Kohde (EN)        | Väri (Hex) | Leveys/Tyyli | Kuvaus                                                      |
| :------------------- | :---------------- | :--------- | :----------- | :---------------------------------------------------------- |
| **Lautta tai lossi** | Ferry             | `#1A1A1A`  | `1.0px`      | Katkoviiva vesialueen yli: `dasharray: [4, 4]`.             |
| **Laivaväylä**       | Ship channel      | `#1A1A1A`  | `1.0px`      | Yhtenäinen viiva, suuntanuolia (`<` / `>`) ja syvyysteksti. |
| **Venereitti**       | Boat route        | `#1A1A1A`  | `1.0px`      | Katkoviiva: `dasharray: [5, 5]`.                            |
| **Viitat, poijut**   | Buoys, spar buoys | `#1A1A1A`  | Symboli      | Erilaisia SVG-merimerkkejä (kolmioita, palloja).            |
| **Majakka, kummeli** | Lighthouse, cairn | `#1A1A1A`  | Symboli      | Tähti (`★`) tai avoin kolmio (`△`).                         |

### Johtoyhteydet

| Kohde (FI)            | Kohde (EN)         | Väri (Hex) | Leveys/Tyyli | Kuvaus                                            |
| :-------------------- | :----------------- | :--------- | :----------- | :------------------------------------------------ |
| **Kaasujohto**        | Gas pipe           | `#808080`  | `1.0px`      | Katkoviiva, jossa K-kirjain välein (`- - K - -`). |
| **Sähkölinja**        | Electricity line   | `#1A1A1A`  | `0.8px`      | Yhtenäinen ohut viiva.                            |
| **Muuntaja / Pylväs** | Transformer / Pole | `#1A1A1A`  | Symboli      | Neliö tai poikkiviiva sähkölinjan päällä.         |

---

## 2. Rakennukset ja runkopisteet

### Rakennukset ja alueet (Fill)

| Kohde (FI)                          | Kohde (EN)              | Väri (Hex) | Kuvaus                                               |
| :---------------------------------- | :---------------------- | :--------- | :--------------------------------------------------- |
| **Kirkolliset rakennukset**         | Church buildings        | `#7A287B`  | Liila alue, usein ristikuvioinen, ilman reunaviivaa. |
| **Hautausmaa**                      | Cemetery                | `#A3C2A3`  | Vaaleanvihreä alue mustalla reunuksella (`0.5px`).   |
| **Asuin-, loma-, liikerakennukset** | Residential, commercial | `#C85A8A`  | Pinkki/magenta alue mustalla reunuksella (`0.5px`).  |
| **Pienet rakennukset**              | Small buildings         | `#404040`  | Tummanharmaa alue ilman reunusta.                    |
| **Tehdas- ja talousrakennukset**    | Factory / agricultural  | `#B3A8AC`  | Lämmin harmaa/ruskea alue mustalla reunuksella.      |
| **Varastorakennukset**              | Warehouses              | `#D0D0D0`  | Vaaleanharmaa alue mustalla reunuksella.             |
| **Varastoalue**                     | Storage area            | `#F2F2E8`  | Beige alue reunuksella, usein `#` kuvio sisällä.     |

### Viivamaiset kohteet (Line)

| Kohde (FI)      | Kohde (EN)   | Väri (Hex) | Leveys  | Tyyli / Kuvaus                                      |
| :-------------- | :----------- | :--------- | :------ | :-------------------------------------------------- |
| **Aita**        | Fence        | `#1A1A1A`  | `0.8px` | Musta viiva, jossa pieniä solmupisteitä välein.     |
| **Pensasaita**  | Hedge        | `#208020`  | `1.5px` | Vihreä pisteviiva: `dasharray: [0, 2]`.             |
| **Puurivi**     | Row of trees | `#208020`  | `2.5px` | Paksumpi vihreä pisteviiva harvemmalla välillä.     |
| **Hiihtohissi** | Ski lift     | `#1A1A1A`  | `0.8px` | Musta viiva kohtisuorilla ankkuriviivoilla (T-bar). |

### Pistesymbolit ja maamerkit (Symbol)

| Kohde (FI)                 | Kohde (EN)            | Väri (Hex) | Ikonin kuvaus                                           |
| :------------------------- | :-------------------- | :--------- | :------------------------------------------------------ |
| **Vesitorni / Savupiippu** | Water tower / Chimney | `#1A1A1A`  | Musta pallo (vesitorni) tai avoin rengas (savupiippu).  |
| **Radiomasto**             | Radio tower           | `#1A1A1A`  | Musta piste pystyviivalla ja nuolilla.                  |
| **Tuulivoimala**           | Wind power plant      | `#1A1A1A`  | Avoin ympyrä pystyviivalla ja ruksilla.                 |
| **Muistomerkki**           | Monument              | `#1A1A1A`  | Avoin obeliski / kapea kolmio.                          |
| **Runkopisteet**           | Control points        | `#1A1A1A`  | Avoin kolmio (`△`) tai ristiympyrä (`⊕`) numeroarvolla. |

---

## 3. Maasto ja kasvillisuus

### Maankäyttö ja pinnanmuodot (Fill / Pattern)

| Kohde (FI)                  | Kohde (EN)            | Väri (Hex) / Tyyli | Kuvaus                                                    |
| :-------------------------- | :-------------------- | :----------------- | :-------------------------------------------------------- |
| **Pelto**                   | Arable land           | `#EEDCA1`          | Tasainen vaaleankeltainen/kullanvärinen alue.             |
| **Puutarha, niitty**        | Garden, meadow        | `#EEDCA1`          | Keltainen alue vihreällä pistekuviolla (`fill-pattern`).  |
| **Metsäinen alue**          | Forested area (white) | `#FFFFFF`          | Valkoinen alue mustilla lainausmerkeillä (`"`).           |
| **Avoin vesijättö / metsä** | Open area / forest    | `#FCEB64`          | Kirkkaankeltainen alue. Metsämaassa ruskea vinoviivoitus. |
| **Urheilu- / puistoalue**   | Park / sports         | `#CDE097`          | Tasainen vaaleanvihreä alue.                              |
| **Vaikeakulkuinen suo**     | Marsh (difficult)     | `#D6C76E` (Puuton) | Beige alue tiheällä sinisellä vaakaviivoituksella.        |
| **Helppokulkuinen suo**     | Marsh (easy)          | `#B3D4E6` (Metsä)  | Tasainen vaaleansininen (metsä) tai beige (puuton) alue.  |
| **Avokallio**               | Exposed bedrock       | `#D6C5C5`          | Tasainen vaaleanpunertavanharmaa alue.                    |
| **Kivikko, louhikko**       | Rock / boulder field  | `#FFFFFF`          | Valkoinen alue, jossa mustia kolmioita tai pisteitä.      |
| **Hietikko**                | Bare sand             | `#FCEB64`          | Keltainen alue mustalla pistekuviolla.                    |

### Hydrografia (Vesistöt)

| Kohde (FI)     | Kohde (EN)    | Tyyppi | Väri (Hex) | Kuvaus                                             |
| :------------- | :------------ | :----- | :--------- | :------------------------------------------------- |
| **Vesialue**   | Water area    | `fill` | `#93CCEE`  | Vaaleansininen alue.                               |
| **Rantaviiva** | Shoreline     | `line` | `#1A5A90`  | Tummansininen yhtenäinen viiva (`1.0-1.5px`).      |
| **Puro / Oja** | Brook / Ditch | `line` | `#1A5A90`  | Tummansininen viiva (`0.8px - 1.5px`).             |
| **Matalikko**  | Shallows      | `fill` | `#93CCEE`  | Vaaleansininen alue tummansinisellä pistekuviolla. |

---

## 4. Korkeus- ja syvyystiedot

| Kohde (FI)      | Kohde (EN)        | Väri (Hex) | Leveys/Tyyli | Kuvaus                                                           |
| :-------------- | :---------------- | :--------- | :----------- | :--------------------------------------------------------------- |
| **Johtokäyrä**  | Index contour     | `#A66329`  | `1.2px`      | Yhtenäinen ruskea viiva + korkeusarvo tekstinä.                  |
| **Välikäyrä**   | Auxiliary contour | `#A66329`  | `0.6px`      | Ohut yhtenäinen ruskea viiva.                                    |
| **Apukäyrä**    | Help contour      | `#A66329`  | `0.6px`      | Ruskea katkoviiva: `dasharray: [4, 4]`.                          |
| **Jyrkänne**    | Steep             | `#1A1A1A`  | `line`       | Musta viiva alaspäin osoittavilla hampailla/viivoilla.           |
| **Syvyyskäyrä** | Depth contour     | `#006EB3`  | `line`       | Tummansininen viiva (syvät yhtenäisellä, matalat katkoviivalla). |

---

## 5. Rajat

| Kohde (FI)          | Kohde (EN)               | Väri (Hex) | Tyyli / Kuvaus                                                   |
| :------------------ | :----------------------- | :--------- | :--------------------------------------------------------------- |
| **Valtakunnanraja** | International boundary   | `#803080`  | Paksu liila katkoviiva liilalla vinoviivoituksella (`hatching`). |
| **Rajavyöhyke**     | Boundary zone            | `#B880B8`  | Ohuempi vaaleanliila katkoviiva vinoviivoituksella.              |
| **Aluevesiraja**    | Territorial waters limit | `#502050`  | Paksu tummanliila katkoviiva pitkillä väleillä: `[8, 4]`.        |
| **Maakunnanraja**   | Regional boundary        | `#502050`  | Tummanliila piste-katkoviiva: `dasharray: [6, 2, 1, 2, 1, 2]`.   |
| **Kunnanraja**      | Municipal boundary       | `#502050`  | Tummanliila piste-katkoviiva: `dasharray: [6, 2, 1, 2]`.         |
| **Suojelualue**     | Conservation area        | `#59A869`  | Vihreä katkoviiva vihreällä sisäpuolisella vinoviivoituksella.   |

---

## 6. Paikannimistö ja Typografia

Kaikki tekstit asetetaan `symbol`-tason `text-field`-ominaisuudella.

| Tyyppi (FI)             | Esimerkki             | Fontin tyyli ja paino  | Väri (Hex) | Tekstimuunnos (Transform) |
| :---------------------- | :-------------------- | :--------------------- | :--------- | :------------------------ |
| **Pienet asutukset**    | Koivumäki             | Sans-Serif, Regular    | `#1A1A1A`  | `none` (Title Case)       |
| **Kaupungit**           | MARIEHAMN             | Sans-Serif, Regular    | `#1A1A1A`  | `uppercase`               |
| **Suurkaupungit**       | HELSINKI              | Sans-Serif, Bold       | `#1A1A1A`  | `uppercase`               |
| **Maastonimet**         | _Högberget_, _Isosuo_ | Sans-Serif, **Italic** | `#1A1A1A`  | `none` (Title Case)       |
| **Vesistönimet**        | Päijänne, Lumipuro    | Sans-Serif, Regular    | `#006EB3`  | `none` (Title Case)       |
| **Selitteet / Yleiset** | Terveyskeskus         | Sans-Serif, Regular    | `#1A1A1A`  | `none` (Title Case)       |
| **Suojelualueen nimi**  | Luonnonsuojelualue    | Sans-Serif, Regular    | `#2D9154`  | `none` (Title Case)       |
| **Ampuma-alueen nimi**  | Ampuma-alue           | Sans-Serif, Regular    | `#763481`  | `none` (Title Case)       |
