# 🧪 Guide de test sur Windows

## Procédure de test complète

### Prérequis

- Windows 7+ ou Windows Server 2012+
- PowerShell 5.1+ (préinstallé sur Windows 10+)

Vérifiez votre version :

```powershell
$PSVersionTable.PSVersion
```

### Étape 1 : Cloner ou télécharger le projet

```powershell
# Avec Git
git clone https://github.com/votre-repo/PowerShell-text-to-excel-VF.git
cd PowerShell-text-to-excel-VF

# OU téléchargez le ZIP et extrayez-le
```

### Étape 2 : Débloquer les scripts (si téléchargés depuis Internet)

```powershell
# Débloquer tous les fichiers .ps1
Get-ChildItem -Path . -Filter "*.ps1" -Recurse | Unblock-File
```

### Étape 3 : Exécuter les tests automatiques

```powershell
# Lancer la suite de tests
.\Test-Extraction.ps1
```

**Résultat attendu** :

```text
================================================================================
 TESTS PRÉLIMINAIRES
================================================================================
2025-10-30 14:50:15 [✓] Script Extract-Sections.ps1 existe : PASS
2025-10-30 14:50:15 [✓] Dossier de tests existe : PASS
2025-10-30 14:50:15 [✓] Fichiers de test présents : PASS

================================================================================
 EXÉCUTION DU SCRIPT EN MODE NORMAL
================================================================================

  Exécution de : Extract-Sections.ps1
  Paramètres : -InputFolder '.\mes_textes' -OutputCsv '.\test_output.csv'

2025-10-30 14:50:16 [i] === Extraction de sections vers CSV ===
2025-10-30 14:50:16 [i] Dossier source : .\mes_textes
2025-10-30 14:50:16 [i] Fichier de sortie : .\test_output.csv
2025-10-30 14:50:16 [✓] Fichiers trouvés : 5

2025-10-30 14:50:17 [i] [1/5] Traitement : test01_complet.txt (20.0%)
2025-10-30 14:50:17 [✓]   ✓ Succès

...

2025-10-30 14:50:20 [✓] ✓ EXPORT TERMINÉ
2025-10-30 14:50:20 [✓]   Fichier : .\test_output.csv
2025-10-30 14:50:20 [✓]   Lignes : 5

2025-10-30 14:50:20 [✓] Exécution sans erreur : PASS

================================================================================
 VALIDATION DU FICHIER CSV
================================================================================
2025-10-30 14:50:20 [✓] Fichier CSV créé : PASS
2025-10-30 14:50:20 [✓] Import CSV réussi : PASS (5 lignes)
2025-10-30 14:50:20 [✓] Nombre de lignes ≥ 3 : PASS
2025-10-30 14:50:20 [✓] Toutes les colonnes présentes : PASS

================================================================================
 TESTS DE CONTENU : test01_complet.txt
================================================================================
2025-10-30 14:50:21 [✓] Client extrait correctement : PASS
2025-10-30 14:50:21 [✓] Objet extrait correctement : PASS
2025-10-30 14:50:21 [✓] Contexte non vide : PASS (458 caractères)
2025-10-30 14:50:21 [✓] Contexte contient 'infrastructure IT vieillissante' : PASS
2025-10-30 14:50:21 [✓] Contexte contient les enjeux : PASS
2025-10-30 14:50:21 [✓] Valeur ajoutée non vide : PASS (312 caractères)
2025-10-30 14:50:21 [✓] Valeur ajoutée contient 'expertise technique' : PASS
2025-10-30 14:50:21 [✓] Valeur ajoutée contient 'différenciation' : PASS
2025-10-30 14:50:21 [✓] Contact(s) contient 'Jean Dupont' : PASS
2025-10-30 14:50:21 [✓] Période contient 'Janvier 2025' : PASS
2025-10-30 14:50:21 [✓] Honoraires contient '450 000' : PASS
2025-10-30 14:50:21 [✓] Contenu et livrables non vide : PASS (356 caractères)
2025-10-30 14:50:21 [✓] Contenu contient 'Rapport d'audit' : PASS

================================================================================
 TESTS DE CONTENU : test02_variantes.txt (variantes)
================================================================================
2025-10-30 14:50:22 [✓] Client avec étiquette 'Client:' : PASS
2025-10-30 14:50:22 [✓] Valeur ajoutée (variante &) non vide : PASS (245 caractères)
2025-10-30 14:50:22 [✓] Valeur ajoutée contient inline 'expertise en healthtech' : PASS
2025-10-30 14:50:22 [✓] Contact(s) détecté malgré variante : PASS
2025-10-30 14:50:22 [✓] Période avec symbole → : PASS

================================================================================
 TESTS DE CONTENU : test03_inline.txt (contenu inline)
================================================================================
2025-10-30 14:50:23 [✓] Contexte contient inline 'Le groupe GreenEnergy' : PASS
2025-10-30 14:50:23 [✓] Contexte contient suite multi-lignes 'autorisations administratives' : PASS
2025-10-30 14:50:23 [✓] Valeur ajoutée (sans accents) contient inline 'leader français' : PASS
2025-10-30 14:50:23 [✓] Période avec inline 'Septembre 2024' : PASS
2025-10-30 14:50:23 [✓] Honoraires avec inline '320 000' : PASS
2025-10-30 14:50:23 [✓] Contenu avec inline 'Étude de faisabilité technique' : PASS

================================================================================
 TEST MODE STRICT (fichier incomplet)
================================================================================

  Exécution en mode strict sur test05_incomplet.md...
2025-10-30 14:50:24 [✓] Mode strict échoue sur fichier incomplet : PASS

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

### Étape 4 : Test manuel avec vos propres fichiers

#### 4.1 Créer un dossier avec vos fichiers

```powershell
# Créer un dossier pour vos documents
New-Item -ItemType Directory -Path ".\mes_documents" -Force

