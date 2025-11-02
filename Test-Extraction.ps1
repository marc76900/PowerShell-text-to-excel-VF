<#
.SYNOPSIS
    Script de test et validation pour Extract-Sections.ps1

.DESCRIPTION
    Exécute une batterie de tests pour valider :
    - L'extraction correcte des sections
    - La gestion du contenu inline
    - La détection des variantes de titres
    - La robustesse face aux encodages
    - Le comportement en mode strict

.EXAMPLE
    .\Test-Extraction.ps1

.EXAMPLE
    .\Test-Extraction.ps1 -Verbose
#>

[CmdletBinding()]
Param()

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptPath = Join-Path $PSScriptRoot "Extract-Sections.ps1"
$TestFolder = Join-Path $PSScriptRoot "mes_textes"
$OutputCsv = Join-Path $PSScriptRoot "test_output.csv"

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

function Write-TestHeader {
    Param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "="*80 -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "="*80 -ForegroundColor Cyan
}

function Write-TestResult {
    Param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )

    $symbol = if ($Passed) { "✓" } else { "✗" }
    $color = if ($Passed) { "Green" } else { "Red" }
    $status = if ($Passed) { "PASS" } else { "FAIL" }

    Write-Host "  [$symbol] " -ForegroundColor $color -NoNewline
    Write-Host "$TestName : " -NoNewline
    Write-Host $status -ForegroundColor $color

    if ($Details) {
        Write-Host "      → $Details" -ForegroundColor Gray
    }
}

function Assert-True {
    Param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Expected,
        [string]$Actual
    )

    if ($Condition) {
        Write-TestResult -TestName $TestName -Passed $true
        return $true
    } else {
        Write-TestResult -TestName $TestName -Passed $false -Details "Attendu: $Expected | Obtenu: $Actual"
        return $false
    }
}

function Assert-Contains {
    Param(
        [string]$TestName,
        [string]$Text,
        [string]$Expected
    )

    $contains = $Text -like "*$Expected*"

    if ($contains) {
        Write-TestResult -TestName $TestName -Passed $true
        return $true
    } else {
        $preview = if ($Text.Length -gt 100) { $Text.Substring(0, 100) + "..." } else { $Text }
        Write-TestResult -TestName $TestName -Passed $false -Details "Texte recherché '$Expected' non trouvé dans : $preview"
        return $false
    }
}

function Assert-NotEmpty {
    Param(
        [string]$TestName,
        [string]$Text
    )

    $notEmpty = -not [string]::IsNullOrWhiteSpace($Text)

    if ($notEmpty) {
        Write-TestResult -TestName $TestName -Passed $true -Details "Longueur : $($Text.Length) caractères"
        return $true
    } else {
        Write-TestResult -TestName $TestName -Passed $false -Details "Texte vide ou null"
        return $false
    }
}

# ============================================================================
# TESTS PRÉLIMINAIRES
# ============================================================================

Write-TestHeader "TESTS PRÉLIMINAIRES"

$testsPassed = 0
$testsFailed = 0

# Test 1 : Script principal existe
if (Assert-True -TestName "Script Extract-Sections.ps1 existe" `
    -Condition (Test-Path $ScriptPath) `
    -Expected "Fichier existant" `
    -Actual (if (Test-Path $ScriptPath) { "Existe" } else { "Introuvable" })) {
    $testsPassed++
} else {
    $testsFailed++
}

# Test 2 : Dossier de test existe
if (Assert-True -TestName "Dossier de tests existe" `
    -Condition (Test-Path $TestFolder) `
    -Expected "Dossier existant" `
    -Actual (if (Test-Path $TestFolder) { "Existe" } else { "Introuvable" })) {
    $testsPassed++
} else {
    $testsFailed++
}

