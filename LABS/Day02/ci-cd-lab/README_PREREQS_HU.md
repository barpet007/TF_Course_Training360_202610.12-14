# Day 02 CI/CD Lab előfeltételei

Ez a lab egy megosztott Azure Storage backendet és egy Azure DevOps Service Connectiont használ, amelyet a Workload Identity Federation (WIF) alapú hitelesítés támogat. A javasolt elsődleges útvonal nem igényel hosszú életű client secretet.

## 1. A szükséges Azure-erőforrások provisionálása

A repository gyökeréből vagy a `ci-cd-lab/scripts` mappából futtasd a következő előkészítő szkriptet:

```powershell
pwsh ./scripts/create_azure_prereqs.ps1
```

Ez a konfiguráció mindkét erőforráscsoportot létre kell, hogy hozza:
- `tfstate-day2-rg` a megosztott Terraform remote backendhez
- `tf-day2-lab-rg` a lab telepítéséhez szükséges erőforrásokhoz

A szkript emellett a következőket is létrehozza:
- egy Storage Account a `tfstate-day2-rg` csoportban
- egy blob container a Terraform state tárolásához
- egy backend-kész állapot-helyet a `day2-lab.terraform.tfstate` fájlhoz

Ne a Terraform `-var` argumentumain keresztül add át a backend értékeket. A backendet a `terraform { backend "azurerm" {} }` beállítással inicializálod, és az értékeket a pipeline a `terraform init` során adja meg.

## 2. Az Azure DevOps projekt előfeltételei

Szükséged lesz egy Azure DevOps szervezetre, projektre, repositoryra és olyan hostolt agentre vagy hasonló környezetre, amely képes a Terraform feladatok futtatására.

## 3. Az Azure DevOps Service Connection beállítása

A Service Connection segítségével az Azure DevOps pipeline hitelesítetten érheti el az Azure-erőforrásokat.

Ehhez a laborhoz az Azure Resource Manager Service Connection és a Workload Identity Federation (WIF) kombinációját kell használnod.

A WIF lehetővé teszi, hogy az Azure DevOps ne tároljon hosszú életű client secretet a Service Connectionben.

> **Fontos**
>
> Ebben a laborban ne hozz létre és ne tárolj client secretet.
> A gyakorlat elsődleges hitelesítési módja a Workload Identity Federation.

### 3.1 OPEN SERVICE CONNECTIONS

A Service Connection létrehozásához a következő útvonalat kell követned az Azure DevOps portálon:

1. Nyisd meg a labhoz használt Azure DevOps projektet.
2. Kattints a következőre:

   `Project settings`

3. A `Pipelines` menü alatt válaszd a következőt:

   `Service connections`

4. Kattints a következő gombra:

   `New service connection`

5. Válaszd ki a következőt:

   `Azure Resource Manager`

6. Kattints a `Next` gombra.

Az Azure DevOps felület angol nyelvű lehet, ezért a felhasználói felület megfelelő menüpontjait az angol UI-label alapján kell azonosítanod.

### 3.2 SELECT AUTHENTICATION

A preferált lehetőség az Azure Resource Manager kapcsolat, amely a Workload Identity Federationet használja.

Ha a projektben elérhető, válaszd az automatikus WIF / automatikus app-registration opciót. Ez a legjobb megoldás új Azure Resource Manager Service Connectionokhoz.

A Microsoft ajánlása szerint az új Azure Resource Manager Service Connectionok esetén a Workload Identity Federation a javasolt megoldás.

Ne hozz létre client secretet. A cél az, hogy a pipeline az Azure DevOpsben ne tároljon hosszú életű titkos hitelesítő adatot.

Ha az UI pontos feliratai a verzióktól függően változnak, akkor a Service Connection létrehozásánál válaszd azt az Azure Resource Manager hitelesítési lehetőséget, amely kifejezetten a következőt használja:

`Workload Identity Federation`

### 3.3 SELECT AZURE SCOPE

A Service Connection létrehozásakor meg kell adnod vagy ellenőrizned a következő mezőket:

- `Subscription` (előfizetés)
- `Resource Group` (erőforráscsoport)
- `Service connection name` (Service Connection neve)

A gyakorlatban a Service Connection neve legyen pontosan:

`TF-SERVICE-CONNECTION`

A Service Connection identitásának később két különböző hatókörhöz kell hozzáférést kapnia:

- Backend: `tfstate-day2-rg`
- Deployment: `tf-day2-lab-rg`

A backend és a deployment céljai különböznek:

| Scope | Purpose |
|---|---|
| `tfstate-day2-rg` | Terraform backend |
| `tf-day2-lab-rg` | Lab deployment |

A backend hozzáférés és a Terraform deploymenthez szükséges hozzáférés külön jogosultsági feladat. A labben a két cél külön lépésben is kezelendő.

### 3.4 NAME THE CONNECTION

A Service Connection nevét pontosan így kell megadni:

`TF-SERVICE-CONNECTION`

Ez a név fontos, mert a pipeline YAML fájlja ezt a pontos nevet használja. Ne válassz másik nevet, kivéve ha szándékosan frissíted a pipeline YAML konfigurációját is.

### 3.5 PIPELINE AUTHORIZATION

