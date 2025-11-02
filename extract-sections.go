package main

import (
	"bytes"
	"encoding/csv"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"golang.org/x/text/encoding/unicode"
	"golang.org/x/text/transform"
)

// Version du script
const Version = "2.0.0-go"

// Couleurs pour les logs (Windows compatible)
const (
	ColorReset  = "\033[0m"
	ColorGreen  = "\033[32m"
	ColorYellow = "\033[33m"
	ColorRed    = "\033[31m"
	ColorCyan   = "\033[36m"
)

// Sections requises dans l'ordre
var RequiredSections = []string{
	"Contexte, problématique et enjeux",
	"Valeur ajoutée et différenciation",
	"Contact(s)",
	"Période",
	"Honoraires",
	"Contenu, résultats et livrables",
}

// Heading représente un titre trouvé dans le texte
type Heading struct {
	Label      string
	Start      int
	End        int
	Inline     string
	LineNumber int
}

// Config contient les paramètres du script
type Config struct {
	InputFolder string
	OutputCSV   string
	Recurse     bool
	Strict      bool
	Verbose     bool
}

// FileResult contient les données extraites d'un fichier
type FileResult struct {
	Fichier  string
	Chemin   string
	Client   string
	Objet    string
	Sections map[string]string
}

// ============================================================================
// FONCTIONS DE LOG
// ============================================================================

func logMessage(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	var prefix, color string

	switch level {
	case "success":
		prefix = "[✓]"
		color = ColorGreen
	case "warning":
		prefix = "[!]"
		color = ColorYellow
	case "error":
		prefix = "[✗]"
		color = ColorRed
	case "info":
		prefix = "[i]"
		color = ColorCyan
	default:
		prefix = "[i]"
		color = ""
	}

	fmt.Printf("%s %s%s%s %s\n", timestamp, color, prefix, ColorReset, message)
}

func logInfo(message string) {
	logMessage("info", message)
}

func logSuccess(message string) {
	logMessage("success", message)
}

func logWarning(message string) {
	logMessage("warning", message)
}

func logError(message string) {
	logMessage("error", message)
}

func logVerbose(config *Config, message string) {
	if config.Verbose {
		fmt.Println("  →", message)
	}
}

// ============================================================================
// DÉTECTION ET LECTURE D'ENCODAGE
// ============================================================================

func readFileWithEncoding(path string) (string, error) {
	// Lire les octets bruts
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}

	if len(data) == 0 {
		return "", nil
	}

	// Détecter le BOM
	// UTF-16 LE : FF FE
	if len(data) >= 2 && data[0] == 0xFF && data[1] == 0xFE {
		decoder := unicode.UTF16(unicode.LittleEndian, unicode.UseBOM).NewDecoder()
		decoded, _, err := transform.Bytes(decoder, data)
		if err != nil {
			return "", err
		}
		return string(decoded), nil
	}

	// UTF-16 BE : FE FF
	if len(data) >= 2 && data[0] == 0xFE && data[1] == 0xFF {
		decoder := unicode.UTF16(unicode.BigEndian, unicode.UseBOM).NewDecoder()
		decoded, _, err := transform.Bytes(decoder, data)
		if err != nil {
			return "", err
		}
		return string(decoded), nil
	}

	// UTF-8 BOM : EF BB BF
	if len(data) >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF {
		return string(data[3:]), nil
	}

	// Pas de BOM : essayer UTF-8
	if utf8.Valid(data) {
		return string(data), nil
	}

	// Fallback : ISO-8859-1 / Windows-1252 (approximation)
	return string(data), nil
}

// ============================================================================
// NORMALISATION DU TEXTE
// ============================================================================

