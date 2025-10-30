# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

---

## [2.0.0] - 2025-10-30

### 🎉 Refonte complète du script

Version professionnelle avec améliorations majeures par rapport à la v1.0.

### ✨ Ajouts

#### Détection robuste des titres
- **Variantes d'accents** : Support complet des caractères accentués et non accentués
  - `é/è/e`, `à/a`, `ï/î/i`, `ô/o`, `û/u`, `ç/c`
- **Variantes orthographiques** :
  - `Valeur ajoutée et différenciation` ⇄ `Valeur ajoutée & différenciation`
  - `Contact(s)` ⇄ `Contacts` ⇄ `Contact`
  - `Période` ⇄ `Periode`
  - `Contexte, problématique...` avec ou sans accents
- **Bullets et numérotation** : Support de tous les types
  - `-`, `•`, `▪`, `◦`, `▫`
  - `1.`, `2)`, `3.`, etc.
- **Contenu inline** : Le texte après `:` sur la ligne du titre est maintenant inclus
  - Exemple : `Période : Janvier 2025 avec extension possible` → tout est capturé

#### Gestion multi-encodage avancée
- **Détection automatique du BOM** (Byte Order Mark)
  - UTF-16 LE : `FF FE`
  - UTF-16 BE : `FE FF`
  - UTF-8 : `EF BB BF`
- **Fallback intelligent** si pas de BOM
  - Essais successifs : UTF-8, UTF-16 LE, UTF-16 BE, Windows-1252
- **Robustesse** : Aucun plantage sur fichiers mal encodés

#### Extraction Client/Objet améliorée
- **Stratégie à 2 niveaux** :
  1. Recherche d'étiquettes explicites (prioritaire)
     - `Client:`, `Destinataire:`, `Société:`, `Entreprise:`
     - `Objet:`, `Mission:`, `Sujet:`, `Objet de la mission:`
  2. Heuristique si absentes (lignes 1-4)
- **Nettoyage intelligent** : Suppression des guillemets/espaces parasites
- **Exclusion des mots-clés** : L'objet s'arrête avant un titre de section

#### Mode strict
- Nouveau paramètre `-Strict` pour validation
- Échoue si des sections requises sont manquantes
- Utile pour détecter rapidement les anomalies dans les fichiers

#### Logs et verbosité
- **Logs structurés** avec timestamps
- **Niveaux de log** : Info, Success, Warning, Error, Debug
- **Code couleur** dans le terminal pour meilleure lisibilité
- **Statistiques** :
  - Nombre de fichiers traités
  - Nombre de succès/erreurs
  - Progression en temps réel
  - Taille du fichier CSV de sortie

#### Documentation complète
- **README.md** : Vue d'ensemble avec badges et exemples
- **DOCUMENTATION.md** : Guide complet (20+ pages)
  - Installation
  - Utilisation avancée
  - Encodages
  - Dépannage
  - Création d'un .exe
- **QUICKSTART.md** : Guide ultra-rapide (2 minutes)
- **TESTING_WINDOWS.md** : Procédure de test complète
- **CHANGELOG.md** : Ce fichier

#### Tests automatiques
- **Script de test complet** : `Test-Extraction.ps1`
- **42 tests unitaires** couvrant :
  - Extraction des sections
  - Détection des variantes
  - Contenu inline
  - Mode strict
  - Encodages
- **Assertions robustes** avec rapports détaillés

#### Fichiers de test
- **5 fichiers de test** représentatifs :
  - `test01_complet.txt` : Fichier parfait avec toutes les sections
  - `test02_variantes.txt` : Variantes orthographiques et bullets
  - `test03_inline.txt` : Contenu inline après `:`
  - `test04_utf16.txt` : Test encodage UTF-16
  - `test05_incomplet.md` : Test mode strict (section manquante)

### 🔧 Améliorations

#### Performance
- **Regex optimisées** pour détection des titres
- **Gestion mémoire** : ArrayList au lieu de tableaux dynamiques
- **Traitement par lots** : Support de 1000+ fichiers

#### Normalisation du texte
- **Espaces spéciaux** : Conversion vers espaces normaux
  - Insécables (`\u00A0`), fines (`\u202F`, `\u2009`)
  - Largeur nulle (`\u200B`)
- **Tirets** : Normalisation (`—`, `–`, `•` → `-`)
- **Guillemets** : Standardisation (`«»`, `""` → `"`)
- **Retours à la ligne** : Uniformisation (`\r\n` → `\n`)
- **Préservation** : Les sauts de ligne internes sont conservés

