# 📄 PowerShell Text to Excel - Version Finale

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Go](https://img.shields.io/badge/Go-1.21%2B-00ADD8.svg)](https://go.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **🚀 NOUVEAU** : Une version **Go** est maintenant disponible ! Parfaite pour les environnements verrouillés où l'exécution de scripts PowerShell est bloquée. Voir [README_GO.md](README_GO.md) et [BUILD_GO.md](BUILD_GO.md).

## 🎯 Description

**Extract-Sections.ps1** est un script PowerShell robuste qui extrait des sections structurées de fichiers texte (`.txt`, `.md`) et les exporte vers un fichier CSV UTF-8.

Idéal pour :
- 📋 Extraction de données de propositions commerciales
- 📊 Consolidation d'informations dispersées dans de nombreux fichiers
- 🔄 Parsing de documents structurés (missions, projets, contrats)
- 📈 Préparation de données pour analyse ou reporting

## ✨ Fonctionnalités principales

- ✅ **Détection robuste des titres** : gère les accents, bullets, variantes orthographiques
- ✅ **Multi-encodage** : UTF-16 (LE/BE), UTF-8 (avec/sans BOM), Windows-1252
- ✅ **Contenu inline** : extrait le texte après `:` sur la ligne du titre
- ✅ **Mode strict** : validation que toutes les sections requises sont présentes
- ✅ **Récursivité** : parcourt les sous-dossiers si demandé
- ✅ **Sans dépendances** : aucun module externe requis
- ✅ **Pas de droits admin** : fonctionne dans un environnement verrouillé

## 🤔 Quelle version choisir ?

### Version PowerShell (`Extract-Sections.ps1`)

**👍 Choisissez PowerShell si** :
- Vous avez les droits pour exécuter des scripts PowerShell
- Vous voulez modifier facilement le code
- Vous préférez un fichier léger (25 Ko)

**⚠️ Problème potentiel** : "l'exécution de scripts est désactivée sur ce système"

### Version Go (`extract-sections.exe`) - **RECOMMANDÉE pour environnements verrouillés**

**👍 Choisissez Go si** :
- ❌ PowerShell bloque l'exécution de scripts
- ✅ Vous voulez un exécutable autonome (aucune dépendance)
- ✅ Vous voulez la meilleure performance (5x plus rapide)
- ✅ Vous voulez distribuer facilement (un seul .exe)

**📘 Guide complet** : [README_GO.md](README_GO.md) | [BUILD_GO.md](BUILD_GO.md)

---

## 🚀 Démarrage rapide

### Installation

```bash
git clone https://github.com/votre-repo/PowerShell-text-to-excel-VF.git
cd PowerShell-text-to-excel-VF
```

### Usage basique

```powershell
# Extraire les sections de tous les fichiers .txt/.md d'un dossier
.\Extract-Sections.ps1 -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
```

### Options avancées

```powershell
# Avec sous-dossiers + mode strict + logs détaillés
.\Extract-Sections.ps1 -InputFolder ".\documents" -Recurse -Strict -Verbose
```

## 📊 Colonnes extraites

Le CSV de sortie contient 10 colonnes :

| # | Colonne | Description |
|---|---------|-------------|
| 1-2 | **Fichier, Chemin** | Métadonnées du fichier source |
| 3-4 | **Client, Objet** | Extraits des premières lignes |
| 5-10 | **6 sections** | Contexte, Valeur ajoutée, Contact(s), Période, Honoraires, Contenu |

## 📝 Exemple de fichier source

```text
Acme Corporation
Mission de transformation digitale

Contexte, problématique et enjeux:
L'entreprise fait face à une infrastructure IT vieillissante.
Les systèmes actuels ne sont plus adaptés aux besoins métiers.

Valeur ajoutée et différenciation:
Notre approche unique combine expertise technique et compréhension métier.
Méthodologie éprouvée sur plus de 50 projets similaires.

Contact(s):
Jean Dupont - CTO - jean.dupont@acme.com

Période:
Janvier 2025 - Juin 2025 (6 mois)

Honoraires:
Budget global : 450 000 € HT

Contenu, résultats et livrables:
- Rapport d'audit complet
- Architecture cible détaillée
- Formation des équipes
```

## ✅ Tests

Un script de test complet est fourni pour valider toutes les fonctionnalités :

```powershell
.\Test-Extraction.ps1
```

Résultat attendu :

```text
  Tests exécutés  : 42
  Tests réussis   : 42
  Tests échoués   : 0
  Taux de succès  : 100.0%

✓ TOUS LES TESTS SONT PASSÉS !
```

## 📚 Documentation complète

Pour plus de détails, consultez **[DOCUMENTATION.md](DOCUMENTATION.md)** qui couvre :

- 🔍 Détection des variantes de titres (accents, bullets, &/et, etc.)
- 🌍 Gestion des encodages (UTF-16, UTF-8, ANSI)
- 🎓 Cas d'usage avancés (automatisation, pipeline, etc.)
- 📦 Création d'un exécutable (.exe) pour environnements verrouillés
- 🔧 Dépannage des problèmes courants

## 🛠️ Prérequis

- **OS** : Windows 7+ / Windows Server 2012+
- **PowerShell** : Version 5.1 minimum (compatible PowerShell 7+)
- **Droits** : Aucun droit administrateur requis

Vérifier votre version :

```powershell
$PSVersionTable.PSVersion
```

## 📦 Structure du projet

```
PowerShell-text-to-excel-VF/
│
├── Extract-Sections.ps1          # 🎯 Script principal
├── Test-Extraction.ps1            # ✅ Script de tests
├── DOCUMENTATION.md               # 📚 Documentation complète
├── README.md                      # 📖 Ce fichier
│
└── mes_textes/                    # 📁 Fichiers de test
    ├── test01_complet.txt
    ├── test02_variantes.txt
    ├── test03_inline.txt
    ├── test04_utf16.txt
    └── test05_incomplet.md
```

## 🎓 Exemples d'utilisation

### Exemple 1 : Traitement basique

```powershell
.\Extract-Sections.ps1 -InputFolder "C:\Docs\Missions" -OutputCsv "C:\Output\missions.csv"
```

### Exemple 2 : Avec sous-dossiers

```powershell
.\Extract-Sections.ps1 -InputFolder ".\documents" -OutputCsv ".\resultats.csv" -Recurse
```

### Exemple 3 : Mode strict (valide que toutes les sections sont présentes)

```powershell
.\Extract-Sections.ps1 -InputFolder ".\propositions" -Strict
```

### Exemple 4 : Debug avec logs détaillés

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Verbose
```

## 📦 Création d'un exécutable (EXE)

Pour les environnements où l'exécution de scripts `.ps1` est bloquée :

```powershell
# Installer PS2EXE
Install-Module -Name ps2exe -Scope CurrentUser

# Convertir en .exe
ps2exe .\Extract-Sections.ps1 .\Extract-Sections.exe
```

Voir [DOCUMENTATION.md](DOCUMENTATION.md#création-dun-exécutable) pour plus de détails.

## 🔍 Variantes de titres supportées

Le script reconnaît automatiquement ces variantes :

| Titre attendu | Variantes reconnues |
|---------------|---------------------|
| `Contexte, problématique et enjeux` | `Contexte, problematique et enjeux` (sans accents) |
| `Valeur ajoutée et différenciation` | `Valeur ajoutée & différenciation`<br>`Valeur ajoutee et differenciation` |
| `Contact(s)` | `Contacts`<br>`Contact` |
| `Période` | `Periode`<br>`Durée` |

Et aussi :
- Bullets : `•`, `-`, `▪`, etc.
- Numérotation : `1.`, `2)`, etc.
- Contenu inline après `:` inclus automatiquement

## 🐛 Dépannage

### Erreur "exécution de scripts est désactivée"

```powershell
# Solution 1 : Débloquer le fichier
Unblock-File -Path .\Extract-Sections.ps1

