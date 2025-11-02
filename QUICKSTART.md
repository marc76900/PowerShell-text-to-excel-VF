# 🚀 Guide de démarrage rapide

## ⚡ En 2 minutes

### 1️⃣ Préparez vos fichiers

Placez vos fichiers `.txt` ou `.md` dans un dossier (ex: `mes_textes/`)

### 2️⃣ Exécutez le script

```powershell
.\Extract-Sections.ps1 -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
```

### 3️⃣ Ouvrez le CSV

Le fichier `resultats.csv` contient toutes vos sections extraites !

---

## 📝 Structure requise des fichiers

Vos fichiers texte doivent contenir des titres de sections parmi :

- `Contexte, problématique et enjeux`
- `Valeur ajoutée et différenciation`
- `Contact(s)`
- `Période`
- `Honoraires`
- `Contenu, résultats et livrables`

**Exemple minimal** :

```text
Mon Client SA
Objet de la mission

Contexte, problématique et enjeux:
Voici le contexte du projet...

Valeur ajoutée et différenciation:
Notre approche unique...

Contact(s):
Jean Dupont - jean@example.com

Période:
Janvier - Mars 2025

Honoraires:
100 000 € HT

Contenu, résultats et livrables:
- Livrable 1
- Livrable 2
```

---

## 🔧 Options utiles

### Parcourir les sous-dossiers

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Recurse
```

### Mode strict (valider que toutes les sections sont présentes)

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Strict
```

### Voir les logs détaillés

```powershell
.\Extract-Sections.ps1 -InputFolder ".\docs" -Verbose
```

---

## 🐛 Problème courant : "Exécution de scripts désactivée"

**Erreur** :

```text
Impossible de charger le fichier car l'exécution de scripts est désactivée
```

**Solution rapide** :

```powershell
# Débloquer le fichier
Unblock-File -Path .\Extract-Sections.ps1

# OU exécuter avec bypass
PowerShell.exe -ExecutionPolicy Bypass -File .\Extract-Sections.ps1
```

---

## ✅ Tester l'installation

Lancez les tests automatiques :

```powershell
.\Test-Extraction.ps1
```

Si tout fonctionne, vous verrez :

```text
✓ TOUS LES TESTS SONT PASSÉS !
```

---

## 📚 Besoin de plus d'aide ?

- **Documentation complète** : [DOCUMENTATION.md](DOCUMENTATION.md)
- **README** : [README.md](README.md)
- **Support** : Ouvrez une [issue](https://github.com/votre-repo/issues)

---

**Prêt à traiter des centaines de fichiers ? C'est parti ! 🚀**
