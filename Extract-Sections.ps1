<#
.SYNOPSIS
    Extrait des sections structurées de fichiers texte vers un CSV UTF-8.

.DESCRIPTION
    Parse des fichiers .txt/.md pour extraire des sections délimitées par des titres spécifiques.
    Gère robustement les encodages variés (UTF-16, UTF-8, ANSI) et les variations de titres.

    Colonnes extraites :
    - Fichier, Chemin (métadonnées)
    - Client, Objet (extraits des premières lignes)
    - 6 sections de contenu (entre titres délimiteurs)

.PARAMETER InputFolder
    Dossier contenant les fichiers .txt/.md à traiter.

.PARAMETER OutputCsv
    Chemin du fichier CSV de sortie (UTF-8 sans BOM).

.PARAMETER Recurse
    Parcourt récursivement les sous-dossiers.

.PARAMETER Strict
    En mode strict, échoue si des sections requises sont manquantes.
    Par défaut, les sections manquantes restent vides.

.PARAMETER Verbose
    Affiche des logs détaillés pour chaque fichier traité.

.EXAMPLE
    .\Extract-Sections.ps1 -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"

.EXAMPLE
    .\Extract-Sections.ps1 -InputFolder ".\docs" -Recurse -Strict -Verbose

.NOTES
    Version: 2.0
    Auteur: Expert PowerShell
    Compatible: PowerShell 5.1+ et PowerShell 7+
    Environnement: Pas de droits admin requis
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false, HelpMessage="Dossier contenant les fichiers .txt/.md")]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$InputFolder = ".\mes_textes",

    [Parameter(Mandatory=$false, HelpMessage="Fichier CSV de sortie")]
    [string]$OutputCsv = ".\sections.csv",

    [Parameter(Mandatory=$false, HelpMessage="Parcourir les sous-dossiers")]
    [switch]$Recurse,

    [Parameter(Mandatory=$false, HelpMessage="Mode strict : échoue si sections manquantes")]
    [switch]$Strict
)

# Configuration stricte pour détecter les erreurs
$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================================
# CONFIGURATION DES SECTIONS
# ============================================================================

# Liste ordonnée des sections à extraire (colonnes 5-10)
$Script:RequiredSections = @(
    "Contexte, problématique et enjeux",
    "Valeur ajoutée et différenciation",
    "Contact(s)",
    "Période",
    "Honoraires",
    "Contenu, résultats et livrables"
)

# Variantes acceptées pour chaque section (pour logging)
$Script:SectionVariants = @{
    "Contexte, problématique et enjeux" = @("Contexte", "Problématique", "Enjeux")
    "Valeur ajoutée et différenciation" = @("Valeur ajoutée", "Différenciation", "Valeur ajoutee et differenciation", "Valeur ajoutée & différenciation")
    "Contact(s)" = @("Contact", "Contacts", "Contact(s)")
    "Période" = @("Période", "Periode", "Durée", "Duree")
    "Honoraires" = @("Honoraires", "Budget", "Tarifs", "Prix")
    "Contenu, résultats et livrables" = @("Contenu", "Résultats", "Resultats", "Livrables")
}

# ============================================================================
# FONCTIONS UTILITAIRES - NORMALISATION
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Écrit un message de log avec timestamp et niveau.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Success','Warning','Error','Debug')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Debug'   { 'Cyan' }
        default   { 'White' }
    }

    $prefix = switch ($Level) {
        'Success' { '[✓]' }
        'Warning' { '[!]' }
        'Error'   { '[✗]' }
        'Debug'   { '[→]' }
        default   { '[i]' }
    }

    if ($Level -eq 'Debug') {
        Write-Verbose "$timestamp $prefix $Message"
    } else {
        Write-Host "$timestamp $prefix $Message" -ForegroundColor $color
    }
}