# Copier vos fichiers .txt/.md dans ce dossier
Copy-Item "C:\VosDocuments\*.txt" -Destination ".\mes_documents\"
```

#### 4.2 Exécuter le script

```powershell
# Extraction basique
.\Extract-Sections.ps1 -InputFolder ".\mes_documents" -OutputCsv ".\mon_export.csv"

# Avec logs détaillés (pour débogage)
.\Extract-Sections.ps1 -InputFolder ".\mes_documents" -OutputCsv ".\mon_export.csv" -Verbose
```

#### 4.3 Vérifier le résultat

```powershell
# Ouvrir le CSV dans Excel
Start-Process ".\mon_export.csv"

# OU importer en PowerShell pour inspection
$data = Import-Csv -Path ".\mon_export.csv" -Encoding UTF8
$data | Format-Table -AutoSize

# Afficher les colonnes d'une ligne
$data[0] | Format-List
```

### Étape 5 : Tests avancés

#### Test en mode strict

```powershell
# Le script échouera si des sections sont manquantes
.\Extract-Sections.ps1 -InputFolder ".\mes_documents" -Strict
```

#### Test avec sous-dossiers

```powershell
# Créer une structure de dossiers
New-Item -ItemType Directory -Path ".\test_recurse\2024" -Force
New-Item -ItemType Directory -Path ".\test_recurse\2025" -Force
Copy-Item ".\mes_textes\test01_complet.txt" -Destination ".\test_recurse\2024\"
Copy-Item ".\mes_textes\test02_variantes.txt" -Destination ".\test_recurse\2025\"

# Exécuter avec -Recurse
.\Extract-Sections.ps1 -InputFolder ".\test_recurse" -Recurse -OutputCsv ".\recurse_output.csv"

# Vérifier le résultat
Import-Csv ".\recurse_output.csv" | Select-Object Fichier, Chemin
```

#### Test de performance (gros volume)

```powershell
# Dupliquer les fichiers de test pour simuler un gros volume
$testFolder = ".\test_performance"
New-Item -ItemType Directory -Path $testFolder -Force

