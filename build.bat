@echo off
REM ============================================================================
REM build.bat
REM Script de compilation pour extract-sections.exe (version Go)
REM ============================================================================

setlocal EnableDelayedExpansion

REM Couleurs
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "CYAN=[96m"
set "RESET=[0m"

echo.
echo %CYAN%========================================%RESET%
echo %CYAN%  Extract-Sections - Compilation Go%RESET%
echo %CYAN%========================================%RESET%
echo.

REM Vérifier que Go est installé
where go.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %RED%ERREUR : Go n'est pas installé ou pas dans le PATH%RESET%
    echo.
    echo %YELLOW%Installation requise :%RESET%
    echo   1. Téléchargez Go depuis https://go.dev/dl/
    echo   2. Installez le fichier .msi
    echo   3. Redémarrez ce terminal
    echo.
    pause
    exit /b 1
)

REM Afficher la version de Go
for /f "tokens=3" %%v in ('go version') do set GO_VERSION=%%v
echo %GREEN%Go détecté : %GO_VERSION%%RESET%
echo.

REM Vérifier que les fichiers sources existent
if not exist "extract-sections.go" (
    echo %RED%ERREUR : extract-sections.go introuvable%RESET%
    echo.
    echo Assurez-vous d'exécuter ce script depuis le dossier du projet.
    pause
    exit /b 1
)

if not exist "go.mod" (
    echo %RED%ERREUR : go.mod introuvable%RESET%
    echo.
    echo Assurez-vous d'exécuter ce script depuis le dossier du projet.
    pause
    exit /b 1
)

echo %YELLOW%Étape 1/3 : Téléchargement des dépendances...%RESET%
echo.
go mod download
if %ERRORLEVEL% NEQ 0 (
    echo %RED%ERREUR lors du téléchargement des dépendances%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ Dépendances téléchargées%RESET%
echo.

echo %YELLOW%Étape 2/3 : Nettoyage du go.mod...%RESET%
echo.
go mod tidy
echo %GREEN%✓ go.mod nettoyé%RESET%
echo.

echo %YELLOW%Étape 3/3 : Compilation...%RESET%
echo.
go build -o extract-sections.exe extract-sections.go
if %ERRORLEVEL% NEQ 0 (
    echo %RED%ERREUR lors de la compilation%RESET%
    pause
    exit /b 1
)

REM Vérifier que l'exe a été créé
if not exist "extract-sections.exe" (
    echo %RED%ERREUR : extract-sections.exe non créé%RESET%
    pause
    exit /b 1
)

REM Afficher la taille du fichier
for %%F in (extract-sections.exe) do set FILE_SIZE=%%~zF
set /a FILE_SIZE_MB=FILE_SIZE/1024/1024
set /a FILE_SIZE_KB=FILE_SIZE/1024

echo %GREEN%✓ Compilation réussie !%RESET%
echo.

echo %CYAN%========================================%RESET%
echo %CYAN%  SUCCÈS%RESET%
echo %CYAN%========================================%RESET%
echo.
echo   Exécutable : %GREEN%extract-sections.exe%RESET%
echo   Taille     : %GREEN%!FILE_SIZE_KB! Ko (~!FILE_SIZE_MB! Mo)%RESET%
echo.
echo %YELLOW%Test rapide :%RESET%
echo   extract-sections.exe -i ".\mes_textes" -o "test_go.csv"
echo.
echo %YELLOW%Usage :%RESET%
echo   extract-sections.exe -InputFolder ^<dossier^> -OutputCsv ^<fichier.csv^>
echo.
echo %YELLOW%Aide complète :%RESET%
echo   extract-sections.exe -h
echo.
echo %YELLOW%Documentation :%RESET%
echo   Voir BUILD_GO.md pour plus de détails
echo.

echo %CYAN%========================================%RESET%

pause