# Test 3 : Fichiers de test présents
$testFiles = Get-ChildItem -Path $TestFolder -File -Filter "*.txt" -ErrorAction SilentlyContinue
if (Assert-True -TestName "Fichiers de test présents" `
    -Condition ($testFiles.Count -ge 3) `
    -Expected "≥ 3 fichiers" `
    -Actual "$($testFiles.Count) fichiers") {
    $testsPassed++
} else {
    $testsFailed++
}

# ============================================================================
# EXÉCUTION DU SCRIPT PRINCIPAL
# ============================================================================

Write-TestHeader "EXÉCUTION DU SCRIPT EN MODE NORMAL"

try {
    Write-Host "`n  Exécution de : " -NoNewline
    Write-Host "Extract-Sections.ps1" -ForegroundColor Yellow
    Write-Host "  Paramètres : " -NoNewline
    Write-Host "-InputFolder '$TestFolder' -OutputCsv '$OutputCsv'" -ForegroundColor Yellow
    Write-Host ""

    # Exécuter le script
    & $ScriptPath -InputFolder $TestFolder -OutputCsv $OutputCsv -Verbose:$VerbosePreference

    Write-Host ""
    Write-TestResult -TestName "Exécution sans erreur" -Passed $true
    $testsPassed++
}
catch {
    Write-TestResult -TestName "Exécution sans erreur" -Passed $false -Details $_.Exception.Message
    $testsFailed++
    Write-Host "`nERREUR FATALE : Impossible de continuer les tests" -ForegroundColor Red
    exit 1
}

# ============================================================================
# VALIDATION DU CSV DE SORTIE
# ============================================================================

Write-TestHeader "VALIDATION DU FICHIER CSV"

# Test : CSV créé
if (-not (Test-Path $OutputCsv)) {
    Write-TestResult -TestName "Fichier CSV créé" -Passed $false -Details "Fichier introuvable"
    $testsFailed++
    exit 1
}

Write-TestResult -TestName "Fichier CSV créé" -Passed $true
$testsPassed++

# Importer le CSV
try {
    $csvData = Import-Csv -Path $OutputCsv -Encoding UTF8
    Write-TestResult -TestName "Import CSV réussi" -Passed $true -Details "$($csvData.Count) lignes"
    $testsPassed++
}
catch {
    Write-TestResult -TestName "Import CSV réussi" -Passed $false -Details $_.Exception.Message
    $testsFailed++
    exit 1
}

# Test : Nombre de lignes
if (Assert-True -TestName "Nombre de lignes ≥ 3" `
    -Condition ($csvData.Count -ge 3) `
    -Expected "≥ 3 lignes" `
    -Actual "$($csvData.Count) lignes") {
    $testsPassed++
} else {
    $testsFailed++
}

# Test : Colonnes présentes
$expectedColumns = @(
    "Fichier", "Chemin", "Client", "Objet",
    "Contexte, problématique et enjeux",
    "Valeur ajoutée et différenciation",
    "Contact(s)",
    "Période",
    "Honoraires",
    "Contenu, résultats et livrables"
)

$actualColumns = $csvData[0].PSObject.Properties.Name
$missingColumns = $expectedColumns | Where-Object { $_ -notin $actualColumns }

if (Assert-True -TestName "Toutes les colonnes présentes" `
    -Condition ($missingColumns.Count -eq 0) `
    -Expected "10 colonnes" `
    -Actual "$($actualColumns.Count) colonnes") {
    $testsPassed++
} else {
    $testsFailed++
    if ($missingColumns) {
        Write-Host "      Colonnes manquantes : $($missingColumns -join ', ')" -ForegroundColor Red
    }
}

# ============================================================================
# VALIDATION DU CONTENU - FICHIER test01_complet.txt
# ============================================================================

Write-TestHeader "TESTS DE CONTENU : test01_complet.txt"

$row1 = $csvData | Where-Object { $_.Fichier -eq "test01_complet.txt" }