1..100 | ForEach-Object {
    Copy-Item ".\mes_textes\test01_complet.txt" -Destination "$testFolder\fichier_$_.txt"
}

# Mesurer le temps d'exécution
Measure-Command {
    .\Extract-Sections.ps1 -InputFolder $testFolder -OutputCsv ".\perf_test.csv"
}

# Nettoyer
Remove-Item -Path $testFolder -Recurse -Force
```

## Vérifications supplémentaires

### Vérifier l'encodage du CSV de sortie

```powershell
# Le CSV doit être UTF-8 sans BOM
$bytes = [System.IO.File]::ReadAllBytes(".\test_output.csv")

# Vérifier l'absence de BOM UTF-8 (EF BB BF)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Host "❌ Le CSV contient un BOM UTF-8 (non souhaité)" -ForegroundColor Red
} else {
    Write-Host "✅ Le CSV est UTF-8 sans BOM (correct)" -ForegroundColor Green
}
```

### Vérifier les sauts de ligne dans les cellules

```powershell
# Importer et vérifier
$data = Import-Csv -Path ".\test_output.csv" -Encoding UTF8
$contexte = $data[0].'Contexte, problématique et enjeux'

# Les sauts de ligne doivent être préservés
if ($contexte -match "`n") {
    Write-Host "✅ Sauts de ligne préservés dans le contenu" -ForegroundColor Green
} else {
    Write-Host "❌ Sauts de ligne perdus" -ForegroundColor Red
}
```

### Vérifier la compatibilité Excel

```powershell
# Ouvrir dans Excel et vérifier manuellement :
# 1. Encodage correct (pas de caractères bizarres)
# 2. Colonnes bien séparées
# 3. Sauts de ligne visibles en mode édition cellule (F2 ou double-clic)
Start-Process excel.exe -ArgumentList "$(Resolve-Path .\test_output.csv)"
```

## Résolution de problèmes

### PowerShell 5.1 vs 7+

Pour tester avec PowerShell 7 (si installé) :

```powershell
# Vérifier si pwsh est disponible
Get-Command pwsh -ErrorAction SilentlyContinue

# Lancer avec PowerShell 7
pwsh -File .\Extract-Sections.ps1 -InputFolder ".\mes_textes"
```

### Problèmes d'encodage

Si vous rencontrez des problèmes avec des caractères spéciaux :

```powershell
# Tester la lecture d'un fichier avec différents encodages
Get-Content -Path ".\mes_textes\test01_complet.txt" -Encoding UTF8 -TotalCount 5
Get-Content -Path ".\mes_textes\test01_complet.txt" -Encoding Unicode -TotalCount 5
Get-Content -Path ".\mes_textes\test01_complet.txt" -Encoding Default -TotalCount 5
```

### Créer un fichier de log détaillé

```powershell
# Rediriger toute la sortie vers un fichier log
.\Extract-Sections.ps1 -InputFolder ".\mes_textes" -Verbose *> extraction.log

# Examiner le log
Get-Content extraction.log
```

## Checklist de validation finale

Avant de déployer en production :

- [ ] Tests automatiques : 100% de réussite
- [ ] Test manuel avec vos vrais fichiers : OK
- [ ] CSV ouvre correctement dans Excel
- [ ] Encodage UTF-8 vérifié
- [ ] Tous les champs sont remplis comme attendu
- [ ] Sauts de ligne préservés
- [ ] Mode strict testé
- [ ] Option -Recurse testée (si nécessaire)
- [ ] Performance acceptable sur votre volume de données

## Prochaines étapes

✅ Une fois tous les tests passés, vous pouvez :

1. **Déployer le script** sur votre poste de travail
2. **Créer un exécutable** (voir [DOCUMENTATION.md](DOCUMENTATION.md#création-dun-exécutable))
3. **Automatiser l'exécution** (tâche planifiée Windows)
4. **Intégrer dans votre workflow** existant

---

**Bon test ! 🧪**
