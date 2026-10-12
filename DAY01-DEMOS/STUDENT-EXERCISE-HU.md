# Hallgatói gyakorlat - Terraform parancsok alapszintje

## Cél

Tanuld meg az alapvető Terraform munkafolyamatot a környezet biztonságos létrehozásához és eltávolításához:

- terraform init
- terraform validate
- terraform plan
- terraform apply
- terraform destroy

A fő gondolat az, hogy megértsd, hogyan működik együtt a konfiguráció, a plan, az apply és az állapot.

## Kiindulópont

Használd a demo mappájában létező Terraform konfigurációt:

- terraform-manifests/azure-resource-group.tf

Ez a demo egyszerű Azure erőforráscsoportot hoz létre. Nem a teljes oktatói megoldást másolod le. A meglévő konfiguráció átnézésével és egy kis módosítással dolgozol.

## Feladat

1. Nyisd meg a demo meglévő Terraform-fájlját, és nézd át az erőforrásblokkot.
2. Futtasd a szokásos Terraform munkafolyamatot sorban:
   - terraform init
   - terraform validate
   - terraform plan
   - terraform apply
3. Ellenőrizd, hogy megjelenik-e az Azure erőforráscsoport az Azure-ben.
4. Végezz el egy kis konfigurációmódosítást, például változtasd az erőforráscsoport nevét vagy helyét.
5. Futtasd újra a terraform plan parancsot, mielőtt alkalmaznád a módosítást.
6. Alkalmazd a módosítást, és nézd meg a kimenetet.
7. Futtasd a terraform destroy parancsot a takarításra.

## Mielőtt futtatnád a Terraformet

Válaszolj ezekre a kérdésekre a parancsok lefuttatása előtt:

- Mire számítasz a terraform plan eredményénél az első apply előtt?
- Melyik parancs az előnézeti lépés, és melyik végzi a tényleges Azure-módosítást?
- Ha megváltoztatod az erőforráscsoport nevét, azt várod, hogy a Terraform új erőforrást hoz létre, frissít egy meglévőt vagy semmit sem csinál?
- Mit gondolsz, mit követ nyomon az állapotfájl az apply után?

## Végrehajtás

Futtasd a következő parancsokat sorban:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

A módosítás után:

```bash
terraform plan
terraform apply
```

Ezután takarítsd rendbe a környezetet:

```bash
terraform destroy
```

## Megfigyelés

Ellenőrizd a következőket:

- A terraform plan által megjelenített kimenet az apply előtt
- Az erőforráscsoport neve és helye az Azure-ben az apply után
- Az, hogy a Terraform a konfiguráció módosítása után újabb tervezett változást jelez
- A resource eltávolítása a terraform destroy után

## Magyarázat

Válaszolj ezekre a kérdésekre a gyakorlat után:

- Miért hasznos a terraform plan átnézése az apply előtt?
- Mi a különbség a konfiguráció és az állapot között?
- Miért változott a terv az erőforráscsoport konfigurációjának módosítása után?
- Mit távolít el a terraform destroy az Azure-ből?

## Sikeres teljesítés feltételei

- [ ] A terraform init sikeresen lefut
- [ ] A terraform validate sikeresen lefut
- [ ] Átnéztem a tervet az alkalmazás előtt
- [ ] Tudom elmagyarázni a plan és az apply különbségét
- [ ] Tudom elmagyarázni, mit nyomon követ a Terraform az apply után
- [ ] Takarítható a resource a terraform destroy segítségével

## Takarítás

Miután befejezted, futtasd:

```bash
terraform destroy
```

Ha a munkakönyvtár még tartalmaz helyi Terraform-alkalmazásokat, csak a demo gyakorlat során létrehozott fájlokat távolítsd el, ha az oktató ezt kéri.
