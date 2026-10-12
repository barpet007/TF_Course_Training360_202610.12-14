# Hallgatói gyakorlat - Terraform output és variables

## Cél

Tanuld meg a különbséget közöttük:

- VARIABLE = érték, amelyet a Terraformnak adunk meg
- OUTPUT = érték, amelyet a Terraform mutat ki

Ez a gyakorlat arra összpontosít, hogy az értékek hogyan kerülnek be a Terraformba, és hogyan adja vissza a Terraform az eredményt a felhasználónak.

## Kiindulópont

Használd a demo meglévő fájljait:

- variables.tf
- main.tf
- outputs.tf

Ezek a fájlok már bemutatnak egy random string erőforrást és olyan outputokat, amelyek a változókból származnak.

## Feladat

1. Nézd át, mely értékek vannak deklarálva változóként.
2. Nézd át, mely értékek kerülnek outputként vissza.
3. Módosíts egy változó értékét, például a string hosszt vagy a prefixet.
4. Futtasd a terraform plan parancsot, és nézd meg, hogyan változik a konfiguráció.
5. Futtasd a terraform apply parancsot, hogy létrehozd vagy frissítsd az eredményt.
6. Futtasd a terraform output parancsot, és nézd meg a létrehozott értékeket.
7. Magyarázd el, mely értékeket adtad meg te, és mely értékeket hozta létre a Terraform.

## Mielőtt futtatnád a Terraformet

Válaszolj ezekre a kérdésekre a módosítás alkalmazása előtt:

- Mely értékek a konfigurációban bemeneti változók?
- Mely értékeket hozza létre a Terraform az erőforrás létrehozása után?
- Ha megváltoztatod a változó értékét, várhatóan változik-e az output értéke?
- Mely rész a konfigurációnak a felhasználó által megadott érték, és mely rész a Terraform által kiadott érték?

## Végrehajtás

Futtasd a következő parancsokat:

```bash
terraform init
terraform plan
terraform apply
terraform output
```

Ezután módosíts egy változó értékét, és futtasd:

```bash
terraform plan
terraform apply
terraform output
```

## Megfigyelés

Ellenőrizd a következőket:

- a variables.tf fájlban deklarált változóértékeket
- az outputs.tf fájlban megjelenő output értékeket
- a random string eredményt az apply után
- azt a tényt, hogy az outputban megjelenő érték nem kézzel gépelt szöveg, hanem a Terraform által létrehozott érték

## Magyarázat

Válaszolj ezekre a kérdésekre a gyakorlat után:

- Mi a különbség a változó és az output között?
- Mely érték került a Terraformba a felhasználó által?
- Mely értéket hozta létre a Terraform?
- Miért hasznosabb az output, mint egy merev, beégetett érték ebben az esetben?

## Sikeres teljesítés feltételei

- [ ] Meg tudom azonosítani a konfigurációban lévő változókat
- [ ] Meg tudom azonosítani a konfigurációban lévő outputokat
- [ ] Tudom elmagyarázni, miért nem ugyanaz a változó, mint az output
- [ ] Lefuttatom a terraform plan, terraform apply és terraform output parancsokat
- [ ] Le tudom írni a mentális modellen: változó be, output ki

## Takarítás

Amikor az oktató elmondja, hogy a gyakorlat véget ért:

```bash
terraform destroy
```

Ha a demo kezelt erőforrásokat hoz létre a környezetedben, akkor a lab befejezése előtt távolítsd el őket.
