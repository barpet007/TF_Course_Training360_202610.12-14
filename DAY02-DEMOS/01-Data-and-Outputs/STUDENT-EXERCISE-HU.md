# Tanulói feladat - Adatforrás és kimenet

## Cél

Megérteni a különbséget között:

- `data` = meglévő infrastruktúra-információk lekérdezése
- `resource` = olyan infrastruktúra deklarációja, amelyet a Terraform kezel
- `output` = olyan érték megjelenítése, amelyet a Terraform már a kiértékelés vagy az apply után ismer

Ez a feladat a Day 02 oktatási modell szerint működik:

Konceptus
   ↓
Oktatói bemutató
   ↓
Tanulói jóslás
   ↓
Tanulói feladat
   ↓
terraform fmt / validate / plan
   ↓
Megfigyelés
   ↓
Magyarázat

## Előfeltételek

- Terraform CLI telepítve van
- Azure CLI konfigurálva van, ha a Terraformet Azure-vel szeretnéd futtatni
- Hozzáférés létezik egy Azure-előfizetéshez és egy meglévő erőforráscsoporthoz, amely megfelel a demo konfigurációjának
- Létező demo fájl: `../../Data and Outputs.tf`
- A data source által hivatkozott meglévő Azure objektum:
  - `data "azurerm_resource_group" "existing_rg"`
  - az erőforráscsoport nevének már léteznie kell Azure-ben

## Kiindulási pont

Használd a meglévő demo fájlt:

- `../../Data and Outputs.tf`

Ez a fájl már tartalmaz:

- egy `data` blokkot, amely egy meglévő erőforráscsoport adatait olvassa be
- egy `resource` blokkot, amely új virtuális hálózatot hoz létre
- egy `output` blokkot, amely a létrehozott VNet azonosítóját jeleníti meg

Ne másold le a teljes megoldást. Inkább azonosítsd a releváns részeket, és végezz el egy kis módosítást.

## Feladat

1. Nyisd meg a `../../Data and Outputs.tf` fájlt.
2. Azonosítsd a `data` blokkot.
3. Azonosítsd a `resource` blokkot.
4. Azonosítsd az `output` blokkot.
5. Jósold meg, mit olvas be a Terraform az Azure-ből, és mit hoz létre.
6. Módosíts egy kis értéket a meglévő demóban, amely világosan támogatott a konfigurációban.
7. Futtasd a `terraform fmt`, `terraform validate` és `terraform plan` parancsokat.
8. Figyeld meg a tervet, és magyarázd el, mi változott.
9. Ha a hivatkozott erőforráscsoport nem létezik, magyarázd el, mit fog tenni a Terraform és miért.

## Mielőtt lefuttatnád a Terraformet

Válaszold meg ezeket a kérdéseket a módosítás vagy validáció előtt:

1. Melyik rész olvas be meglévő információt a fájlból, ahelyett, hogy infrastruktúrát hozna létre?
2. Melyik rész deklarálja az infrastruktúrát, amelyet a Terraform kezelni fog?
3. Melyik érték jelenik meg a felhasználó számára az `output` segítségével?
4. Mi történne, ha a data source-ben megadott erőforráscsoport neve nem létezik az Azure-ben?

## Végrehajtás

Csak a releváns parancsokat futtasd:

```bash
terraform fmt
terraform validate
terraform plan
```

## Megfigyelés

Nézd meg a következőket:

- a `data` blokk és a hivatkozott meglévő Azure objektum
- a `resource` blokk, amely az új VNetet hozza létre
- hogyan használja a VNet a meglévő erőforráscsoportból beolvasott értékeket
- az output értéke, amelyet a Terraform a konfiguráció kiértékelése után mutat
- hogy a terv létrehozási műveletet jelez-e, vagy csak meglévő adatokra való függést

## Magyarázat

Válaszolj ezekre a kérdésekre a terv után:

1. Miért nem ugyanaz a `data` blokk, mint a `resource` blokk?
2. Miért függ az új VNet a meglévő erőforráscsoport adataitól?
3. Mit mutat az output, és miért hasznos ez?
4. Mit tud a Terraform a létrehozás előtt, és mit csak azután tud, hogy a resource létrejött?

## Sikerkritériumok

- [ ] Azonosítom a demo `data` blokkját.
- [ ] Azonosítom a demo `resource` blokkját.
- [ ] Azonosítom a demo `output` blokkját.
- [ ] El tudom magyarázni a meglévő információk lekérdezése és az új infrastruktúra létrehozása közötti különbséget.
- [ ] Tudom előre megjósolni egy kis konfigurációs módosítás hatását a plan előtt.
- [ ] El tudom magyarázni, miért befolyásolja a hiányzó meglévő Azure objektum a tervet.

## Takarítás

Ha az oktató kérni fogja a létrehozott erőforrások eltakarítását, használd:

```bash
terraform destroy
```

Csak akkor töröld az erőforrásokat, ha a demo ténylegesen hozott létre felügyelt erőforrásokat az Azure környezetben.