function Normalize-Text {
    <#
    .SYNOPSIS
        Normalise un texte en nettoyant les caractères spéciaux.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    # Uniformiser les retours à la ligne
    $t = $Text -replace "`r`n", "`n" -replace "`r", "`n"

    # Nettoyer les espaces spéciaux (mais préserver les espaces normaux)
    $t = $t -replace "`u00A0", " "     # Espace insécable
    $t = $t -replace "`u202F", " "     # Espace fine insécable
    $t = $t -replace "`u2009", " "     # Espace fine
    $t = $t -replace "`u200B", ""      # Espace de largeur nulle
    $t = $t -replace "`u2028", "`n"    # Séparateur de ligne
    $t = $t -replace "`u2029", "`n`n"  # Séparateur de paragraphe

    # Normaliser les tirets (mais garder la distinction pour le contexte)
    $t = $t -replace "—", "-"          # Tiret cadratin
    $t = $t -replace "–", "-"          # Tiret demi-cadratin
    $t = $t -replace "•", "-"          # Puce
    $t = $t -replace "◦", "-"          # Puce cercle
    $t = $t -replace "▪", "-"          # Puce carrée
    $t = $t -replace "▫", "-"          # Puce carrée creuse

    # Normaliser les guillemets
    $t = $t -replace "[«»""]", '"'
    $t = $t -replace "['']", "'"

    # Normaliser les espaces autour des deux-points (standardiser)
    $t = [regex]::Replace($t, '\s*:\s*', ': ')

    # Supprimer les espaces multiples (mais pas les sauts de ligne)
    $t = [regex]::Replace($t, '[ \t]+', ' ')

    # Nettoyer les lignes vides multiples (max 2 consécutives)
    $t = [regex]::Replace($t, '\n{3,}', "`n`n")

    return $t
}

# ============================================================================
# FONCTIONS - DÉTECTION DES TITRES
# ============================================================================

function Build-HeadingRegex {
    <#
    .SYNOPSIS
        Construit une regex robuste pour détecter un titre de section.

    .DESCRIPTION
        Gère :
        - Variantes d'accents (é/è/e, à/a, etc.)
        - Espaces variables
        - Bullets/numérotation (-, •, 1., 2), etc.)
        - Deux-points optionnels avec contenu inline
        - Variantes orthographiques (&/et, s/(), etc.)
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Label
    )

    # Cas spéciaux avec logique personnalisée
    if ($Label -eq "Contact(s)") {
        # Contact, Contacts, Contact(s), Contact (s)
        $core = "Contacts?\s*(?:\(\s*s\s*\))?"
    }
    elseif ($Label -eq "Valeur ajoutée et différenciation") {
        # Accepter "et" ou "&" entre les deux parties
        # Variantes : Valeur ajoutée/ajoutee, différenciation/differenciation
        $core = "Valeur\s+ajout[eé]{1,2}e?\s+(?:et|&|/)\s+diff[eé]renciation"
    }
    else {
        # Normalisation générique
        $core = $Label

        # Remplacer les accents par des classes de caractères tolérantes
        $core = $core -replace '[éèêë]', '[eéèêë]'
        $core = $core -replace '[àâä]', '[aàâä]'
        $core = $core -replace '[îï]', '[iîï]'
        $core = $core -replace '[ôö]', '[oôö]'
        $core = $core -replace '[ùûü]', '[uùûü]'
        $core = $core -replace '[ç]', '[cç]'
        $core = $core -replace '[ÉÈÊË]', '[EÉÈÊË]'
        $core = $core -replace '[ÀÂÄ]', '[AÀÂÄ]'
        $core = $core -replace '[ÎÏ]', '[IÎÏ]'
        $core = $core -replace '[ÔÖ]', '[OÔÖ]'
        $core = $core -replace '[ÙÛÜ]', '[UÙÛÜ]'
        $core = $core -replace '[Ç]', '[CÇ]'

        # Virgules avec espaces flexibles
        $core = $core -replace ',', '\s*,\s*'

        # Espaces multiples → \s+
        $core = [regex]::Replace($core, '\s+', '\s+')
    }

    # Pattern complet :
    # - Début de ligne
    # - Espaces optionnels
    # - Bullets/numérotation optionnels : -, •, 1., 2), etc.
    # - Le titre (core pattern)
    # - Deux-points optionnels avec contenu inline capturé
    # - Fin de ligne

    $pattern = "(?im)^\s*" +                                    # Début, espaces
                "(?:[-•▪◦\d]+[\.\)]\s*)?" +                     # Bullets/numérotation optionnels
                "(?:$core)" +                                    # Titre
                "\s*" +                                          # Espaces après titre
                "(?::\s*(?<inline>.*?))?" +                      # ': contenu inline' optionnel
                "\s*$"                                           # Fin de ligne

    Write-Verbose "Regex pour '$Label' : $pattern"

    return [regex]::new($pattern)
}