#### Gestion d'erreurs
- **Try-catch** robustes
- **Messages d'erreur** explicites avec contexte
- **Récupération gracieuse** : Continue après erreur sur un fichier
- **Exit codes** : 0 = succès, 1 = erreur

#### Compatibilité
- **PowerShell 5.1** : Testé et fonctionnel
- **PowerShell 7+** : Support complet
- **Windows 7+** : Compatible
- **Pas de dépendances** : Aucun module externe requis
- **Pas de droits admin** : Fonctionne en environnement verrouillé

### 🐛 Corrections

#### Extraction de sections
- **Fin de section** : Détection correcte du prochain titre (non inclus)
- **Sections vides** : Gestion propre (cellule vide dans le CSV)
- **Espaces parasites** : Nettoyage sans perte de structure

#### CSV
- **Encodage** : UTF-8 sans BOM (compatible Excel international)
- **Séparateurs** : Virgules correctement échappées dans le contenu
- **Sauts de ligne** : Préservés dans les cellules (norme RFC 4180)
- **Guillemets** : Gestion automatique par `Export-Csv`

#### Client/Objet
- **Détection fiable** : Priorité aux étiquettes explicites
- **Heuristique améliorée** : Arrêt avant mots-clés de section
- **Nettoyage** : Suppression des suffixes parasites (`Période :`, `Honoraires :`)

### 🗑️ Suppressions

- Code mort et commentaires obsolètes
- Fonctions de debug temporaires

### 🔒 Sécurité

- **Validation des chemins** : Protection contre path traversal
- **Pas d'exécution de code** : Aucune évaluation dynamique
- **Lecture seule** : Le script ne modifie jamais les fichiers source

---

## [1.0.0] - Date initiale

### Fonctionnalités initiales

- Extraction basique des 6 sections
- Support UTF-8 et UTF-16
- Heuristique Client/Objet sur 4 premières lignes
- Export CSV

### Limitations connues v1.0

- ⚠️ Détection des titres fragile (accents stricts)
- ⚠️ Pas de support pour contenu inline après `:`
- ⚠️ Variantes orthographiques non reconnues
- ⚠️ Pas de mode strict
- ⚠️ Logs minimaux
- ⚠️ Pas de tests automatiques
- ⚠️ Documentation limitée

---

## [Unreleased] - Fonctionnalités futures envisagées

### À venir

- [ ] Support de formats additionnels
  - [ ] `.docx` (Microsoft Word)
  - [ ] `.pdf` (extraction de texte)
- [ ] Export vers Excel natif (`.xlsx`)
- [ ] Interface graphique (GUI) optionnelle
- [ ] Détection automatique de nouvelles sections (ML)
- [ ] Support des templates personnalisables
- [ ] Validation de schéma (JSON Schema pour structure attendue)
- [ ] Mode interactif (choix des sections à extraire)
- [ ] Intégration avec bases de données (export SQL)
- [ ] API REST (mode serveur)

### Idées en discussion

- [ ] Support de langues multiples (anglais, espagnol)
- [ ] Extraction de tableaux structurés
- [ ] OCR pour fichiers scannés
- [ ] Synchronisation cloud (OneDrive, SharePoint)
- [ ] Notifications (email, Slack) après traitement

---

## Notes de version

### Comment mettre à jour

```powershell
# Sauvegarder l'ancienne version
Copy-Item .\Extract-Sections.ps1 .\Extract-Sections_old.ps1

# Télécharger la nouvelle version
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/votre-repo/main/Extract-Sections.ps1" -OutFile .\Extract-Sections.ps1

# Tester
.\Test-Extraction.ps1
```

### Compatibilité ascendante

La v2.0 est **rétrocompatible** avec les fichiers traités par la v1.0.

Les anciens scripts/pipelines fonctionneront sans modification :

```powershell
# Syntaxe v1.0 (toujours valide en v2.0)
.\Extract-Sections.ps1 -InputFolder ".\docs" -OutputCsv ".\output.csv"
```

Nouveaux paramètres optionnels (pas d'impact sur usage existant) :
- `-Recurse` (nouveau)
- `-Strict` (nouveau)
- `-Verbose` (amélioré)

---

**Voir le fichier [DOCUMENTATION.md](DOCUMENTATION.md) pour plus de détails sur chaque fonctionnalité.**