if (-not $row1) {
    Write-Host "  ERREUR : Fichier test01_complet.txt non trouvé dans le CSV" -ForegroundColor Red
    $testsFailed += 10
} else {
    # Test : Client
    if (Assert-Contains -TestName "Client extrait correctement" `
        -Text $row1.Client `
        -Expected "Acme Corporation") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Objet
    if (Assert-Contains -TestName "Objet extrait correctement" `
        -Text $row1.Objet `
        -Expected "transformation digitale") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Contexte complet
    $contexte = $row1.'Contexte, problématique et enjeux'
    if (Assert-NotEmpty -TestName "Contexte non vide" -Text $contexte) {
        $testsPassed++
    } else {
        $testsFailed++
    }

    if (Assert-Contains -TestName "Contexte contient 'infrastructure IT vieillissante'" `
        -Text $contexte `
        -Expected "infrastructure IT vieillissante") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    if (Assert-Contains -TestName "Contexte contient les enjeux" `
        -Text $contexte `
        -Expected "Moderniser l'infrastructure") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Valeur ajoutée complète
    $valeur = $row1.'Valeur ajoutée et différenciation'
    if (Assert-NotEmpty -TestName "Valeur ajoutée non vide" -Text $valeur) {
        $testsPassed++
    } else {
        $testsFailed++
    }

    if (Assert-Contains -TestName "Valeur ajoutée contient 'expertise technique'" `
        -Text $valeur `
        -Expected "expertise technique") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    if (Assert-Contains -TestName "Valeur ajoutée contient 'différenciation'" `
        -Text $valeur `
        -Expected "différenciation") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Contacts
    if (Assert-Contains -TestName "Contact(s) contient 'Jean Dupont'" `
        -Text $row1.'Contact(s)' `
        -Expected "Jean Dupont") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Période
    if (Assert-Contains -TestName "Période contient 'Janvier 2025'" `
        -Text $row1.'Période' `
        -Expected "Janvier 2025") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Honoraires
    if (Assert-Contains -TestName "Honoraires contient '450 000'" `
        -Text $row1.'Honoraires' `
        -Expected "450 000") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Contenu et livrables
    $contenu = $row1.'Contenu, résultats et livrables'
    if (Assert-NotEmpty -TestName "Contenu et livrables non vide" -Text $contenu) {
        $testsPassed++
    } else {
        $testsFailed++
    }

    if (Assert-Contains -TestName "Contenu contient 'Rapport d'audit'" `
        -Text $contenu `
        -Expected "Rapport d'audit") {
        $testsPassed++
    } else {
        $testsFailed++
    }
}

# ============================================================================
# VALIDATION DU CONTENU - FICHIER test02_variantes.txt
# ============================================================================

Write-TestHeader "TESTS DE CONTENU : test02_variantes.txt (variantes)"

$row2 = $csvData | Where-Object { $_.Fichier -eq "test02_variantes.txt" }

if (-not $row2) {
    Write-Host "  ERREUR : Fichier test02_variantes.txt non trouvé dans le CSV" -ForegroundColor Red
    $testsFailed += 5
} else {
    # Test : Client avec étiquette explicite
    if (Assert-Contains -TestName "Client avec étiquette 'Client:'" `
        -Text $row2.Client `
        -Expected "TechStart") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Valeur ajoutée avec "&" au lieu de "et"
    $valeur2 = $row2.'Valeur ajoutée et différenciation'
    if (Assert-NotEmpty -TestName "Valeur ajoutée (variante &) non vide" -Text $valeur2) {
        $testsPassed++
    } else {
        $testsFailed++
    }

    if (Assert-Contains -TestName "Valeur ajoutée contient inline 'expertise en healthtech'" `
        -Text $valeur2 `
        -Expected "expertise en healthtech") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Contacts avec variante "Contacts :"
    if (Assert-Contains -TestName "Contact(s) détecté malgré variante" `
        -Text $row2.'Contact(s)' `
        -Expected "Pierre Lefebvre") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Période avec flèche →
    if (Assert-Contains -TestName "Période avec symbole →" `
        -Text $row2.'Période' `
        -Expected "Mars 2025") {
        $testsPassed++
    } else {
        $testsFailed++
    }
}

# ============================================================================
# VALIDATION DU CONTENU - FICHIER test03_inline.txt
# ============================================================================

Write-TestHeader "TESTS DE CONTENU : test03_inline.txt (contenu inline)"

$row3 = $csvData | Where-Object { $_.Fichier -eq "test03_inline.txt" }