function Find-Headings {
    <#
    .SYNOPSIS
        Trouve tous les titres de sections dans le texte.

    .DESCRIPTION
        Retourne une liste triée par position des titres trouvés,
        avec leur label, position, et éventuel contenu inline.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )

    $hits = [System.Collections.ArrayList]::new()

    foreach ($label in $Script:RequiredSections) {
        $rx = Build-HeadingRegex -Label $label
        $matches = $rx.Matches($Text)

        foreach ($m in $matches) {
            if ($m.Success) {
                $inline = ""
                if ($m.Groups['inline'].Success) {
                    $inline = $m.Groups['inline'].Value.Trim()
                }

                $hitObj = [PSCustomObject]@{
                    Label       = $label
                    Start       = $m.Index
                    End         = $m.Index + $m.Length
                    Inline      = $inline
                    LineNumber  = ($Text.Substring(0, $m.Index) -split "`n").Count
                }

                [void]$hits.Add($hitObj)

                Write-Verbose "  Trouvé '$label' à la ligne $($hitObj.LineNumber) (pos $($m.Index))"
                if ($inline) {
                    Write-Verbose "    Contenu inline : '$inline'"
                }
            }
        }
    }

    # Trier par position dans le texte
    return $hits | Sort-Object Start
}

# ============================================================================
# FONCTIONS - EXTRACTION DES BLOCS
# ============================================================================

function Extract-Blocks {
    <#
    .SYNOPSIS
        Extrait les blocs de contenu entre les titres de sections.

    .DESCRIPTION
        Chaque bloc commence à la fin du titre (ou au contenu inline)
        et se termine au début du prochain titre.
        Les sauts de ligne internes sont préservés.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Text,

        [Parameter(Mandatory=$false)]
        [string]$FileName = ""
    )

    $normalized = Normalize-Text -Text $Text
    $hits = Find-Headings -Text $normalized

    if ($hits.Count -eq 0) {
        Write-Log "Aucun titre de section trouvé dans '$FileName'" -Level Warning
    } else {
        Write-Verbose "  → $($hits.Count) titre(s) détecté(s)"
    }

    # Initialiser toutes les sections à vide
    $blocks = [ordered]@{}
    foreach ($label in $Script:RequiredSections) {
        $blocks[$label] = ""
    }

    # Extraire chaque bloc
    for ($i = 0; $i -lt $hits.Count; $i++) {
        $currentHit = $hits[$i]
        $label = $currentHit.Label

        # Début du contenu = juste après le titre
        $contentStart = $currentHit.End

        # Fin du contenu = début du prochain titre (ou fin de fichier)
        $contentEnd = if ($i -lt $hits.Count - 1) {
            $hits[$i + 1].Start
        } else {
            $normalized.Length
        }

        # Extraire le bloc
        $blockContent = ""
        if ($contentEnd -gt $contentStart) {
            $blockContent = $normalized.Substring($contentStart, $contentEnd - $contentStart).Trim()
        }

        # Ajouter le contenu inline en préfixe si présent
        if ($currentHit.Inline) {
            if ($blockContent) {
                $blockContent = $currentHit.Inline + "`n" + $blockContent
            } else {
                $blockContent = $currentHit.Inline
            }
        }

        $blocks[$label] = $blockContent.Trim()

        $lineCount = ($blockContent -split "`n").Count
        Write-Verbose "    Bloc '$label' : $lineCount ligne(s), $($blockContent.Length) caractères"
    }

    return $blocks
}

