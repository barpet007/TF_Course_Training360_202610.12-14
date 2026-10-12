# Hallgatói gyakorlat - Terraform provider és resource blokkok alapjai

## Cél

Tanuld meg a különbséget közöttük:

- Terraform CLI verziókorlátozása
- Terraform provider követelményei
- provider konfiguráció
- resource deklaráció

Ez a gyakorlat segít megérteni, hogy a Terraform, a provider és az erőforrás három különböző rész a konfigurációban.

## Kiindulópont

Használd a demo mappájában létező Terraform-fájlokat:

- sample-terraform-settings.tf
- terraform-manifests/c1-versions.tf
- terraform-manifests/c2-resource-group.tf

Nézd át a terraform blokket, a provider blokket és a resource blokket, mielőtt bármit futtatnál.

## Feladat

1. Olvasd el a demo terraform blokkját, és azonosítsd a Terraform verziókorlátozást.
2. Olvasd el a required_providers blokköt, és azonosítsd a provider forrását és a verziókorlátozást.
3. Keresd meg a provider blokköt, amely az Azure providert konfigurálja.
4. Keresd meg a resource blokköt, amely az Azure erőforráscsoport deklarációját tartalmazza.
5. Módosíts egy kis értéket a resource blokkban, például a név vagy a hely értékét.
6. Futtasd a terraform plan parancsot, és nézd meg, mit mond a Terraform.
7. Magyarázd el, hogy melyik rész felelős a Terraform CLI vezérléséért, melyik a providerhez tartozik, és melyik deklarálja az infrastruktúrát.

## Mielőtt futtatnád a Terraformet

Válaszolj ezekre a kérdésekre a Terraform használata előtt:

- Melyik korlátozás vonatkozik a Terraform CLI-re?
- Melyik korlátozás vonatkozik a provider verziójára?
- Melyik blokk konfigurálja az Azure providerét?
- Melyik blokk deklarálja a tényleges Azure erőforrást, amelyet létrehoznak?

## Végrehajtás

Futtasd a következő parancsokat:

```bash
terraform version
terraform init
terraform validate
terraform plan
```

Ha az oktató kéri a módosítás alkalmazását, használd:

```bash
terraform apply
```

A gyakorlat után takarítsd rendbe a környezetet:

```bash
terraform destroy
```

## Megfigyelés

Ellenőrizd a következőket a kimenetben:

- hogy a terraform version megfelel-e a required_version korlátozásnak
- hogy a Terraform a init során helyesen feloldja-e a providert
- hogy a plan megmutatja-e a várt erőforráscsoport-módosítást
- melyik blokk felelős a provider konfigurációjáért és melyik az erőforrás létrehozásáért

## Magyarázat

Válaszolj ezekre a kérdésekre a gyakorlat után:

- Miért különbözik a required_version a required_providers-től?
- Miért nem ugyanaz a provider blokk, mint a resource blokk?
- Mit csinál a resource blokk a Terraformben?
- Melyik blokk határozza meg a Terraform CLI verzióját, és melyik a provider verzióját?

## Sikeres teljesítés feltételei

- [ ] Meg tudom azonosítani a Terraform verziókorlátozást
- [ ] Meg tudom azonosítani a provider verziókorlátozást
- [ ] Meg tudom különböztetni a provider blokköt a resource blokktól
- [ ] Tudom elmagyarázni, mit jelentenek a terraform plan eredményei
- [ ] Le tudom írni a fő gondolatot a saját szavaimmal

## Takarítás

Amikor az oktató megmondja, hogy a gyakorlat befejeződött:

```bash
terraform destroy
```

Ne töröld az eredeti demo fájlokat. Csak a létrehozott infrastruktúrát távolítsd el, ha ezt az oktató kéri.
