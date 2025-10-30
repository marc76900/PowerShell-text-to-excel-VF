@echo off
REM ============================================================================
REM Extract-Sections.bat
REM Wrapper batch pour Extract-Sections.ps1
REM Permet l'exécution facile même si les scripts PS1 sont bloqués
REM ============================================================================

setlocal EnableDelayedExpansion

REM Couleurs et symboles
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "RESET=[0m"

echo.
echo %GREEN%========================================%RESET%
echo %GREEN%  Extract-Sections - Launcher%RESET%
echo %GREEN%========================================%RESET%
echo.

REM Vérifier que PowerShell est disponible
where powershell.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %RED%ERREUR : PowerShell n'est pas trouvé dans le PATH%RESET%
    echo.
    echo Veuillez installer PowerShell ou vérifier votre installation.
    pause
    exit /b 1
)

REM Vérifier que le script PS1 existe
set "SCRIPT_PATH=%~dp0Extract-Sections.ps1"
if not exist "%SCRIPT_PATH%" (
    echo %RED%ERREUR : Extract-Sections.ps1 introuvable%RESET%
    echo.
    echo Chemin attendu : %SCRIPT_PATH%
    pause
    exit /b 1
)

echo %YELLOW%Script PowerShell : %RESET%%SCRIPT_PATH%
echo.

REM Si aucun argument, afficher l'aide
if "%~1"=="" (
    echo %YELLOW%Usage :%RESET%
    echo   %~nx0 -InputFolder ^<dossier^> -OutputCsv ^<fichier.csv^> [options]
    echo.
    echo %YELLOW%Exemples :%RESET%
    echo   %~nx0 -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
    echo   %~nx0 -InputFolder ".\docs" -Recurse -Strict
    echo.
    echo %YELLOW%Options disponibles :%RESET%
    echo   -InputFolder ^<dossier^>     Dossier contenant les fichiers .txt/.md
    echo   -OutputCsv ^<fichier.csv^>   Fichier CSV de sortie
    echo   -Recurse                    Parcourir les sous-dossiers
    echo   -Strict                     Mode strict (échoue si sections manquantes^)
    echo   -Verbose                    Logs détaillés
    echo.
    echo %YELLOW%Pour plus d'aide :%RESET%
    echo   powershell -File "%SCRIPT_PATH%" -?
    echo.
    pause
    exit /b 0
)

REM Construire la commande PowerShell avec tous les arguments
set "PS_ARGS="
:parse_args
if not "%~1"=="" (
    set "PS_ARGS=!PS_ARGS! %1"
    shift
    goto parse_args
)

echo %YELLOW%Exécution en cours...%RESET%
echo.

REM Exécuter le script PowerShell avec bypass de l'ExecutionPolicy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" %PS_ARGS%

REM Capturer le code de sortie
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if %EXIT_CODE% EQU 0 (
    echo %GREEN%========================================%RESET%
    echo %GREEN%  Exécution terminée avec succès !%RESET%
    echo %GREEN%========================================%RESET%
) else (
    echo %RED%========================================%RESET%
    echo %RED%  Erreur lors de l'exécution%RESET%
    echo %RED%  Code de sortie : %EXIT_CODE%%RESET%
    echo %RED%========================================%RESET%
)

echo.
pause
exit /b %EXIT_CODE%
