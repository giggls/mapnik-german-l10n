# Abbreviations definitions & test cases

- Canadian Post: <https://www.canadapost.ca/tools/pg/manual/PGaddress-f.asp#1460716>
- OSM Wiki: <https://wiki.openstreetmap.org/wiki/Name_finder:Abbreviations>
- Mapbox Tokens: <https://github.com/mapbox/geocoder-abbreviations/tree/master/tokens>

## en - Englisch

### en - Streets

| Sample long                                                  | Sample shortened                                             | Expression  | Abbrev. | Regexp           | Test |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ----------- | ------- | ---------------- | ---- |
| [92 Avenue NW](https://b.tile.openstreetmap.org/18/48298/84753.png) | [92 Ave. NW](https://c.tile.openstreetmap.de/18/48298/84753.png) | Avenue      | Ave.    | (?!^)Avenue\M    | Yes  |
| [William S Canning Boulevard](https://a.tile.openstreetmap.org/18/79253/97630.png) | [William S Canning Blvd.](https://a.tile.openstreetmap.de/18/79253/97630.png) | Boulevard   | Blvd.   | (?!^)Boulevard\M | Yes  |
| -                                                            | -                                                            | Centre      | Ctr     |                  |      |
| -                                                            | -                                                            | Circle      | Cir.    |                  |      |
| -                                                            | -                                                            | Corners     | Crnrs   |                  |      |
| [Vinton Court](https://c.tile.openstreetmap.org/18/41938/101308.png) | [Vinton Ct](https://c.tile.openstreetmap.de/18/41938/101308.png) | Court       | Ct      |                  | Yes  |
| -                                                            |                                                              | Crescent    | Cres.   | Crescent\M       | -    |
| Mullholland Drive                                            | Mullholand Dr.                                               | Drive       | Dr.     | Drive\M          | Yes  |
| -                                                            |                                                              | Estates     | Estate  |                  |      |
| Oregon Expressway                                            | Oregon Expy                                                  | Expressway  | Expy    |                  | Yes  |
| Juniperro Serra Freeway                                      | Juniperro Serra Fwy                                          | Freeway     | Fwy     |                  |      |
| -                                                            |                                                              | Gardens     | Gdns    |                  |      |
| -                                                            |                                                              | Grounds     | Grnds   |                  |      |
| -                                                            |                                                              | Harbour     | Harbr   |                  |      |
| -                                                            |                                                              | Heights     | Hts     |                  |      |
| -                                                            |                                                              | Highlands   | Hghlds  |                  |      |
| -                                                            |                                                              | Highway     | Hwy     |                  |      |
| -                                                            |                                                              | Hollow      | Hollow  |                  |      |
| -                                                            |                                                              | Lane        | Ln.     | Lane\M           |      |
| -                                                            |                                                              | Landing     | Landng  |                  |      |
| -                                                            |                                                              | Limits      | Lmts    |                  |      |
| -                                                            |                                                              | Lookout     | Lkout   |                  |      |
| -                                                            |                                                              | Mountain    | Mtn     |                  |      |
| -                                                            |                                                              | Orchard     | Orch    |                  |      |
| -                                                            |                                                              | Park        | Pk      |                  |      |
| [Curtiss Parkway](https://c.tile.openstreetmap.org/16/18152/27900.png) | [Curtiss Pkwy](https://c.tile.openstreetmap.de/16/18152/27900.png) | Parkway     | Pkwy    | -                | -    |
| -                                                            |                                                              | Range       | Rg      |                  |      |
| Main Road                                                    | Main Rd.                                                     | Road        | Rd.     | Road\M           |      |
| -                                                            |                                                              | Pathway     | Ptway   |                  |      |
| [Sabin Place](https://b.tile.openstreetmap.org/18/41938/101307.png) | [Sabin Pl.](https://b.tile.openstreetmap.de/18/41938/101307.png) | Place       | Pl      |                  |      |
|                                                              |                                                              | Private     | Pvt     |                  |      |
| -                                                            |                                                              | Terrace     | Terr    |                  |      |
| [Trafalgar Square](https://c.tile.openstreetmap.org/18/130978/87169.png) | [Trafalgar Sq.](https://c.tile.openstreetmap.de/18/130978/87169.png) | Square      | Sq.     | Square\M         |      |
| [Main Street](https://b.tile.openstreetmap.de/17/36662/47815.png) | [Main St.](https://b.tile.openstreetmap.org/17/36662/47815.png) | Street      | St.     | Street\M         |      |
| -                                                            |                                                              | Subdivision | Subdiv  |                  |      |
| -                                                            |                                                              | Thicket     | Thick   |                  |      |
| -                                                            |                                                              | Townline    | Tline   |                  |      |
| -                                                            |                                                              | Turnabout   | Trnabt  |                  |      |


### en - Cardinal Directions

| Sample full                                                  | Sample short                                                 | Regexp      | Abreviation | Test |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ----------- | ----------- | ---- |
| North 50th Street                                            | N 50th St.                                                   | North\M     | N           | Yes  |
| [South Fuller Street](https://c.tile.openstreetmap.org/17/39346/49121.png) | [S Fuller St.](https://c.tile.openstreetmap.de/17/39346/49121.png) | South\M     | S           |      |
| -                                                            | -                                                            | West\M      | W           |      |
| [East 50th Street](https://c.tile.openstreetmap.org/17/38604/49260.png) | [E 50 St.](https://c.tile.openstreetmap.de/17/38604/49260.png) | East\M      | E           |      |
| - | - | Northwest\M      | NW           |      |
| - | - | Northeast\M      | NE           |      |
| - | - | Southwest\M      | SW           |      |
| [Carrol Street Southeast](https://b.tile.openstreetmap.ORG/17/34311/52441.png) | [Carrol St. SE](https://c.tile.openstreetmap.de/17/34311/52441.png) | Southeast\M | SE          | Yes  |

## fr - Francais

### fr - Streets

|                                     Sample (long)                                     |                                 Sample (short)                                  | Types de rues | Abbrev. |   RegExp   | Test |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ------------- | ----------- | --------------- | ------ |
| -                                                                                     |                                                                                 | Autoroute     | Aut         |   |        |
| [Avenue de la Gare](https://b.tile.openstreetmap.org/18/136280/92412.png)             | [Av. de la Gare](https://b.tile.openstreetmap.de/18/136280/92412.png)           | Avenue | Av.         | ^Avenue\M | Yes    |
| [Boulevard de Pérolles](https://c.tile.openstreetmap.org/18/136279/92414.png)         | [Bd de Pérolles](https://c.tile.openstreetmap.de/18/136279/92414.png)           | Boulevard | Bd          | ^Boulevard\M | Yes    |
| -                                                                                     |                                                                                 | Carré         | Car-        |                 |        |
| -                                                                                     |                                                                                 | Carrefour     | Carref.     |                 |        |
| -                                                                                     |                                                                                 | Centre        | C.          |                 |        |
| [Chemin des Bains](https://c.tile.openstreetmap.org/17/68142/46206.png)             | [Ch. des Bains](https://c.tile.openstreetmap.de/17/68142/46206.png) | Chemin        | Ch.         | ^Chemin\M | Yes |
| -                                                                                     |                                                                                 | Circuit       | Circt.      |                 |        |
| -                                                                                     |                                                                                 | Concession    | Conc        |                 |        |
| -                                                                                     |                                                                                 | Cul-de-sac    | Cds         |                 |        |
| -                                                                                     |                                                                                 | Diversion     | Divers.     |                 |        |
| -                                                                                     |                                                                                 | Échangeur     | Éch.        |                 |        |
| [Esplanade de l'Ancienne Gare](https://d.tile.openstreetmap.org/19/272557/184828.png) | [Espl. de l'Ancienne Gare](https://d.tile.openstreetmap.de/19/272557/184828.png) | Esplanade     | Espl.       | ^Esplanande\M | Yes  |
| -                                                                                     |                                                                                 | Extension     | Ext fr      |                 |        |
| [Impasse de la forêt](https://c.tile.openstreetmap.org/16/34073/23100.png)            | [Imp. de la forêt](https://c.tile.openstreetmap.de/16/34073/23100.png)          | Impasse       | Imp.        | ^Impasse\M |        |
| [Passage de Cardinal](https://b.tile.openstreetmap.org/18/136276/92417.png)           | [Pass. de Cardinal](https://b.tile.openstreetmap.de/18/136276/92417.png)        | Passage       | Pass.       | ^Passage\M  |        |
| -                                                                                     |                                                                                 | Plateau       | Plat        |                 |        |
| -                                                                                     |                                                                                 | Point         | Pt          |                 |        |
| -                                                                                     |                                                                                 | Promenade     | Prom,       |                 |        |
| -                                                                                     |                                                                                 | Rond-point    | Rdpt        |                 |        |
| [Route de Marly](https://b.tile.openstreetmap.org/16/34071/23106.png)                 | [Rte de Marly](https://b.tile.openstreetmap.de/16/34071/23106.png)              | Route         | Rte         | ^Route\M | Yes    |
| [Ruelle des Tonneliers](https://b.tile.openstreetmap.org/17/66943/44271.png)          | [Rle des Tonneliers](https://b.tile.openstreetmap.de/17/66943/44271.png)        | Ruelle        | Rle         | ^Ruelle\M | Yes    |
| [Sentier du Stand](https://a.tile.openstreetmap.org/18/136284/92403.png)          | [Sent. du Stand](https://a.tile.openstreetmap.de/18/136284/92403.png)        | Sentier       | Sent.       | ^Sentier\M | Yes    |
| -                                                                                     |                                                                                 | Terrasse      | Tsse        |                 |        |
