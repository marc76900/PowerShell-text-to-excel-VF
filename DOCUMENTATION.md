# 📄 Extract-Sections.ps1 - Documentation Complète

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Fonctionnalités](#fonctionnalités)
3. [Prérequis](#prérequis)
4. [Installation](#installation)
5. [Utilisation](#utilisation)
6. [Tests et validation](#tests-et-validation)
7. [Encodages supportés](#encodages-supportés)
8. [Cas d'usage avancés](#cas-dusage-avancés)
9. [Création d'un exécutable](#création-dun-exécutable)
10. [Dépannage](#dépannage)
11. [Limitations connues](#limitations-connues)

---

## 🎯 Vue d'ensemble

**Extract-Sections.ps1** est un script PowerShell robuste conçu pour extraire des sections structurées de fichiers texte (`.txt`, `.md`) et les exporter vers un fichier CSV UTF-8.

### Cas d'usage typiques

- Extraction de données de propositions commerciales
- Parsing de documents structurés (missions, projets, contrats)
- Consolidation d'informations dispersées dans de nombreux fichiers
- Préparation de données pour analyse ou reporting

### Sortie

Un fichier CSV avec les colonnes suivantes :

| # | Colonne | Description |
|---|---------|-------------|
| 1 | **Fichier** | Nom du fichier source |
| 2 | **Chemin** | Chemin complet du fichier |
| 3 | **Client** | Nom du client (ligne 1 ou étiquette explicite) |
| 4 | **Objet** | Objet de la mission (lignes 2-4 ou étiquette) |
| 5 | **Contexte, problématique et enjeux** | Section complète |
| 6 | **Valeur ajoutée et différenciation** | Section complète |
| 7 | **Contact(s)** | Section complète |
| 8 | **Période** | Section complète |
| 9 | **Honoraires** | Section complète |
| 10 | **Contenu, résultats et livrables** | Section complète |

---

## ✨ Fonctionnalités

### 🔍 Détection robuste des titres

Le script gère automatiquement :

- **Variantes d'accents** : `é`, `è`, `e`, `ê`, etc.
- **Espaces variables** : espaces simples, multiples, insécables
- **Bullets et numérotation** : `•`, `-`, `▪`, `1.`, `2)`, etc.
- **Variantes orthographiques** :
  - `Valeur ajoutée et différenciation` ⇄ `Valeur ajoutée & différenciation`
  - `Contact(s)` ⇄ `Contacts` ⇄ `Contact`
  - `Période` ⇄ `Periode`
  - `Contexte, problematique...` (sans accents)
- **Contenu inline** : le texte après `:` sur la même ligne que le titre est inclus

### 📝 Exemples de titres reconnus

Tous ces variants sont détectés correctement :

```text
Contexte, problématique et enjeux:
• Contexte, problematique et enjeux
1. Contexte, problématique et enjeux : Voici le contexte...
▪ Contexte, problématique et enjeux

Valeur ajoutée et différenciation:
Valeur ajoutée & différenciation : Notre expertise unique...
2) Valeur ajoutee et differenciation

Contact(s):
Contacts :
- Contact : Jean Dupont - jean@example.com

Période : Janvier - Juin 2025
Periode: Q1 2025

Honoraires: 150 000 € HT
• Honoraires : Budget global de 200K€

Contenu, résultats et livrables:
→ Contenu, résultats et livrables : Liste des livrables...
```

### 🔧 Extraction intelligente Client/Objet

#### Stratégie 1 : Étiquettes explicites (prioritaire)

Recherche dans les **10 premières lignes** :

```text
Client: Acme Corporation
Objet: Mission de transformation digitale
```

Étiquettes reconnues :
- **Client** : `Client:`, `Destinataire:`, `Société:`, `Entreprise:`
- **Objet** : `Objet:`, `Objet de la mission:`, `Mission:`, `Sujet:`

#### Stratégie 2 : Heuristique (si étiquettes absentes)

- **Client** = 1ère ligne non vide
- **Objet** = lignes 2-4 non vides, concaténées, jusqu'à rencontrer un mot-clé de section

Exemple :

```text
TechStart Solutions
Développement d'une application mobile
pour la gestion de projets collaboratifs

Contexte, problématique et enjeux:
...
```

→ Client : `TechStart Solutions`
→ Objet : `Développement d'une application mobile pour la gestion de projets collaboratifs`

### 🌍 Gestion multi-encodage

Détection automatique et lecture correcte des fichiers :

| Encodage | BOM | Support |
|----------|-----|---------|
| UTF-16 LE | `FF FE` | ✅ Détection automatique |
| UTF-16 BE | `FE FF` | ✅ Détection automatique |
| UTF-8 | `EF BB BF` | ✅ Détection automatique |
| UTF-8 sans BOM | aucun | ✅ Fallback |
| Windows-1252 (ANSI) | aucun | ✅ Tentative Get-Content |

### 🧹 Normalisation du texte

- Uniformisation des retours à la ligne (`\r\n` → `\n`)
- Conversion des espaces spéciaux (insécables, fines, etc.) → espace normal
- Normalisation des tirets (`—`, `–`, `•` → `-`)
- Nettoyage des guillemets (`«»`, `""` → `"`)
- Préservation des **sauts de ligne internes** dans les blocs

---

## 🔧 Prérequis

### Système

- **OS** : Windows 7+ / Windows Server 2012+
- **PowerShell** : Version 5.1 minimum (compatible PowerShell 7+)
- **Droits** : Aucun droit administrateur requis

### Vérifier votre version PowerShell

```powershell
$PSVersionTable.PSVersion
```

Sortie attendue :

```text
Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      ...    ...
```

---

## 📦 Installation

### Option 1 : Téléchargement direct

1. Téléchargez `Extract-Sections.ps1`
2. Placez-le dans un dossier accessible (ex: `C:\Scripts\`)

### Option 2 : Clonage du dépôt

```bash
git clone https://github.com/votre-repo/PowerShell-text-to-excel-VF.git
cd PowerShell-text-to-excel-VF
```

### Débloquer le script (si nécessaire)

Si vous avez téléchargé le script depuis Internet :

```powershell
Unblock-File -Path .\Extract-Sections.ps1
```

---

## 🚀 Utilisation

### Syntaxe de base

```powershell
.\Extract-Sections.ps1 -InputFolder <dossier> -OutputCsv <fichier.csv> [-Recurse] [-Strict] [-Verbose]
```

### Paramètres

| Paramètre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| `-InputFolder` | String | Non | Dossier contenant les fichiers `.txt`/`.md` (défaut: `.\mes_textes`) |
| `-OutputCsv` | String | Non | Chemin du CSV de sortie (défaut: `.\sections.csv`) |
| `-Recurse` | Switch | Non | Parcourt les sous-dossiers récursivement |
| `-Strict` | Switch | Non | Mode strict : échoue si des sections sont manquantes |
| `-Verbose` | Switch | Non | Affiche des logs détaillés pour le débogage |

### Exemples d'utilisation

#### Exemple 1 : Usage basique

```powershell
.\Extract-Sections.ps1 -InputFolder "C:\Docs\Missions" -OutputCsv "C:\Output\missions.csv"
```

#### Exemple 2 : Avec sous-dossiers

```powershell
.\Extract-Sections.ps1 -InputFolder ".\documents" -OutputCsv ".\resultats.csv" -Recurse
```

#### Exemple 3 : Mode strict + logs détaillés

```powershell
.\Extract-Sections.ps1 -InputFolder ".\propositions" -Strict -Verbose
```

En mode strict, le script **échouera** si une des 6 sections requises est manquante dans un fichier.

#### Exemple 4 : Chemin relatif

```powershell
.\Extract-Sections.ps1
# Utilise les valeurs par défaut :
#   -InputFolder ".\mes_textes"
#   -OutputCsv ".\sections.csv"
```

### Résultat

```text
2025-10-30 14:23:15 [i] === Extraction de sections vers CSV ===
2025-10-30 14:23:15 [i] Dossier source : .\mes_textes
2025-10-30 14:23:15 [i] Fichier de sortie : .\sections.csv
2025-10-30 14:23:15 [✓] Fichiers trouvés : 5

2025-10-30 14:23:16 [i] [1/5] Traitement : mission_acme.txt (20.0%)
2025-10-30 14:23:16 [✓]   ✓ Succès

2025-10-30 14:23:17 [i] [2/5] Traitement : projet_techstart.txt (40.0%)
2025-10-30 14:23:17 [✓]   ✓ Succès

...

2025-10-30 14:23:20 [i] === Résumé ===
2025-10-30 14:23:20 [✓] Fichiers traités avec succès : 5

2025-10-30 14:23:20 [i] Export vers : .\sections.csv

2025-10-30 14:23:20 [✓] ✓ EXPORT TERMINÉ
2025-10-30 14:23:20 [✓]   Fichier : .\sections.csv
2025-10-30 14:23:20 [✓]   Taille : 42.56 Ko
2025-10-30 14:23:20 [✓]   Lignes : 5
```

---

## ✅ Tests et validation

Un script de test complet est fourni : **`Test-Extraction.ps1`**

### Exécution des tests

```powershell
.\Test-Extraction.ps1
```

Avec logs détaillés :

```powershell
.\Test-Extraction.ps1 -Verbose
```

### Ce qui est testé

Le script de test valide :

1. ✅ Présence du script principal et des fichiers de test
2. ✅ Exécution sans erreur
3. ✅ Création du fichier CSV avec toutes les colonnes
4. ✅ Extraction correcte du Client et de l'Objet
5. ✅ Extraction complète de chaque section (inline + multi-lignes)
6. ✅ Détection des variantes de titres (accents, &, bullets)
7. ✅ Gestion du contenu inline après `:`
8. ✅ Comportement du mode strict (échec attendu sur fichier incomplet)

### Résultat attendu

```text
================================================================================
 RÉSUMÉ DES TESTS
================================================================================

  Tests exécutés  : 42
  Tests réussis   : 42
  Tests échoués   : 0

  Taux de succès  : 100.0%

================================================================================

✓ TOUS LES TESTS SONT PASSÉS !
```

### Fichiers de test fournis

| Fichier | Description |
|---------|-------------|
| `test01_complet.txt` | Fichier parfait avec toutes les sections |
| `test02_variantes.txt` | Variantes d'orthographe (accents, &, bullets) |
| `test03_inline.txt` | Contenu inline après `:` sur la ligne du titre |
| `test04_utf16.txt` | Test d'encodage UTF-16 |
| `test05_incomplet.md` | Fichier avec section manquante (test mode strict) |

---

## 🌐 Encodages supportés

### Détection automatique

Le script essaie dans l'ordre :

1. **Détection du BOM** (Byte Order Mark)
   - UTF-16 LE : `FF FE`
   - UTF-16 BE : `FE FF`
   - UTF-8 : `EF BB BF`

2. **Essais avec Get-Content** (si pas de BOM)
   - UTF-8
   - UTF-16 LE
   - UTF-16 BE
   - Windows-1252 (ANSI)

3. **Fallback UTF-8** (dernier recours)

### Vérifier l'encodage d'un fichier

**Windows** :

```powershell
# PowerShell
Get-Content .\fichier.txt -Encoding UTF8 -TotalCount 1

# Notepad++
Menu → Encodage → Affiche l'encodage actuel
```

**Linux/Mac** :

```bash
file -i fichier.txt
```

### Convertir un fichier vers UTF-8

```powershell
# Lire en UTF-16
$content = Get-Content -Path .\fichier_utf16.txt -Encoding Unicode -Raw

# Écrire en UTF-8 (sans BOM)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText(".\fichier_utf8.txt", $content, $utf8NoBom)
```

---

## 🎓 Cas d'usage avancés

### 1. Traiter un grand volume de fichiers

Pour des dossiers avec 100+ fichiers :

```powershell
# Activer la récursion et désactiver les logs verbeux
.\Extract-Sections.ps1 -InputFolder "\\serveur\partage\documents" -OutputCsv ".\export_complet.csv" -Recurse
```

### 2. Filtrer les fichiers à traiter

Si vous souhaitez traiter seulement certains fichiers :

```powershell
# Copier les fichiers souhaités dans un dossier temporaire
$tempFolder = ".\temp_selection"
New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null

Get-ChildItem ".\tous_les_fichiers" -Filter "*_2025_*.txt" | Copy-Item -Destination $tempFolder

# Traiter
.\Extract-Sections.ps1 -InputFolder $tempFolder -OutputCsv ".\selection_2025.csv"

# Nettoyer
Remove-Item -Path $tempFolder -Recurse -Force
```

### 3. Intégration dans un pipeline

```powershell
# Pipeline complet
.\Extract-Sections.ps1 -InputFolder ".\raw_data" -OutputCsv ".\export.csv"

if ($LASTEXITCODE -eq 0) {
    # Importer et traiter le CSV
    $data = Import-Csv -Path ".\export.csv" -Encoding UTF8

    # Filtrer, transformer, analyser...
    $data | Where-Object { $_.'Client' -like "*Acme*" } | Export-Csv ".\acme_only.csv" -NoTypeInformation

    Write-Host "✓ Pipeline terminé avec succès"
} else {
    Write-Host "✗ Erreur lors de l'extraction" -ForegroundColor Red
}
```

### 4. Automatisation avec tâche planifiée

```powershell
# Créer une tâche planifiée Windows (exécution quotidienne à 8h)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Scripts\Extract-Sections.ps1`" -InputFolder `"C:\Data\Input`" -OutputCsv `"C:\Data\Output\export.csv`""

$trigger = New-ScheduledTaskTrigger -Daily -At 8am

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "ExtractSections" -Description "Extraction quotidienne des sections"
```

---

## 📦 Création d'un exécutable

Dans les environnements où l'exécution de scripts `.ps1` est bloquée, vous pouvez créer un fichier `.exe`.

### Méthode 1 : Utiliser PS2EXE (recommandé)

**PS2EXE** convertit un script PowerShell en exécutable Windows.

#### Installation

```powershell
# Installer le module (nécessite droits admin)
Install-Module -Name ps2exe -Scope CurrentUser

# OU télécharger depuis GitHub (pas de droits admin)
# https://github.com/MScholtes/PS2EXE
```

#### Conversion

```powershell
# Basique
ps2exe .\Extract-Sections.ps1 .\Extract-Sections.exe

# Avec options avancées
ps2exe `
    -inputFile .\Extract-Sections.ps1 `
    -outputFile .\Extract-Sections.exe `
    -noConsole:$false `
    -title "Extract Sections" `
    -description "Extraction de sections texte vers CSV" `
    -company "Votre Société" `
    -version "2.0.0.0" `
    -iconFile .\icon.ico
```

#### Utilisation de l'EXE

```cmd
REM Identique à l'appel PowerShell, mais en .exe
Extract-Sections.exe -InputFolder "C:\Docs" -OutputCsv "C:\Output\result.csv"
```

### Méthode 2 : Wrapper batch (.bat)

Créez un fichier `Extract-Sections.bat` :

```batch
@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Extract-Sections.ps1" %*
```

Usage :

```cmd
Extract-Sections.bat -InputFolder ".\docs" -OutputCsv ".\result.csv"
```

### Méthode 3 : Encodage en Base64 (pour bypass ExecutionPolicy)

```powershell
# Encoder le script
$scriptContent = Get-Content -Path .\Extract-Sections.ps1 -Raw
$bytes = [System.Text.Encoding]::Unicode.GetBytes($scriptContent)
$encodedCommand = [Convert]::ToBase64String($bytes)

# Exécuter sans fichier .ps1
PowerShell.exe -NoProfile -EncodedCommand $encodedCommand
```

⚠️ Cette méthode a des limitations (taille max de la commande).

---

## 🔍 Dépannage

### Problème : "Impossible de charger le fichier car l'exécution de scripts est désactivée"

**Erreur complète** :

```text
.\Extract-Sections.ps1 : Impossible de charger le fichier ... car l'exécution de scripts est désactivée sur ce système.
```

**Solutions** :

1. **Débloquer le script** (si téléchargé depuis Internet) :

   ```powershell
   Unblock-File -Path .\Extract-Sections.ps1
   ```

2. **Modifier la stratégie d'exécution** (temporaire) :

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\Extract-Sections.ps1
   ```

3. **Utiliser l'option `-ExecutionPolicy Bypass`** :

   ```powershell
   PowerShell.exe -ExecutionPolicy Bypass -File .\Extract-Sections.ps1
   ```

### Problème : Caractères illisibles dans le CSV (mojibake)

**Exemple** : `Activit\u00e9` au lieu de `Activité`

**Causes** :
- Fichier d'entrée mal encodé
- CSV ouvert avec le mauvais encodage

**Solutions** :

1. **Vérifier l'encodage du fichier source** :

   ```powershell
   # Tester plusieurs encodages
   Get-Content -Path .\fichier.txt -Encoding UTF8 -TotalCount 5
   Get-Content -Path .\fichier.txt -Encoding Unicode -TotalCount 5
   ```

2. **Ouvrir le CSV avec Excel en forçant UTF-8** :
   - Excel → Données → Obtenir des données → À partir d'un fichier texte/CSV
   - Sélectionner `65001 : Unicode (UTF-8)` comme encodage

3. **Ouvrir avec LibreOffice Calc** (meilleure gestion UTF-8) :
   - LibreOffice détecte automatiquement UTF-8

### Problème : Certaines sections sont vides alors qu'elles existent

**Causes possibles** :
- Variante du titre non reconnue
- Espaces ou caractères invisibles dans le titre

**Diagnostic** :

Exécuter avec `-Verbose` :

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Verbose
```

Rechercher dans les logs :

```text
VERBOSE: Trouvé 'Contexte, problématique et enjeux' à la ligne 5 (pos 123)
VERBOSE: Trouvé 'Valeur ajoutée et différenciation' à la ligne 12 (pos 456)
```

Si un titre n'apparaît pas, c'est qu'il n'est pas reconnu.

**Solution** :

Examiner manuellement le fichier et ajuster le titre pour qu'il corresponde à l'une des formes attendues.

### Problème : Mode strict échoue sur tous les fichiers

**Message d'erreur** :

```text
ERREUR (Strict) : Sections manquantes : 'Contact(s)', 'Période'
```

**Cause** : Le mode strict exige que **toutes** les 6 sections soient présentes.

**Solutions** :

1. **Ajouter les sections manquantes** dans vos fichiers
2. **Désactiver le mode strict** (par défaut) :

   ```powershell
   .\Extract-Sections.ps1 -InputFolder ".\docs"
   # Pas de -Strict
   ```

### Problème : Performance lente sur gros volumes

**Si le traitement est trop lent** :

1. **Désactiver les logs verbeux** (ne pas utiliser `-Verbose`)
2. **Traiter par lots** :

   ```powershell
   # Diviser les fichiers en plusieurs dossiers
   .\Extract-Sections.ps1 -InputFolder ".\batch1"
   .\Extract-Sections.ps1 -InputFolder ".\batch2"

   # Fusionner les CSV
   $csv1 = Import-Csv ".\output1.csv"
   $csv2 = Import-Csv ".\output2.csv"
   $csv1 + $csv2 | Export-Csv ".\combined.csv" -NoTypeInformation
   ```

---

## ⚠️ Limitations connues

### 1. Sections imbriquées

Le script détecte uniquement les **titres de niveau 1**. Si un fichier contient des sous-sections, elles ne seront pas extraites séparément.

**Exemple** :

```text
Contexte, problématique et enjeux:
Texte principal...

  1.1 Sous-contexte A
  Texte A...

  1.2 Sous-contexte B
  Texte B...

Valeur ajoutée et différenciation:
...
```

→ Tout le contenu entre "Contexte..." et "Valeur ajoutée..." sera extrait en un seul bloc.

### 2. Titres en double

Si un titre apparaît plusieurs fois, **seul le dernier** sera conservé.

**Exemple** :

```text
Période : Phase 1

... texte ...

Période : Phase 2
```

→ La colonne "Période" contiendra uniquement "Phase 2".

### 3. Taille des fichiers

Le script charge chaque fichier **entièrement en mémoire**. Pour des fichiers > 10 Mo, des ralentissements peuvent survenir.

### 4. CSV : Sauts de ligne dans les cellules

Les sauts de ligne internes sont **préservés** dans le CSV (entourés de guillemets selon la norme RFC 4180).

**Exemple dans Excel** :

| Client | Contexte |
|--------|----------|
| Acme | "Problème A`<br>`Problème B" |

Les sauts de ligne sont visibles en mode édition de cellule (Alt+Entrée dans Excel).

### 5. Compatibilité PS5 vs PS7

Le script est compatible **PowerShell 5.1 et 7+**, mais :

- **PowerShell 7** : Meilleure performance sur gros volumes
- **PowerShell 5.1** : Préinstallé sur Windows (plus pratique en entreprise)

---

## 📞 Support et contribution

### Problèmes connus

Consultez la section [Issues](https://github.com/votre-repo/issues) pour signaler un bug ou demander une fonctionnalité.

### Contributions

Les pull requests sont les bienvenues ! Pour des changements majeurs, ouvrez d'abord une issue pour discuter de ce que vous souhaitez modifier.

---

## 📜 Licence

Ce script est fourni "tel quel", sans garantie d'aucune sorte.

---

## 📚 Annexes

### Commandes utiles

```powershell
# Afficher l'aide intégrée
Get-Help .\Extract-Sections.ps1 -Full

# Lister les paramètres disponibles
Get-Help .\Extract-Sections.ps1 -Parameter *

# Exemples d'utilisation
Get-Help .\Extract-Sections.ps1 -Examples
```

### Structure des fichiers du projet

```
PowerShell-text-to-excel-VF/
│
├── Extract-Sections.ps1          # Script principal
├── Test-Extraction.ps1            # Script de tests
├── DOCUMENTATION.md               # Ce fichier
├── README.md                      # Vue d'ensemble rapide
│
└── mes_textes/                    # Dossier de test
    ├── test01_complet.txt
    ├── test02_variantes.txt
    ├── test03_inline.txt
    ├── test04_utf16.txt
    └── test05_incomplet.md
```

---

**Version** : 2.0
**Dernière mise à jour** : 2025-10-30
**Auteur** : Expert PowerShell
