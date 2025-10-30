# 📋 Cheat Sheet - Extract-Sections.ps1

Guide de référence rapide pour les commandes les plus courantes.

---

## 🚀 Commandes de base

### Extraction simple

```powershell
.\Extract-Sections.ps1 -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
```

### Avec sous-dossiers

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Recurse
```

### Mode strict (validation complète)

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Strict
```

### Logs détaillés (debug)

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Verbose
```

### Combinaison d'options

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -OutputCsv ".\export.csv" -Recurse -Strict -Verbose
```

---

## 🛠️ Utilitaires PowerShell

### Débloquer le script

```powershell
Unblock-File -Path .\Extract-Sections.ps1
```

### Bypass ExecutionPolicy

```powershell
PowerShell.exe -ExecutionPolicy Bypass -File .\Extract-Sections.ps1
```

### Vérifier version PowerShell

```powershell
$PSVersionTable.PSVersion
```

### Obtenir l'aide

```powershell
Get-Help .\Extract-Sections.ps1 -Full
Get-Help .\Extract-Sections.ps1 -Examples
```

---

## 📊 Analyse du CSV

### Importer le CSV

```powershell
$data = Import-Csv -Path ".\resultats.csv" -Encoding UTF8
```

### Afficher les colonnes

```powershell
$data[0] | Get-Member -MemberType NoteProperty | Select-Object Name
```

### Afficher une ligne

```powershell
$data[0] | Format-List
```

### Filtrer les résultats

```powershell
# Clients contenant "Acme"
$data | Where-Object { $_.Client -like "*Acme*" }

# Fichiers avec section Contexte non vide
$data | Where-Object { $_.'Contexte, problématique et enjeux' -ne "" }
```

### Exporter un sous-ensemble

```powershell
$data | Where-Object { $_.Client -like "*Tech*" } | Export-Csv ".\tech_only.csv" -NoTypeInformation
```

---

## 🔍 Inspection des fichiers

### Vérifier l'encodage

```powershell
# Lire avec UTF-8
Get-Content -Path ".\fichier.txt" -Encoding UTF8 -TotalCount 5

# Lire avec UTF-16
Get-Content -Path ".\fichier.txt" -Encoding Unicode -TotalCount 5
```

### Compter les fichiers

```powershell
# Dans un dossier
(Get-ChildItem -Path ".\mes_textes" -Filter "*.txt").Count

# Récursivement
(Get-ChildItem -Path ".\mes_textes" -Filter "*.txt" -Recurse).Count
```

### Lister les fichiers par taille

```powershell
Get-ChildItem -Path ".\mes_textes" -File | Sort-Object Length -Descending | Select-Object Name, @{N='Taille (Ko)';E={[math]::Round($_.Length/1KB,2)}}
```

---

## 🧪 Tests

### Lancer les tests

```powershell
.\Test-Extraction.ps1
```

### Avec logs verbeux

```powershell
.\Test-Extraction.ps1 -Verbose
```

### Mesurer le temps d'exécution

```powershell
Measure-Command { .\Extract-Sections.ps1 -InputFolder ".\mes_textes" }
```

---

## 🔄 Conversion d'encodage

### Fichier UTF-16 → UTF-8

```powershell
$content = Get-Content -Path ".\fichier_utf16.txt" -Encoding Unicode -Raw
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText(".\fichier_utf8.txt", $content, $utf8NoBom)
```

### Vérifier BOM d'un fichier

```powershell
$bytes = [System.IO.File]::ReadAllBytes(".\fichier.txt")
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Host "UTF-8 avec BOM"
} elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    Write-Host "UTF-16 LE"
} elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
    Write-Host "UTF-16 BE"
} else {
    Write-Host "Pas de BOM détecté"
}
```

---

## 📦 Création d'un exécutable

### Installer PS2EXE

```powershell
Install-Module -Name ps2exe -Scope CurrentUser
```

### Convertir en .exe

```powershell
ps2exe .\Extract-Sections.ps1 .\Extract-Sections.exe
```

### Avec options avancées

