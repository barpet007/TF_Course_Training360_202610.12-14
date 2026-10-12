# Hallgatói gyakorlat - Provider dependency lock file

## Cél

Tanuld meg, miért fontos a provider verziókorlátozása és a dependency lock file.

Ez a gyakorlat egy ellenőrzött hibaelhárítási forgatókönyvre összpontosít:

- provider verziókorlátozások
- .terraform.lock.hcl
- terraform init
- terraform init -upgrade
- provider kompatibilitás

A fő tanulság az, hogy a provider frissítése kompatibilitási változás, nem csak szoftverfrissítés.

## Kiindulópont

Használd a demo meglévő fájljait:

- terraform-manifests/c1-versions.tf
- terraform-manifests/c2-resource-group-storage-container.tf
- .terraform.lock.hcl-v1.44

Mielőtt módosítanál, ellenőrizd:

- az aktuális Azure provider korlátozását a c1-versions.tf fájlban
- a jelenlegi lock fájlt a munkakönyvtárban
- az erőforrásblokköt, amely a provider funkcióit használja, amelyet tesztelni fogsz

## Feladat

1. Nézd át a provider verziókorlátozását a Terraform konfigurációban.
2. Ellenőrizd a jelenlegi lock fájlt, és hasonlítsd össze a provider verzióinformációit a deklarált korlátozással.
3. Jósold meg, mi történhet, ha a provider verzióját újabb főverzióra módosítod.
4. Módosítsd az Azure provider verziókorlátozását a konfigurációban azokra az újabb verziós sorokra, amelyek a demo forgatókönyvéhez illenek.
5. Futtasd a terraform initet, majd a terraform plan parancsot.
6. Azonosítsd a kompatibilitási problémát.
7. Javítsd ki a problémát a demo által megkövetelt legkisebb valid módosítással.
8. Futtasd újra a terraform plan parancsot, hogy ellenőrizd, a konfiguráció érvényes-e.

## Mielőtt futtatnád a Terraformet

Válaszolj ezekre a kérdésekre a verziómódosítás előtt:

- Melyik verzió van jelenleg zárolva a konfigurációban és a lock fájlban?
- Mire számítasz, mi törhet el, ha az Azure provider verzióját frissíted?
- Miért fontos a lock fájl, ha a csapatok megosztják a Terraform-kódot?
- Ha egy erőforrás argumentuma eltűnik vagy megváltozik egy provider főverzióban, mit kell tennie a Terraformnek a plan futtatásakor?

## Végrehajtás

Először ellenőrizd az aktuális állapotot:

```bash
terraform init
```

Ha a demo a verziózott lock fájlból indul, használd a mappában elérhető előkészített verziófájlt a init előtt.

Ezután módosítsd a provider verzióját a demo forgatókönyvének megfelelően, és futtasd:

```bash
terraform init -upgrade
terraform plan
```

A probléma azonosítása után végezd el a demo utasításaiban szereplő minimális javítást, és futtasd:

```bash
terraform plan
```

## Megfigyelés

Ellenőrizd a következőket:

- a provider verziókorlátozását a c1-versions.tf fájlban
- a .terraform.lock.hcl tartalmát
- a terraform plan által kibocsátott hibát a provider frissítése után
- az adott argumentum vagy követelmény pontosét, amely már nem érvényes az újabb provider verzióban

## Magyarázat

Válaszolj ezekre a kérdésekre a gyakorlat után:

- Miért hibásodott meg a plan a provider verzióváltozás után?
- Miért fontos a lock fájl, még akkor is, ha a konfiguráció érvényes?
- Mit jelent ez a tényleges Terraform munkában a provider frissítései esetén?
- Miért nem egyszerű véletlen hiba ez a provider kompatibilitási kérdés?

## Sikeres teljesítés feltételei

- [ ] Megnéztem a meglévő provider korlátozást és a lock fájlt a módosítás előtt
- [ ] Előre megjósoltam egy kompatibilitási problémát a frissítés előtt
- [ ] Azonosítottam a hiba valódi okát a plan során
- [ ] Javítottam a konfigurációt a legkisebb, érvényes módosítással
- [ ] Tudom elmagyarázni, miért törhetnek el a provider frissítések a meglévő Terraform-kóddal

## Takarítás

Amikor az oktató szerint a gyakorlat véget ért:

```bash
terraform destroy
```

Ezután távolítsd el a generált Terraform munkafájlokat, ahogy a demo utasítja, anélkül, hogy eltörölnéd az eredeti demo fájlokat.