# ============================================================================
# FONCTIONS - EXTRACTION CLIENT/OBJET
# ============================================================================

function Get-ClientObjet {
    <#
    .SYNOPSIS
        Extrait le Client et l'Objet depuis les premières lignes.

    .DESCRIPTION
        Stratégie :
        1. Chercher des étiquettes explicites (Client:, Objet:, etc.) dans les 10 premières lignes
        2. Sinon, heuristique :
           - Client = 1ère ligne non vide
           - Objet = lignes 2-4 non vides, jusqu'à rencontrer un mot-clé de section
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )

    $normalized = Normalize-Text -Text $Text
    $allLines = ($normalized -split "`n" | ForEach-Object { $_.Trim() }) | Where-Object { $_ -ne "" }
    $top10 = $allLines | Select-Object -First 10

    # Fonction helper pour rechercher un pattern
    function Find-LabeledValue {
        Param(
            [string]$Pattern,
            [array]$Lines
        )
        foreach ($line in $Lines) {
            if ($line -match $Pattern) {
                return $Matches['val'].Trim()
            }
        }
        return $null
    }

    # Patterns pour Client
    $clientPattern = '^\s*(?:Client|Destinataire|Soci[eé]t[eé]|Entreprise)\s*[:\-–]\s*(?<val>.+)$'
    $client = Find-LabeledValue -Pattern $clientPattern -Lines $top10

    # Patterns pour Objet
    $objetPattern = '^\s*(?:Objet(?:\s+de\s+la\s+mission)?|Mission|Sujet)\s*[:\-–]\s*(?<val>.+)$'
    $objet = Find-LabeledValue -Pattern $objetPattern -Lines $top10

    # Heuristique si non trouvés
    $first4 = $allLines | Select-Object -First 4
    $sectionKeywords = '(?i)^(' +
        'P[eé]riode|Honoraires|Contexte|Valeur\s+ajout[eé]e|Contact|Contenu|' +
        'R[eé]sultats|Livrables|Diff[eé]renciation|Probl[eé]matique|Enjeux' +
        ')\b'

    if (-not $client -and $first4.Count -ge 1) {
        $client = $first4[0]
        Write-Verbose "  Client (heuristique) : ligne 1"
    }

    if (-not $objet -and $first4.Count -ge 2) {
        $objetLines = [System.Collections.ArrayList]::new()

        for ($i = 1; $i -lt [Math]::Min(4, $first4.Count); $i++) {
            $line = $first4[$i]

            # Arrêter si on rencontre un mot-clé de section
            if ($line -match $sectionKeywords) {
                Write-Verbose "  Objet : arrêt à la ligne $($i+1) (mot-clé détecté)"
                break
            }

            # Nettoyer les suffixes parasites (Période:, Honoraires:)
            $cleaned = $line -replace '(?i)\b(P[eé]riode|Honoraires)\s*:.*$', ''
            $cleaned = $cleaned.Trim()

            if ($cleaned) {
                [void]$objetLines.Add($cleaned)
            }
        }

        if ($objetLines.Count -gt 0) {
            $objet = $objetLines -join ' '
            Write-Verbose "  Objet (heuristique) : lignes 2-$($objetLines.Count + 1)"
        }
    }

    # Nettoyage final
    if ($client) {
        $client = $client.Trim(' """"«»''')
        $client = $client.Trim()
    }
    if ($objet) {
        $objet = $objet.Trim(' """"«»''')
        $objet = $objet.Trim()
    }

    return @{
        Client = ($client -as [string])
        Objet  = ($objet -as [string])
    }
}

# ============================================================================
# FONCTIONS - LECTURE DE FICHIERS
# ============================================================================