func normalizeText(text string) string {
	// Uniformiser les retours à la ligne
	text = strings.ReplaceAll(text, "\r\n", "\n")
	text = strings.ReplaceAll(text, "\r", "\n")

	// Espaces spéciaux → espaces normaux
	text = strings.ReplaceAll(text, "\u00A0", " ")  // Espace insécable
	text = strings.ReplaceAll(text, "\u202F", " ")  // Espace fine insécable
	text = strings.ReplaceAll(text, "\u2009", " ")  // Espace fine
	text = strings.ReplaceAll(text, "\u200B", "")   // Espace de largeur nulle
	text = strings.ReplaceAll(text, "\u2028", "\n") // Séparateur de ligne
	text = strings.ReplaceAll(text, "\u2029", "\n\n") // Séparateur de paragraphe

	// Normaliser les tirets
	text = strings.ReplaceAll(text, "—", "-") // Tiret cadratin
	text = strings.ReplaceAll(text, "–", "-") // Tiret demi-cadratin
	text = strings.ReplaceAll(text, "•", "-") // Puce
	text = strings.ReplaceAll(text, "◦", "-")
	text = strings.ReplaceAll(text, "▪", "-")
	text = strings.ReplaceAll(text, "▫", "-")

	// Normaliser les guillemets
	text = strings.ReplaceAll(text, "«", "\"")
	text = strings.ReplaceAll(text, "»", "\"")
	text = strings.ReplaceAll(text, """, "\"")
	text = strings.ReplaceAll(text, """, "\"")
	text = strings.ReplaceAll(text, "'", "'")
	text = strings.ReplaceAll(text, "'", "'")

	// Normaliser les deux-points
	re := regexp.MustCompile(`\s*:\s*`)
	text = re.ReplaceAllString(text, ": ")

	// Supprimer les espaces multiples (mais pas les sauts de ligne)
	re = regexp.MustCompile(`[ \t]+`)
	text = re.ReplaceAllString(text, " ")

	// Nettoyer les lignes vides multiples
	re = regexp.MustCompile(`\n{3,}`)
	text = re.ReplaceAllString(text, "\n\n")

	return text
}

// ============================================================================
// CONSTRUCTION DES REGEX POUR LES TITRES
// ============================================================================

func buildHeadingRegex(label string) *regexp.Regexp {
	var core string

	switch label {
	case "Contact(s)":
		core = `Contacts?\s*(?:\(\s*s\s*\))?`

	case "Valeur ajoutée et différenciation":
		core = `Valeur\s+ajout[eé]{1,2}e?\s+(?:et|&|/)\s+diff[eé]renciation`

	default:
		core = label

		// Remplacer les accents par des classes de caractères tolérantes
		core = regexp.MustCompile(`[éèêë]`).ReplaceAllString(core, `[eéèêë]`)
		core = regexp.MustCompile(`[àâä]`).ReplaceAllString(core, `[aàâä]`)
		core = regexp.MustCompile(`[îï]`).ReplaceAllString(core, `[iîï]`)
		core = regexp.MustCompile(`[ôö]`).ReplaceAllString(core, `[oôö]`)
		core = regexp.MustCompile(`[ùûü]`).ReplaceAllString(core, `[uùûü]`)
		core = regexp.MustCompile(`[ç]`).ReplaceAllString(core, `[cç]`)
		core = regexp.MustCompile(`[ÉÈÊË]`).ReplaceAllString(core, `[EÉÈÊË]`)
		core = regexp.MustCompile(`[ÀÂÄ]`).ReplaceAllString(core, `[AÀÂÄ]`)
		core = regexp.MustCompile(`[ÎÏ]`).ReplaceAllString(core, `[IÎÏ]`)
		core = regexp.MustCompile(`[ÔÖ]`).ReplaceAllString(core, `[OÔÖ]`)
		core = regexp.MustCompile(`[ÙÛÜ]`).ReplaceAllString(core, `[UÙÛÜ]`)
		core = regexp.MustCompile(`[Ç]`).ReplaceAllString(core, `[CÇ]`)

		// Virgules avec espaces flexibles
		core = strings.ReplaceAll(core, ",", `\s*,\s*`)

		// Espaces multiples → \s+
		re := regexp.MustCompile(`\s+`)
		core = re.ReplaceAllString(core, `\s+`)
	}

	// Pattern complet
	pattern := `(?im)^\s*(?:[-•▪◦\d]+[\.\)]\s*)?(?:` + core + `)\s*(?::\s*(?P<inline>.*?))?\s*$`

	return regexp.MustCompile(pattern)
}

// ============================================================================
// RECHERCHE DES TITRES
// ============================================================================