if (-not $row3) {
    Write-Host "  ERREUR : Fichier test03_inline.txt non trouvé dans le CSV" -ForegroundColor Red
    $testsFailed += 5
} else {
    # Test : Contexte avec contenu inline après ":"
    $contexte3 = $row3.'Contexte, problématique et enjeux'
    if (Assert-Contains -TestName "Contexte contient inline 'Le groupe GreenEnergy'" `
        -Text $contexte3 `
        -Expected "Le groupe GreenEnergy") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    if (Assert-Contains -TestName "Contexte contient suite multi-lignes 'autorisations administratives'" `
        -Text $contexte3 `
        -Expected "autorisations administratives") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Valeur ajoutée sans accent "differenciation"
    $valeur3 = $row3.'Valeur ajoutée et différenciation'
    if (Assert-Contains -TestName "Valeur ajoutée (sans accents) contient inline 'leader français'" `
        -Text $valeur3 `
        -Expected "leader français") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Période avec inline
    if (Assert-Contains -TestName "Période avec inline 'Septembre 2024'" `
        -Text $row3.'Période' `
        -Expected "Septembre 2024") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Honoraires avec inline complet
    if (Assert-Contains -TestName "Honoraires avec inline '320 000'" `
        -Text $row3.'Honoraires' `
        -Expected "320 000") {
        $testsPassed++
    } else {
        $testsFailed++
    }

    # Test : Contenu avec inline
    $contenu3 = $row3.'Contenu, résultats et livrables'
    if (Assert-Contains -TestName "Contenu avec inline 'Étude de faisabilité technique'" `
        -Text $contenu3 `
        -Expected "Étude de faisabilité technique") {
        $testsPassed++
    } else {
        $testsFailed++
    }
}

# ============================================================================
# TEST EN MODE STRICT (doit échouer sur fichier incomplet)
# ============================================================================

Write-TestHeader "TEST MODE STRICT (fichier incomplet)"

$testStrictCsv = Join-Path $PSScriptRoot "test_strict.csv"

try {
    Write-Host "`n  Exécution en mode strict sur test05_incomplet.md..." -ForegroundColor Yellow

    # Créer un dossier temporaire avec seulement le fichier incomplet
    $tempStrictFolder = Join-Path $PSScriptRoot "temp_strict_test"
    if (Test-Path $tempStrictFolder) {
        Remove-Item -Path $tempStrictFolder -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempStrictFolder -Force | Out-Null
    Copy-Item -Path (Join-Path $TestFolder "test05_incomplet.md") -Destination $tempStrictFolder

    # Tenter l'exécution en mode strict
    & $ScriptPath -InputFolder $tempStrictFolder -OutputCsv $testStrictCsv -Strict -ErrorAction Stop 2>&1 | Out-Null

    # Si on arrive ici, le script n'a PAS échoué (ce qui est incorrect)
    Write-TestResult -TestName "Mode strict échoue sur fichier incomplet" -Passed $false -Details "Le script aurait dû échouer mais a réussi"
    $testsFailed++

    # Cleanup
    Remove-Item -Path $tempStrictFolder -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    # Le script a échoué comme attendu
    Write-TestResult -TestName "Mode strict échoue sur fichier incomplet" -Passed $true -Details "Erreur attendue détectée"
    $testsPassed++

    # Cleanup
    $tempStrictFolder = Join-Path $PSScriptRoot "temp_strict_test"
    if (Test-Path $tempStrictFolder) {
        Remove-Item -Path $tempStrictFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ============================================================================
# RÉSUMÉ FINAL
# ============================================================================

Write-TestHeader "RÉSUMÉ DES TESTS"

$totalTests = $testsPassed + $testsFailed
$successRate = [math]::Round(($testsPassed / $totalTests) * 100, 1)

Write-Host ""
Write-Host "  Tests exécutés  : " -NoNewline
Write-Host $totalTests -ForegroundColor Cyan

Write-Host "  Tests réussis   : " -NoNewline
Write-Host $testsPassed -ForegroundColor Green

Write-Host "  Tests échoués   : " -NoNewline
if ($testsFailed -gt 0) {
    Write-Host $testsFailed -ForegroundColor Red
} else {
    Write-Host $testsFailed -ForegroundColor Green
}

Write-Host ""
Write-Host "  Taux de succès  : " -NoNewline
if ($successRate -eq 100) {
    Write-Host "$successRate%" -ForegroundColor Green
} elseif ($successRate -ge 80) {
    Write-Host "$successRate%" -ForegroundColor Yellow
} else {
    Write-Host "$successRate%" -ForegroundColor Red
}

Write-Host ""
Write-Host "="*80 -ForegroundColor Cyan

if ($testsFailed -eq 0) {
    Write-Host "`n✓ TOUS LES TESTS SONT PASSÉS !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n✗ CERTAINS TESTS ONT ÉCHOUÉ" -ForegroundColor Red
    exit 1
}