function Read-FileWithEncoding {
    <#
    .SYNOPSIS
        Lit un fichier en détectant automatiquement l'encodage.

    .DESCRIPTION
        Essaie successivement : UTF-16 LE, UTF-16 BE, UTF-8, ANSI/Windows-1252.
        Gère les BOM et les fichiers sans BOM.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Fichier introuvable : $Path"
    }

    # Lire les premiers octets pour détecter le BOM
    $bytes = [System.IO.File]::ReadAllBytes($Path)

    if ($bytes.Length -eq 0) {
        Write-Verbose "  Fichier vide : $Path"
        return ""
    }

    # Détection du BOM
    $encoding = $null
    $bomLength = 0

    if ($bytes.Length -ge 2) {
        # UTF-16 LE : FF FE
        if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            $encoding = [System.Text.Encoding]::Unicode
            $bomLength = 2
            Write-Verbose "  Encodage détecté : UTF-16 LE (BOM)"
        }
        # UTF-16 BE : FE FF
        elseif ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            $encoding = [System.Text.Encoding]::BigEndianUnicode
            $bomLength = 2
            Write-Verbose "  Encodage détecté : UTF-16 BE (BOM)"
        }
    }

    if ($bytes.Length -ge 3 -and -not $encoding) {
        # UTF-8 BOM : EF BB BF
        if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $encoding = [System.Text.UTF8Encoding]::new($false) # Pas de BOM en sortie
            $bomLength = 3
            Write-Verbose "  Encodage détecté : UTF-8 (BOM)"
        }
    }

    # Essayer avec Get-Content si pas de BOM détecté
    if (-not $encoding) {
        foreach ($enc in @('UTF8', 'Unicode', 'BigEndianUnicode', 'Default')) {
            try {
                $content = Get-Content -LiteralPath $Path -Raw -Encoding $enc -ErrorAction Stop
                if ($content) {
                    Write-Verbose "  Encodage détecté : $enc (essai Get-Content)"
                    return $content
                }
            }
            catch {
                continue
            }
        }

        # Fallback : UTF-8 sans BOM
        Write-Verbose "  Encodage par défaut : UTF-8 (fallback)"
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    }

    # Décoder en sautant le BOM
    if ($bomLength -gt 0 -and $bytes.Length -gt $bomLength) {
        $contentBytes = $bytes[$bomLength..($bytes.Length - 1)]
        return $encoding.GetString($contentBytes)
    }

    return $encoding.GetString($bytes)
}

# ============================================================================
# FONCTION PRINCIPALE
# ============================================================================

