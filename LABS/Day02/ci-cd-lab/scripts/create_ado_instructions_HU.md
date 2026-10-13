# Azure DevOps konfiguráció a Day 02 CI/CD laborhoz

Ez az útmutató a labor által javasolt Azure DevOps beállítását ismerteti egy megosztott Azure Storage backend és egy Workload Identity Federation (WIF) alapú Service Connection használatával. Ez az elsődleges útvonal a kurzus laborjához.

## 1. Előfeltételek

Mielőtt hozzákezdesz, ellenőrizd, hogy rendelkezésedre áll:

- Azure DevOps szervezet
- Azure DevOps projekt
- a laborfájlokat tartalmazó repository
- egy hosted agent vagy ehhez hasonló végrehajtási környezet
- hozzáférés az Azure DevOps Terraform pipeline feladatokhoz
- jogosultság Service Connection létrehozására és engedélyezésére
- jogosultság variable group létrehozására és konfigurálására
- egy `production` nevű Azure DevOps Environment, amelyhez approval van konfigurálva

## 2. Azure platform előfeltételei

Hozd létre a szükséges Azure erőforrásokat a pipeline futása előtt:

- backend resource group: `tfstate-day2-rg`
- deployment resource group: `tf-day2-lab-rg`
- Storage Account a backend resource groupben
- blob container a távoli Terraform state tárolásához

Használd ugyanazokat a backend értékeket a pipeline-ben és a dokumentációban is.

## 3. Azure DevOps Service Connection

Az Azure DevOpsben hozz létre egy új Azure Resource Manager Service Connection-t a következő névvel:

```text
TF-SERVICE-CONNECTION
```

Használd az ajánlott hitelesítési modellt:

- Azure Resource Manager Service Connection
- Workload Identity Federation
- nincs szükség hosszú életű client secretre

Az identitásnak szüksége lesz:

- Storage data-plane jogosultságra a backend Storage Accounthez a `tfstate-day2-rg` resource groupben
- deployment jogosultságokra a `tf-day2-lab-rg` resource groupben
- pipeline-engedélyezésre a Service Connection használatához

Ez a labor elsődleges beállítási útvonala.

### Azure DevOps navigáció

Nyisd meg az Azure DevOps Projectet, majd menj végig ezen az útvonalon:

```text
Azure DevOps Project
>
Project settings
>
Pipelines
>
Service connections
>
New service connection
>
Azure Resource Manager
```

A Service Connection létrehozásakor válaszd ki a `Workload Identity Federation` hitelesítési lehetőséget. Ennek célja, hogy a pipeline az Azure DevOpsből biztonságosan tudjon hitelesíteni Azure felé anélkül, hogy hosszú életű titkos kulcsot vagy client secretet kellene a repositoryban vagy az elsődleges labor konfigurációjában tárolni.

Ez az a megoldás, amelyet a lab a fő útvonalként használ. A pipeline az Azure-ban futó Azure Resource Manager Service Connectionen keresztül fog hitelesíteni, és a környezet a WIF-hez kapcsolódó identitás alapján kap engedélyt.

### Régi/legacy alternatíva

Egy secret-alapú Azure service principal megoldás csak jól jelölt legacy alternatívaként tartható meg régebbi környezetekhez. Ez nem a javasolt lab-útvonal, és nem ajánlott alapértelmezett beállításként.

## 4. Variable group létrehozása

Hozz létre egy `TF-SECRETS` nevű Azure DevOps variable groupet, és add hozzá ezeket az értékeket:

- `ARM_BACKEND_RG` = `tfstate-day2-rg`
- `ARM_BACKEND_SA` = a backend Storage Account neve
- `ARM_BACKEND_CONTAINER` = a blob container neve
- `ARM_BACKEND_KEY` = `day2-lab.terraform.tfstate`

Ne kezelje az `ARM_BACKEND_KEY` változót secretként vagy client credentialként. Ez a távoli state kulcsa, nem hitelesítő adatok.

## 5. Azure DevOps Environment approval

Konfiguráld a `production` nevű Azure DevOps Environmentet a szükséges approvallel.

Fontos: az approvalt az Azure DevOpsben lévő Environmenten kell konfigurálni, nem egy YAML megjegyzésben. A környezet approval kapu szabályozza az apply szakaszt.

A `CD_APPLY` szakasz továbbra is a sikeres `CI_SCAN_PLAN` szakasztól és az environment approvaltől függjön.