func findHeadings(text string, config *Config) []Heading {
	var headings []Heading

	for _, label := range RequiredSections {
		rx := buildHeadingRegex(label)
		matches := rx.FindAllStringSubmatchIndex(text, -1)

		for _, match := range matches {
			start := match[0]
			end := match[1]

			// Extraire le contenu inline si présent
			inline := ""
			if len(match) >= 4 && match[2] >= 0 {
				inline = strings.TrimSpace(text[match[2]:match[3]])
			}

			// Calculer le numéro de ligne
			lineNumber := strings.Count(text[:start], "\n") + 1

			heading := Heading{
				Label:      label,
				Start:      start,
				End:        end,
				Inline:     inline,
				LineNumber: lineNumber,
			}

			headings = append(headings, heading)

			logVerbose(config, fmt.Sprintf("Trouvé '%s' à la ligne %d (pos %d)", label, lineNumber, start))
			if inline != "" {
				logVerbose(config, fmt.Sprintf("  Contenu inline: '%s'", inline))
			}
		}
	}

	return headings
}

// ============================================================================
// EXTRACTION DES BLOCS
// ============================================================================

func extractBlocks(text string, config *Config, filename string) map[string]string {
	normalized := normalizeText(text)
	headings := findHeadings(normalized, config)

	if len(headings) == 0 {
		logWarning(fmt.Sprintf("Aucun titre de section trouvé dans '%s'", filename))
	} else {
		logVerbose(config, fmt.Sprintf("→ %d titre(s) détecté(s)", len(headings)))
	}

	// Initialiser toutes les sections à vide
	blocks := make(map[string]string)
	for _, label := range RequiredSections {
		blocks[label] = ""
	}

	// Extraire chaque bloc
	for i, heading := range headings {
		contentStart := heading.End
		contentEnd := len(normalized)

		if i < len(headings)-1 {
			contentEnd = headings[i+1].Start
		}

		// Extraire le contenu
		blockContent := ""
		if contentEnd > contentStart {
			blockContent = strings.TrimSpace(normalized[contentStart:contentEnd])
		}

		// Ajouter le contenu inline en préfixe si présent
		if heading.Inline != "" {
			if blockContent != "" {
				blockContent = heading.Inline + "\n" + blockContent
			} else {
				blockContent = heading.Inline
			}
		}

		blocks[heading.Label] = blockContent

		lineCount := strings.Count(blockContent, "\n") + 1
		logVerbose(config, fmt.Sprintf("  Bloc '%s': %d ligne(s), %d caractères", heading.Label, lineCount, len(blockContent)))
	}

	return blocks
}

// ============================================================================
// EXTRACTION CLIENT / OBJET
// ============================================================================

func extractClientObjet(text string) (string, string) {
	normalized := normalizeText(text)
	lines := strings.Split(normalized, "\n")

	// Filtrer les lignes vides
	var nonEmptyLines []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" {
			nonEmptyLines = append(nonEmptyLines, trimmed)
		}
	}

	if len(nonEmptyLines) == 0 {
		return "", ""
	}

	// Prendre les 10 premières lignes pour la recherche d'étiquettes
	top10 := nonEmptyLines
	if len(nonEmptyLines) > 10 {
		top10 = nonEmptyLines[:10]
	}

	// Patterns pour Client
	clientPattern := regexp.MustCompile(`(?i)^\s*(?:Client|Destinataire|Soci[eé]t[eé]|Entreprise)\s*[:\-–]\s*(.+)$`)
	client := ""
	for _, line := range top10 {
		if match := clientPattern.FindStringSubmatch(line); match != nil {
			client = strings.TrimSpace(match[1])
			break
		}
	}

	// Patterns pour Objet
	objetPattern := regexp.MustCompile(`(?i)^\s*(?:Objet(?:\s+de\s+la\s+mission)?|Mission|Sujet)\s*[:\-–]\s*(.+)$`)
	objet := ""
	for _, line := range top10 {
		if match := objetPattern.FindStringSubmatch(line); match != nil {
			objet = strings.TrimSpace(match[1])
			break
		}
	}

	// Heuristique si non trouvés
	first4 := nonEmptyLines
	if len(nonEmptyLines) > 4 {
		first4 = nonEmptyLines[:4]
	}

	sectionKeywords := regexp.MustCompile(`(?i)^(P[eé]riode|Honoraires|Contexte|Valeur\s+ajout[eé]e|Contact|Contenu|R[eé]sultats|Livrables|Diff[eé]renciation|Probl[eé]matique|Enjeux)\b`)

	if client == "" && len(first4) >= 1 {
		client = first4[0]
	}

	if objet == "" && len(first4) >= 2 {
		var objetLines []string
		for i := 1; i < len(first4); i++ {
			line := first4[i]

			// Arrêter si on rencontre un mot-clé de section
			if sectionKeywords.MatchString(line) {
				break
			}

			// Nettoyer les suffixes parasites
			cleanPattern := regexp.MustCompile(`(?i)\b(P[eé]riode|Honoraires)\s*:.*$`)
			cleaned := cleanPattern.ReplaceAllString(line, "")
			cleaned = strings.TrimSpace(cleaned)

			if cleaned != "" {
				objetLines = append(objetLines, cleaned)
			}
		}

		if len(objetLines) > 0 {
			objet = strings.Join(objetLines, " ")
		}
	}

	// Nettoyage final
	client = strings.Trim(client, ` """«»''`)
	objet = strings.Trim(objet, ` """«»''`)

	return client, objet
}