# Solution 2 : Bypass temporaire
PowerShell.exe -ExecutionPolicy Bypass -File .\Extract-Sections.ps1
```

### Caractères illisibles (mojibake)

- Vérifier l'encodage du fichier source
- Ouvrir le CSV avec Excel en forçant UTF-8 :
  - Données → Obtenir des données → À partir d'un fichier texte/CSV
  - Sélectionner `65001 : Unicode (UTF-8)`

Voir [DOCUMENTATION.md - Dépannage](DOCUMENTATION.md#dépannage) pour plus de solutions.

## 📈 Performance

- ⚡ **Rapide** : Traite 100 fichiers (~50 Ko chacun) en ~10 secondes
- 💾 **Léger** : Aucune dépendance externe
- 🔄 **Scalable** : Testé avec 1000+ fichiers

## 📞 Support

- 📖 Documentation complète : [DOCUMENTATION.md](DOCUMENTATION.md)
- 🐛 Signaler un bug : [Issues](https://github.com/votre-repo/issues)
- 💬 Questions : [Discussions](https://github.com/votre-repo/discussions)

## 🤝 Contribution

Les contributions sont les bienvenues ! Consultez [CONTRIBUTING.md](CONTRIBUTING.md) pour les directives.

## 📜 Licence

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE) pour plus de détails.

---

**Version** : 2.0
**Dernière mise à jour** : 2025-10-30
**Auteur** : Expert PowerShell

---

## 🌟 Fonctionnalités à venir

- [ ] Support de formats additionnels (.docx, .pdf)
- [ ] Export vers Excel (.xlsx) natif
- [ ] Interface graphique (GUI) optionnelle
- [ ] Détection automatique de nouvelles sections
- [ ] Support des templates personnalisés

---

**⭐ Si ce projet vous est utile, n'hésitez pas à lui donner une étoile !**