```powershell
ps2exe -inputFile .\Extract-Sections.ps1 `
       -outputFile .\Extract-Sections.exe `
       -title "Extract Sections" `
       -description "Extraction de sections texte vers CSV" `
       -version "2.0.0.0" `
       -noConsole:$false
```

---

## 🗂️ Organisation des fichiers

### Créer une structure

```powershell
# Dossiers par année
New-Item -ItemType Directory -Path ".\archives\2024" -Force
New-Item -ItemType Directory -Path ".\archives\2025" -Force

# Déplacer les fichiers
Move-Item -Path ".\mes_textes\*_2024_*.txt" -Destination ".\archives\2024\"
Move-Item -Path ".\mes_textes\*_2025_*.txt" -Destination ".\archives\2025\"
```

### Renommer en masse

```powershell
# Ajouter un préfixe
Get-ChildItem -Path ".\mes_textes" -Filter "*.txt" | Rename-Item -NewName {"mission_" + $_.Name}

# Remplacer un motif
Get-ChildItem -Path ".\mes_textes" -Filter "*.txt" | Rename-Item -NewName {$_.Name -replace "old", "new"}
```

---

## 📈 Performance

### Traiter par lots

```powershell
# Diviser les fichiers en dossiers de 100
$files = Get-ChildItem -Path ".\mes_textes" -Filter "*.txt"
$batchSize = 100
$batchNumber = 0

for ($i = 0; $i -lt $files.Count; $i += $batchSize) {
    $batchNumber++
    $batchFolder = ".\batch_$batchNumber"
    New-Item -ItemType Directory -Path $batchFolder -Force | Out-Null

    $files[$i..($i + $batchSize - 1)] | Copy-Item -Destination $batchFolder

    .\Extract-Sections.ps1 -InputFolder $batchFolder -OutputCsv ".\export_batch_$batchNumber.csv"
}
```

### Fusionner plusieurs CSV

```powershell
$csv1 = Import-Csv ".\export1.csv"
$csv2 = Import-Csv ".\export2.csv"
$csv3 = Import-Csv ".\export3.csv"

$combined = $csv1 + $csv2 + $csv3
$combined | Export-Csv ".\export_complet.csv" -NoTypeInformation
```

---

## 🔧 Automatisation

### Tâche planifiée (quotidienne à 8h)

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Scripts\Extract-Sections.ps1`" -InputFolder `"C:\Data\Input`" -OutputCsv `"C:\Data\Output\export.csv`""

$trigger = New-ScheduledTaskTrigger -Daily -At 8am

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "ExtractSections" -Description "Extraction quotidienne"
```

### Script wrapper avec notification

```powershell
# wrapper.ps1
try {
    .\Extract-Sections.ps1 -InputFolder ".\data" -OutputCsv ".\export.csv"

    if ($LASTEXITCODE -eq 0) {
        # Envoyer email de succès
        Send-MailMessage -To "admin@example.com" -Subject "✅ Extraction réussie" -Body "Le traitement est terminé."
    }
}
catch {
    # Envoyer email d'erreur
    Send-MailMessage -To "admin@example.com" -Subject "❌ Extraction échouée" -Body $_.Exception.Message
}
```

---

## 🐛 Débogage

### Capturer toute la sortie dans un log

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Verbose *> log.txt
```

### Afficher uniquement les erreurs

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" 2> errors.txt
```

### Mode interactif avec points d'arrêt

```powershell
# Dans le script, ajouter temporairement :
# Set-PSBreakpoint -Line 100 -Script .\Extract-Sections.ps1

# Exécuter en mode debug
powershell -NoExit -File .\Extract-Sections.ps1
```

---

## 📚 Ressources

- **Documentation complète** : [DOCUMENTATION.md](DOCUMENTATION.md)
- **Guide rapide** : [QUICKSTART.md](QUICKSTART.md)
- **Tests Windows** : [TESTING_WINDOWS.md](TESTING_WINDOWS.md)
- **Changelog** : [CHANGELOG.md](CHANGELOG.md)

---

**💡 Astuce** : Gardez ce cheat sheet sous la main pour référence rapide !