// ============================================================================
// TRAITEMENT D'UN FICHIER
// ============================================================================

func processFile(path string, config *Config) (*FileResult, error) {
	// Lire le fichier
	content, err := readFileWithEncoding(path)
	if err != nil {
		return nil, fmt.Errorf("erreur de lecture: %w", err)
	}

	if strings.TrimSpace(content) == "" {
		return nil, fmt.Errorf("fichier vide ou illisible")
	}

	logVerbose(config, fmt.Sprintf("Contenu lu: %d caractères", len(content)))

	// Extraire les blocs
	blocks := extractBlocks(content, config, filepath.Base(path))

	// Extraire Client/Objet
	client, objet := extractClientObjet(content)

	// Vérifier les sections manquantes en mode strict
	if config.Strict {
		var missingSections []string
		for _, section := range RequiredSections {
			if strings.TrimSpace(blocks[section]) == "" {
				missingSections = append(missingSections, section)
			}
		}

		if len(missingSections) > 0 {
			return nil, fmt.Errorf("sections requises manquantes: %s", strings.Join(missingSections, ", "))
		}
	}

	result := &FileResult{
		Fichier:  filepath.Base(path),
		Chemin:   path,
		Client:   client,
		Objet:    objet,
		Sections: blocks,
	}

	return result, nil
}

// ============================================================================
// RECHERCHE DES FICHIERS
// ============================================================================

func findFiles(inputFolder string, recurse bool) ([]string, error) {
	var files []string

	if recurse {
		err := filepath.Walk(inputFolder, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if !info.IsDir() {
				ext := strings.ToLower(filepath.Ext(path))
				if ext == ".txt" || ext == ".md" {
					files = append(files, path)
				}
			}
			return nil
		})
		if err != nil {
			return nil, err
		}
	} else {
		entries, err := os.ReadDir(inputFolder)
		if err != nil {
			return nil, err
		}

		for _, entry := range entries {
			if !entry.IsDir() {
				ext := strings.ToLower(filepath.Ext(entry.Name()))
				if ext == ".txt" || ext == ".md" {
					files = append(files, filepath.Join(inputFolder, entry.Name()))
				}
			}
		}
	}

	return files, nil
}

// ============================================================================
// EXPORT CSV
// ============================================================================

func exportCSV(results []*FileResult, outputPath string) error {
	// Créer le dossier de sortie si nécessaire
	dir := filepath.Dir(outputPath)
	if dir != "" && dir != "." {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("impossible de créer le dossier: %w", err)
		}
	}

	// Créer le fichier CSV
	file, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("impossible de créer le CSV: %w", err)
	}
	defer file.Close()

	// Écrire le BOM UTF-8 (pour Excel Windows)
	file.Write([]byte{0xEF, 0xBB, 0xBF})

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// En-têtes
	headers := []string{"Fichier", "Chemin", "Client", "Objet"}
	headers = append(headers, RequiredSections...)
	if err := writer.Write(headers); err != nil {
		return fmt.Errorf("erreur d'écriture des en-têtes: %w", err)
	}

	// Données
	for _, result := range results {
		row := []string{
			result.Fichier,
			result.Chemin,
			result.Client,
			result.Objet,
		}

		for _, section := range RequiredSections {
			row = append(row, result.Sections[section])
		}

		if err := writer.Write(row); err != nil {
			return fmt.Errorf("erreur d'écriture de ligne: %w", err)
		}
	}

	return nil
}

// ============================================================================
// FONCTION PRINCIPALE
// ============================================================================

