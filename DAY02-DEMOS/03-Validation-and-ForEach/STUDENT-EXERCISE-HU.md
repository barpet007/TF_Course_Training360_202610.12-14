# Tanulói feladat - Validáció, merge() és for_each

## Cél

Megérteni, hogy:

- a `variable validation` elutasítja a nem támogatott bemenetet
- a `merge()` összefűzi a map objektumokat
- a `for_each` erőforrás példányokat hoz létre egy gyűjteményből
- az `each.key` és az `each.value` a jelenlegi map-elemre hivatkozik

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
- Azure CLI konfigurálva van, ha Azure providerrel szeretnéd futtatni a Terraformet
- Meglévő demo fájl: `../../demo2/main.tf`
- Hozzáférés Azure-hez, ha a konfigurációt alkalmazni akarod

## Kiindulási pont

Használd a meglévő demo fájlt:

- `../../demo2/main.tf`

Ez a fájl már bemutatja:

- validációt az `environment` változóhoz
- egy subnet-definíciók mapjét, amelyet a `for_each` használ
- `merge()` hívást, amely címkék mapjeit fűzi össze
- egy VNet erőforrást, amely minden map elemhez létrejön

Ne másold le az oktatói megoldást. Inkább azonosítsd a validációs szabályt, jósolj a viselkedésről, és gondold át, mi történik, ha megváltoztatod a map bemenetét.

## Feladat

### A rész - Validáció

1. Nyisd meg a `../../demo2/main.tf` fájlt.
2. Azonosítsd az `environment` változó validációs blokkját.
3. Jósold meg, mi történik, ha az environment érvényes.
4. Jósold meg, mi történik, ha az environment érvénytelen.
5. Módosítsd a bemenetet kontrollált módon érvénytelen értékre.
6. Futtasd a `terraform validate` és `terraform plan` parancsokat.
7. Magyarázd el a validációs hibát köznyelven.
8. Állítsd vissza az érvényes értéket.

### B rész - Dinamikus erőforrások a `for_each` segítségével

1. Azonosítsd a `for_each` által használt mapet.
2. Jósold meg, hány VNet erőforrás jön létre.
3. Azonosítsd, hogy hol használják az `each.key` és `each.value` értékeket.
4. Módosíts egy map elemet, és jósolj meg a pontos tervbeli különbséget.
5. Futtasd a `terraform validate` és `terraform plan` parancsokat.
6. Magyarázd el, mi változott a tervben.

### C rész - `merge()`

1. Azonosítsd, mely mapeket fűzi össze a `merge()`.
2. Jósold meg az eredő címke mapet.
3. Magyarázd el, hogy melyik érték nyeri meg a küzdelmet, ha ugyanaz a címke kulcs mindkét mapben előfordul.

## Mielőtt lefuttatnád a Terraformet

Először válaszolj ezekre a kérdésekre:

1. Mely értékek engedélyezettek az `environment` számára a validációs szabály szerint?
2. Mi történik, ha az environment értéke nem az engedélyezett értékek közül való?
3. Hány erőforrás jön létre az alapértelmezett subnet map alapján?
4. Mi történik, ha hozzáadsz egy új subnet elemet a maphez?

## Végrehajtás

Csak a releváns parancsokat futtasd:

```bash
terraform validate
terraform plan
```

Ha szándékosan aktiválod a validációs hibát, csak az error megfigyelésére használd az érvénytelen értéket, majd állítsd vissza az érvényes értéket.

## Megfigyelés

Nézd meg a következőket:

- a validációs szabályt és az engedélyezett értékeket
- a `for_each` mapet és hogyan hoz létre példányokat
- a generált VNet neveket az `each.key` alapján
- a `merge()` eredményét a `tags` blokkben
- a tervet a map vagy változó érték módosítása előtt és után

## Magyarázat

Válaszolj ezekre a kérdésekre a validáció és a terv után:

1. Miért védi a validációs blokk a konfigurációt?
2. Miért hasznos a `for_each`, ha több subnet bejegyzésed van?
3. Hogyan segít az `each.key` a generált erőforrás példányok elnevezésében?
4. Mit csinál a `merge()` a címke mapben, és miért fontos ez?

## Sikerkritériumok

- [ ] Azonosítom a validációs szabályt.
- [ ] Tudom előre megjósolni az érvényes és érvénytelen bemenet hatását.
- [ ] Azonosítom a `for_each` által használt gyűjteményt.
- [ ] El tudom magyarázni, hogyan használják az `each.key` és `each.value` értékeket.
- [ ] El tudom magyarázni, mit csinál a `merge()` a címke blokknál.
- [ ] Tudom megjósolni a plán változását a map módosítása után.

## Takarítás

Ha szándékosan létrehoztál erőforrásokat Azure-ben, akkor tisztítsd meg őket ezzel:

```bash
terraform destroy
```

Ha a feladat csak diagnosztikai célból történik, ne alkalmazd a konfigurációt, kivéve ha az oktató kéri.
