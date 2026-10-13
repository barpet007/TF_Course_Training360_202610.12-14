# Tanulói feladat - Terraform modulok

## Cél

Megérteni a kapcsolatot között:

- gyökérmodul
- gyermekmodul
- modulbemenet
- modulkimenet
- gyermekmodulban létrehozott erőforrás

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
- Hozzáférés van Azure-hez, ha a modul konfigurációját alkalmazni szeretnéd
- Meglévő demo fájlok:
  - `../../demo-folder/main.tf`
  - `../../demo-folder/modules/my-storage/main.tf`
  - `../../demo-folder/modules/my-storage/variables.tf`
  - `../../demo-folder/modules/my-storage/outputs.tf`

## Kiindulási pont

Használd a meglévő modulos példát itt:

- `../../demo-folder/main.tf`
- `../../demo-folder/modules/my-storage/main.tf`
- `../../demo-folder/modules/my-storage/variables.tf`
- `../../demo-folder/modules/my-storage/outputs.tf`

A demo már mutatja, hogy a gyökérmodul értékeket ad át a gyermekmodulnak, majd a gyökérmodul a modul kimenetét olvassa be.

Ne másold le egyszerűen a demót. Inkább ellenőrizd az interfészét, módosíts egy értéket, és jósolj a hatásáról.

## Feladat

1. Nyisd meg a gyökérmodul fájlt: `../../demo-folder/main.tf`.
2. Azonosítsd a `module` blokköt és az oda átadott értékeket.
3. Nyisd meg a gyermekmodul fájlt: `../../demo-folder/modules/my-storage/main.tf`.
4. Azonosítsd, hogy mely erőforrás jön létre a gyermekmodulban.
5. Nyisd meg a `../../demo-folder/modules/my-storage/variables.tf` fájlt, és azonosítsd az összes modulbemenetet.
6. Nyisd meg a `../../demo-folder/modules/my-storage/outputs.tf` fájlt, és azonosítsd a modulkimenetet.
7. Módosíts egy kis modulbemenetet a gyökér konfigurációban.
8. Jósold meg, hogyan fog változni a terv, még a Terraform futtatása előtt.
9. Futtasd a `terraform fmt`, `terraform validate` és `terraform plan` parancsokat.
10. Figyeld meg, mi változott, és magyarázd el az adatfolyamot a gyökér modulbemenettől a gyermekmodul erőforrásáig és a gyökérmodul kimenetéig.

## Mielőtt lefuttatnád a Terraformet

Válaszolj ezekre a kérdésekre a módosítás előtt:

1. Mely értékek kerülnek a gyökérmodulból a gyermekmodulba?
2. Mely erőforrás jön létre a gyermekmodulban?
3. Mely érték kerül vissza a gyermekmodulból a gyökérmodulba?
4. Mi történik, ha megváltoztatod a `storage_name`, a `location` vagy a `replication` egyik értékét?

## Végrehajtás

Csak a releváns parancsokat futtasd:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

## Megfigyelés

Nézd meg a következőket:

- a `module` blokkba átadott értékeket
- a gyermekmodul erőforrás argumentumait
- a gyökérmodulhoz visszaadott modul kimenetét
- a tervet, amely megmutatja, mely értékek változtak
- a függőségi kapcsolatot a gyökér erőforráscsoport és a modulbemenet értékek között

## Magyarázat

Válaszolj ezekre a kérdésekre a terv után:

1. Mi a különbség a gyökérmodul és a gyermekmodul között?
2. Miért szüksége van a gyermekmodulnak a gyökérmodulból érkező bemenetekre?
3. Miért szükséges a gyökérmodulnak a gyermekmodul kimenete?
4. Miért újrafelhasználható egy modul, még akkor is, ha az alapul szolgáló erőforrás logika ugyanaz marad?

## Sikerkritériumok

- [ ] Azonosítom a gyökérmodul és a gyermekmodul közötti különbséget.
- [ ] Azonosítom az összes modulbemenetet.
- [ ] Azonosítom a gyermekmodul erőforrását.
- [ ] Azonosítom a modulkimenetet.
- [ ] Tudom megjósolni a tervet egy modulbemenet módosítása után.
- [ ] El tudom magyarázni az adatfolyamot a gyökérbemenettől a gyermekmodul erőforrásán át a gyökérmodul kimenetéig.

## Takarítás

Ha az oktató kérni fogja a létrehozott erőforrások eltakarítását, használd:

```bash
terraform destroy
```

Csak akkor töröld az erőforrásokat, ha az környezetben ténylegesen létrejöttek.