func run(config *Config) error {
	logInfo("=== Extraction de sections vers CSV ===")
	logInfo(fmt.Sprintf("Dossier source: %s", config.InputFolder))
	logInfo(fmt.Sprintf("Fichier de sortie: %s", config.OutputCSV))

	if config.Recurse {
		logInfo("Mode récursif: ACTIVÉ")
	}
	if config.Strict {
		logWarning("Mode strict: ACTIVÉ")
	}
	fmt.Println()

	// Rechercher les fichiers
	files, err := findFiles(config.InputFolder, config.Recurse)
	if err != nil {
		return fmt.Errorf("erreur de recherche des fichiers: %w", err)
	}

	if len(files) == 0 {
		logError(fmt.Sprintf("Aucun fichier .txt/.md trouvé dans '%s'", config.InputFolder))
		return fmt.Errorf("aucun fichier à traiter")
	}

	logSuccess(fmt.Sprintf("Fichiers trouvés: %d", len(files)))
	fmt.Println()

	// Traiter chaque fichier
	var results []*FileResult
	successCount := 0
	errorCount := 0

	for i, file := range files {
		progress := float64(i+1) / float64(len(files)) * 100
		logInfo(fmt.Sprintf("[%d/%d] Traitement: %s (%.1f%%)", i+1, len(files), filepath.Base(file), progress))

		result, err := processFile(file, config)
		if err != nil {
			logError(fmt.Sprintf("  ✗ Erreur: %v", err))
			errorCount++

			if config.Strict {
				return err
			}
			continue
		}

		results = append(results, result)
		logSuccess("  ✓ Succès")
		successCount++
		fmt.Println()
	}

	// Résumé
	logInfo("=== Résumé ===")
	logSuccess(fmt.Sprintf("Fichiers traités avec succès: %d", successCount))
	if errorCount > 0 {
		logWarning(fmt.Sprintf("Fichiers en erreur: %d", errorCount))
	}
	fmt.Println()

	if len(results) == 0 {
		logError("Aucune donnée à exporter")
		return fmt.Errorf("aucune ligne extraite")
	}

	// Exporter vers CSV
	logInfo(fmt.Sprintf("Export vers: %s", config.OutputCSV))
	if err := exportCSV(results, config.OutputCSV); err != nil {
		return fmt.Errorf("erreur d'export CSV: %w", err)
	}

	// Vérification
	fileInfo, err := os.Stat(config.OutputCSV)
	if err != nil {
		return fmt.Errorf("impossible de vérifier le fichier de sortie: %w", err)
	}

	fileSizeKB := float64(fileInfo.Size()) / 1024.0

	fmt.Println()
	logSuccess("✓ EXPORT TERMINÉ")
	logSuccess(fmt.Sprintf("  Fichier: %s", config.OutputCSV))
	logSuccess(fmt.Sprintf("  Taille: %.2f Ko", fileSizeKB))
	logSuccess(fmt.Sprintf("  Lignes: %d", len(results)))

	return nil
}

// ============================================================================
// POINT D'ENTRÉE
// ============================================================================

func main() {
	// Paramètres de ligne de commande
	config := &Config{}

	flag.StringVar(&config.InputFolder, "InputFolder", "./mes_textes", "Dossier contenant les fichiers .txt/.md")
	flag.StringVar(&config.InputFolder, "i", "./mes_textes", "Dossier contenant les fichiers .txt/.md (raccourci)")
	flag.StringVar(&config.OutputCSV, "OutputCsv", "./sections.csv", "Fichier CSV de sortie")
	flag.StringVar(&config.OutputCSV, "o", "./sections.csv", "Fichier CSV de sortie (raccourci)")
	flag.BoolVar(&config.Recurse, "Recurse", false, "Parcourir les sous-dossiers")
	flag.BoolVar(&config.Recurse, "r", false, "Parcourir les sous-dossiers (raccourci)")
	flag.BoolVar(&config.Strict, "Strict", false, "Mode strict (échoue si sections manquantes)")
	flag.BoolVar(&config.Strict, "s", false, "Mode strict (raccourci)")
	flag.BoolVar(&config.Verbose, "Verbose", false, "Logs détaillés")
	flag.BoolVar(&config.Verbose, "v", false, "Logs détaillés (raccourci)")

	version := flag.Bool("version", false, "Afficher la version")

	flag.Parse()

	if *version {
		fmt.Printf("Extract-Sections version %s\n", Version)
		os.Exit(0)
	}

	// Exécuter
	if err := run(config); err != nil {
		fmt.Println()
		logError("=== ERREUR FATALE ===")
		logError(err.Error())
		os.Exit(1)
	}

	os.Exit(0)
}
