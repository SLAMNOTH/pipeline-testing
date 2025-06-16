# Azure VM Deployment POC

## Overzicht

Deze repository bevat een eenvoudige **Proof-of-Concept (POC)** om met behulp van **Azure DevOps pipelines** en **Bicep** een minimale infrastructuur in Azure uit te rollen.

De POC is opgezet in opdracht van JUICT en maakt gebruik van de Visual Studio MPN-subscriptie. Hierdoor is gekozen voor een lichte en kostenbewuste implementatie.

---

## 🧱 Wat wordt uitgerold (via Bicep)

De Bicep-template (`main.bicep`) zet de volgende infrastructuur op:

- **Virtual Network (VNet)**  
  - Adresruimte: `10.0.0.0/16`  
  - Subnet: `10.0.0.0/24`

- **Public IP-adres**  
  - Dynamisch IP, gekoppeld aan de VM

- **Network Security Group (NSG)**  
  - Alleen poort **3389 (RDP)** toegestaan

- **Network Interface (NIC)**  
  - Verbindt de VM met subnet, NSG en public IP

- **Windows Virtual Machine**  
  - Naam: `win-vm`  
  - Grootte: `Standard_D2s_v5`  
  - OS: **Windows Server 2022 (Azure Edition)**  
  - Login: gebruikersnaam uit pipeline, wachtwoord als **secret variable**  
  - Automatische updates + Azure VM-agent zijn ingeschakeld

---

## 🧪 Doel van deze POC

- Valideren dat de Bicep-template correct werkt
- Aantonen dat Azure DevOps pipelines variabelen correct doorgeven
- Controleren of de VM **operationeel en publiek bereikbaar** wordt uitgerold

---

## 🔧 Pipeline-opbouw

De pipeline bestaat uit drie fasen:

### 🔹 1. Build

Valideert of de Bicep-code syntactisch correct is:

```bash
az bicep build --file $(templateFile)
```

---

### 🔹 2. Test (What-if)

Voert een "what-if deployment" uit om te zien wat Azure zou doen zonder echt te deployen:

```bash
az deployment group what-if \
  --resource-group $(resourceGroupName) \
  --template-file $(templateFile) \
  --parameters adminUsername="$(adminUN)" adminPassword="$(adminPASS)"
```

---

### 🔹 3. Deploy

Voert de daadwerkelijke deployment uit:

```bash
az group create --name $(resourceGroupName) --location $(location)

az deployment group create \
  --resource-group $(resourceGroupName) \
  --template-file $(templateFile) \
  --parameters adminUsername="$(adminUN)" adminPassword="$(adminPASS)"
```

Daarna wordt de status van de VM gecontroleerd:

```bash
az vm get-instance-view \
  --name win-vm \
  --resource-group $(resourceGroupName) \
  --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" \
  -o tsv
```

Als de status niet `VM running` is, faalt de pipeline.

---

## 🔐 Beveiliging

- De **gebruikersnaam** van de VM staat in de pipeline als gewone variabele (`adminUN`)
- Het **wachtwoord** wordt opgeslagen als **secret variable** (`adminPASS`)
- In een toekomstige versie (POC2) wordt gebruik gemaakt van **Azure Key Vault** voor veilige geheimenbeheer

---

## 📁 Bestanden in deze repo

| Bestand                        | Omschrijving                                     |
|-------------------------------|--------------------------------------------------|
| `main.bicep`                  | Bicep-template die de infrastructuur uitrolt     |
| `.azure-pipelines.yml`       | Azure DevOps pipeline-definitie                  |
| `README.md`                  | Documentatie van deze POC                        |

---

## 📌 Let op

Deze POC is **niet bedoeld voor productie**, maar puur om aan te tonen dat de keten (Bicep + Pipeline + Azure) correct werkt.