function Invoke-SectionExtraction {
    <#
    .SYNOPSIS
        Fonction principale d'extraction.
    #>
    [CmdletBinding()]
    Param(
        [string]$InputFolder,
        [string]$OutputCsv,
        [bool]$RecurseMode,
        [bool]$StrictMode
    )

    Write-Log "=== Extraction de sections vers CSV ===" -Level Info
    Write-Log "Dossier source : $InputFolder" -Level Info
    Write-Log "Fichier de sortie : $OutputCsv" -Level Info
    if ($RecurseMode) {
        Write-Log "Mode récursif : ACTIVÉ" -Level Info
    }
    if ($StrictMode) {
        Write-Log "Mode strict : ACTIVÉ" -Level Warning
    }
    Write-Log "" -Level Info

    # Rechercher les fichiers
    $searchParams = @{
        LiteralPath = $InputFolder
        File = $true
    }
    if ($RecurseMode) {
        $searchParams['Recurse'] = $true
    }

    $allFiles = Get-ChildItem @searchParams | Where-Object {
        $_.Extension -match '^\.(txt|md)$'
    }

    if (-not $allFiles -or $allFiles.Count -eq 0) {
        Write-Log "ERREUR : Aucun fichier .txt/.md trouvé dans '$InputFolder'" -Level Error
        throw "Aucun fichier à traiter"
    }

    Write-Log "Fichiers trouvés : $($allFiles.Count)" -Level Success
    Write-Log "" -Level Info

    # Traiter chaque fichier
    $results = [System.Collections.ArrayList]::new()
    $successCount = 0
    $errorCount = 0
    $fileIndex = 0

    foreach ($file in $allFiles) {
        $fileIndex++
        $progress = [math]::Round(($fileIndex / $allFiles.Count) * 100, 1)

        Write-Log "[$fileIndex/$($allFiles.Count)] Traitement : $($file.Name) ($progress%)" -Level Info

        try {
            # Lire le fichier
            $content = Read-FileWithEncoding -Path $file.FullName

            if ([string]::IsNullOrWhiteSpace($content)) {
                Write-Log "  AVERTISSEMENT : Fichier vide ou illisible" -Level Warning
                $errorCount++
                continue
            }

            Write-Verbose "  Contenu lu : $($content.Length) caractères"

            # Extraire les blocs
            $blocks = Extract-Blocks -Text $content -FileName $file.Name

            # Extraire Client/Objet
            $clientObjet = Get-ClientObjet -Text $content

            # Vérifier les sections manquantes en mode strict
            if ($StrictMode) {
                $missingSections = [System.Collections.ArrayList]::new()
                foreach ($section in $Script:RequiredSections) {
                    if ([string]::IsNullOrWhiteSpace($blocks[$section])) {
                        [void]$missingSections.Add($section)
                    }
                }

                if ($missingSections.Count -gt 0) {
                    $missingList = $missingSections -join "', '"
                    Write-Log "  ERREUR (Strict) : Sections manquantes : '$missingList'" -Level Error
                    throw "Sections requises manquantes en mode strict"
                }
            }

            # Construire la ligne de résultat
            $row = [ordered]@{
                'Fichier' = $file.Name
                'Chemin'  = $file.FullName
                'Client'  = $clientObjet.Client
                'Objet'   = $clientObjet.Objet
            }

            # Ajouter les sections
            foreach ($section in $Script:RequiredSections) {
                $row[$section] = $blocks[$section]
            }

            [void]$results.Add([PSCustomObject]$row)

            Write-Log "  ✓ Succès" -Level Success
            $successCount++
        }
        catch {
            Write-Log "  ✗ Erreur : $($_.Exception.Message)" -Level Error
            $errorCount++

            if ($StrictMode) {
                throw
            }
        }

        Write-Host "" # Ligne vide entre fichiers
    }

    # Exporter vers CSV
    Write-Log "=== Résumé ===" -Level Info
    Write-Log "Fichiers traités avec succès : $successCount" -Level Success
    if ($errorCount -gt 0) {
        Write-Log "Fichiers en erreur : $errorCount" -Level Warning
    }
    Write-Log "" -Level Info

    if ($results.Count -eq 0) {
        Write-Log "ERREUR : Aucune donnée à exporter" -Level Error
        throw "Aucune ligne extraite"
    }

    # Créer le dossier de sortie si nécessaire
    $outputDir = Split-Path -Parent $OutputCsv
    if ($outputDir -and -not (Test-Path $outputDir)) {
        Write-Verbose "Création du dossier : $outputDir"
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Exporter en UTF-8 sans BOM
    Write-Log "Export vers : $OutputCsv" -Level Info
    $results | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutputCsv -Force

    # Vérification
    $fileSize = (Get-Item $OutputCsv).Length
    $fileSizeKB = [math]::Round($fileSize / 1KB, 2)

    Write-Log "" -Level Info
    Write-Log "✓ EXPORT TERMINÉ" -Level Success
    Write-Log "  Fichier : $OutputCsv" -Level Success
    Write-Log "  Taille : $fileSizeKB Ko" -Level Success
    Write-Log "  Lignes : $($results.Count)" -Level Success

    return $results
}

# ============================================================================
# POINT D'ENTRÉE
# ============================================================================

try {
    $result = Invoke-SectionExtraction `
        -InputFolder $InputFolder `
        -OutputCsv $OutputCsv `
        -RecurseMode $Recurse.IsPresent `
        -StrictMode $Strict.IsPresent

    exit 0
}
catch {
    Write-Log "" -Level Error
    Write-Log "=== ERREUR FATALE ===" -Level Error
    Write-Log $_.Exception.Message -Level Error
    Write-Log $_.ScriptStackTrace -Level Error
    exit 1
}