## 6. A repository feltöltése és a pipeline létrehozása

- commitold a laborfájlokat
- pushold a repositoryba
- hozz létre egy pipeline-t az `azure-pipelines.yml` fájlból

A laborban használd a kifejezett staginget a `git add .` helyett.

```bash
git status
git add main.tf azure-pipelines.yml modules/simple_storage/main.tf
git commit -m "Remediate storage TLS"
git push origin main
```

## 7. Biztonsági megjegyzések

- soha ne tárolj valódi Azure vagy Git hitelesítő adatokat a source controlban
- ne commitold a `prereqs_output.json` fájlt, ha generált értékeket tartalmaz
- ha muszáj a repo-ban tartani, akkor csak helyőrző adatokkal készült minta kimenetet tarts benne
- ne használj reálisnak tűnő `clientSecret` értéket mintaadatokhoz

> **Fontos**
>
> Ne tárolj valódi Azure credentialt, client secretet vagy más érzékeny adatot a repositoryban.

## 8. Végső ellenőrzőlista

A labor futtatása előtt ellenőrizd:

- a Service Connection neve `TF-SERVICE-CONNECTION`
- a hitelesítési modell WIF
- a backend state key `day2-lab.terraform.tfstate`
- a backend resource group `tfstate-day2-rg`
- a deployment resource group `tf-day2-lab-rg`
- a Checkov szabály `CKV_AZURE_44`
- az environment approval be van konfigurálva a `production` Environmentben
- a pipeline apply lépése továbbra is a CI sikerén és az approvalen keresztül van védve

## 9. Azure scope és RBAC

A labor különböző Azure jogosultsági igényeket különít el:

| Azure scope | Cél |
|---|---|
| `tfstate-day2-rg` | Terraform remote backend |
| `tf-day2-lab-rg` | Terraform labor deployment |

Ezek két különálló engedélykövetelmény:

- a backend hozzáférés szükséges a Terraform state műveletekhez
- a deployment jogosultságok szükségesek az által a Terraform által kezelt erőforrásokhoz

Ez a kialakítás a legkisebb jogkör elvét követi, és nem ír elő subscription-szintű `Owner` jogosultságot.

## 10. Pipeline engedélyezés

A `TF-SERVICE-CONNECTION` létrehozása önmagában nem elegendő. A labor pipeline-je számára a Service Connection használatát az Azure DevOps projekt biztonsági modellje szerint is engedélyezni kell.

A preferált megközelítés az, hogy a labor pipeline-jét engedélyezzük a Service Connection használatára, nem pedig általános, korlátozás nélküli hozzáférést adjunk meg. Ne találj ki szervezeti-specifikus jogosultsági beállításokat.

## 11. Git biztonság és ellenőrzés

A kód módosításai előtt mindig ellenőrizd a repository állapotát:

```bash
git status
```

Mielőtt commitet hozol létre, nézd át a stage-elt fájlokat, és csak azokat add hozzá, amelyeket tényleg szeretnél benne hagyni. Ez megakadályozza, hogy véletlenül elküldj olyan fájlokat, amelyek nem tartoznak a laborhoz, vagy érzékeny adatokat tartalmaznak.

Ne használd a `git add .` parancsot a labor során. A cél az, hogy a hallgatók tudatosan válasszák ki a hozzáadandó fájlokat, és a commit előtt ellenőrizzék, hogy a staged változások helyesek-e.

## Ellenőrzőlista a pipeline indítása előtt

- [ ] `tfstate-day2-rg` létezik
- [ ] `tf-day2-lab-rg` létezik
- [ ] `TF-SERVICE-CONNECTION` létrejött
- [ ] Workload Identity Federation van használatban
- [ ] A Service Connection a megfelelő Azure subscriptionre mutat
- [ ] A backendhez szükséges jogosultságok be vannak állítva
- [ ] A deploymenthez szükséges jogosultságok be vannak állítva
- [ ] `TF-SECRETS` létrejött
- [ ] A backend változók szerepelnek a variable groupban
- [ ] `production` Azure DevOps Environment létrejött
- [ ] A `production` Environment approval be van állítva
- [ ] A pipeline használhatja a `TF-SERVICE-CONNECTION` kapcsolatot
- [ ] `git status` alapján nincs credential vagy nem kívánt fájl staged állapotban