A Service Connection létrehozása után a pipeline-nek képesnek kell lennie arra, hogy ezt a kapcsolatot használja.

Nyisd meg a következő menüpontokat az Azure DevOpsben:

`Project settings` > `Service connections` > `TF-SERVICE-CONNECTION`

Ezután ellenőrizd, hogy a projekt biztonsági szabályai szerint a pipeline megfelelően engedélyezett-e a Service Connection használatára.

A lab célja, hogy a pipeline különösen a konkrét lab pipeline számára legyen felhatalmazva, ne pedig korlátlan, általános hozzáférést kapjon.

### 3.6 AZURE RBAC

A Service Connection identitásának a lab által dokumentált jogosultságokat kell kapnia két külön célra.

#### Backend permissions

A Service Connection identitásának szüksége lesz a Terraform remote state Storage Account eléréséhez szükséges Azure jogosultságokra a következőben:

`tfstate-day2-rg`

Ez a hozzáférés azért szükséges, mert a Terraform a `terraform init` és a későbbi state-műveletek során el kell, hogy érje a tárolt állapotfájlt.

#### Deployment permissions

Ugyanezen identitásnak szüksége lesz a labhoz tartozó deployment jogosultságokra a következő erőforráscsoportban:

`tf-day2-lab-rg`

Ez lehetővé teszi, hogy a Terraform létrehozza és módosítsa a lab erőforrásait az adott Resource Groupben.

> **Fontos**
>
> A backendhez szükséges jogosultság és a Terraform által kezelt erőforrások telepítéséhez szükséges jogosultság két külön feladat.
> Attól, hogy a pipeline eléri a state-et, még nem biztos, hogy jogosult Azure-erőforrásokat létrehozni.

A labban nem adunk meg subscription-wide `Owner` jogosultságot. A megadott jogosultságok legyenek a lab által már jóváhagyott és dokumentált minimumra korlátozott hatókörök.

### 3.7 VERIFY THE CONNECTION

Ellenőrizd a következőket a befejezés előtt:

- [ ] `TF-SERVICE-CONNECTION` létrejött
- [ ] Azure Resource Manager kapcsolat
- [ ] Workload Identity Federation
- [ ] megfelelő Azure subscription
- [ ] pipeline authorization
- [ ] backend hozzáférés
- [ ] deployment hozzáférés

### 3.8 EXPLAIN WHAT HAPPENS

A pipeline futása során az Azure DevOps a Service Connectionen keresztül az Azure-erőforrásokhoz jut. A Service Connection az Azure Resource Manager hitelesítési módon keresztül a Workload Identity Federationet használja, mely a Microsoft Entra ID által kibocsátott identitásalapú hitelesítést használja.

Ez a művelet a következő folyamatot jelenti:

```text
Pipeline
   |
   v
TF-SERVICE-CONNECTION
   |
   v
Workload Identity Federation
   |
   v
Microsoft Entra ID
   |
   +--> Terraform backend
   |
   +--> tf-day2-lab-rg
```

Amikor a pipeline lefut, az Azure DevOps a Service Connectionen keresztül hitelesíti magát az Azure felé. Ezután a Terraform a remote backendhez fér hozzá a `tfstate-day2-rg` erőforráscsoportban, és ugyanakkor a lab erőforrásainak létrehozásához és módosításához a `tf-day2-lab-rg` erőforráscsoportban kap engedélyt.

A fontos tanulság: a backend hozzáférés és a deployment hozzáférés külön-külön konfigurálandó, külön jogosultsági hatókörökkel és külön célokkal.

## 4. A változócsoport létrehozása

Hozz létre egy `TF-SECRETS` nevű Azure DevOps változócsoportot, és add meg a backend értékeket:
- `ARM_BACKEND_RG` = `tfstate-day2-rg`
- `ARM_BACKEND_SA` = a megosztott backend Storage Account neve
- `ARM_BACKEND_CONTAINER` = a blob container neve
- `ARM_BACKEND_KEY` = `day2-lab.terraform.tfstate`

Fontos: az `ARM_BACKEND_KEY` a Terraform state kulcs, nem client secret. Nem ugyanaz, mint egy Azure hitelesítő adat.

## 5. A pipeline létrehozása

Add hozzá a repository tartalmát, majd hozz létre egy pipeline-t az `azure-pipelines.yml` alapján.

## 6. Biztonsági és biztonságos használati útmutató

- Soha ne tárolj valós hitelesítő adatokat a Git repositoryban.
- Ne commitold a `prereqs_output.json` fájlt, ha generált értékeket tartalmaz.
- A commit előtt előbb ellenőrizd a `git status` állapotot, és csak a ténylegesen commitolni kívánt fájlokat add hozzá.
- A lab során kerüld a széles körű `git add .` használatát.
- Ha a mintafájlokat a repo-ban meg kell tartani, azok csak placeholder értékeket tartalmazzanak.

## LEGACY ALTERNATIVE

Egy titkos alapú Azure service-principal flow csak akkor maradhat meg, ha egyértelműen megjelölt legacy alternativeként, régebbi környezetekhez. Ez nem a javasolt beállítás ebben a labban, és soha nem jelenhet meg az elsődleges útvonalként.
