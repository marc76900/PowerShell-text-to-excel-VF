# 🔧 Résoudre l'erreur "l'exécution de scripts est désactivée"

## ❌ Erreur que vous rencontrez

```
.\Extract-Sections.ps1 : Impossible de charger le fichier
C:\Users\MRO\Desktop\PowerShell-text-to-excel-VF\Extract-Sections.ps1,
car l'exécution de scripts est désactivée sur ce système.
```

## ✅ Solutions (par ordre de préférence)

---

## 🥇 Solution 1 : Utiliser la version Go (RECOMMANDÉ)

**La version Go résout définitivement ce problème !**

### Pourquoi ?

- ✅ **Exécutable natif .exe** → Aucun problème de politique d'exécution
- ✅ **Aucune dépendance** → Tout est intégré
- ✅ **5x plus rapide** que PowerShell
- ✅ **Portable** → Un seul fichier à copier

### Comment faire ?

#### Étape 1 : Installer Go (une seule fois)

1. Téléchargez Go : https://go.dev/dl/
2. Choisissez **Windows AMD64** (fichier `.msi`)
3. Installez en double-cliquant (acceptez les valeurs par défaut)
4. Redémarrez votre terminal

#### Étape 2 : Compiler l'exécutable

```cmd
cd C:\Users\MRO\Desktop\PowerShell-text-to-excel-VF
build.bat
```

**Résultat** : Vous obtenez `extract-sections.exe` (8-10 Mo)

#### Étape 3 : Utiliser

```cmd
extract-sections.exe -i ".\mes_textes" -o "resultats.csv"
```

**Ça marche immédiatement !** Plus de problème de politique d'exécution.

📘 **Guide complet** : [BUILD_GO.md](BUILD_GO.md)

---

## 🥈 Solution 2 : Débloquer le script PowerShell

Si vous voulez absolument utiliser PowerShell :

### Méthode A : Débloquer le fichier

```powershell
# Débloquer le script
Unblock-File -Path "C:\Users\MRO\Desktop\PowerShell-text-to-excel-VF\Extract-Sections.ps1"

# Vérifier
Get-Item "C:\Users\MRO\Desktop\PowerShell-text-to-excel-VF\Extract-Sections.ps1" | Select-Object -ExpandProperty Attributes

# Puis exécuter
.\Extract-Sections.ps1 -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
```

### Méthode B : Bypass ExecutionPolicy (temporaire)

```powershell
PowerShell.exe -ExecutionPolicy Bypass -File ".\Extract-Sections.ps1" -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
```

### Méthode C : Changer la politique d'exécution (pour la session)

```powershell
# Changer temporairement (pour cette session seulement)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Puis exécuter normalement
.\Extract-Sections.ps1 -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
```

### Méthode D : Changer la politique d'exécution (permanent, nécessite admin)

⚠️ **Nécessite des droits administrateur**

```powershell
# Ouvrir PowerShell en tant qu'administrateur
# Puis :
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Redémarrer PowerShell normalement
.\Extract-Sections.ps1 -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
```

---

## 🥉 Solution 3 : Utiliser le wrapper batch

Le fichier `Extract-Sections.bat` contourne le problème :

```cmd
Extract-Sections.bat -InputFolder ".\mes_textes" -OutputCsv ".\resultats.csv"
```

Le wrapper batch utilise `-ExecutionPolicy Bypass` automatiquement.

---

## 🎯 Comparaison des solutions

| Solution | Avantages | Inconvénients | Recommandation |
|----------|-----------|---------------|----------------|
| **Version Go** | ✅ Aucun problème<br>✅ Performance<br>✅ Portable | ❌ Nécessite Go pour compiler (une fois) | ⭐⭐⭐⭐⭐ **MEILLEURE** |
| **Débloquer fichier** | ✅ Simple<br>✅ Pas de droits admin | ❌ À refaire si fichier téléchargé à nouveau | ⭐⭐⭐ Acceptable |
| **Bypass temporaire** | ✅ Aucune modification système | ❌ À retaper à chaque fois | ⭐⭐ Acceptable |
| **Changer politique** | ✅ Permanent | ❌ Nécessite droits admin<br>❌ Risque sécurité | ⭐ Pas recommandé |
| **Wrapper batch** | ✅ Automatique | ❌ Contournement, pas une vraie solution | ⭐⭐ Dépannage |

---

## 🚀 Recommandation finale

### Pour votre cas (environnement verrouillé)

1. **Utilisez la version Go** (Solution 1)
   - C'est la solution définitive et la plus professionnelle
   - Aucun problème de politique d'exécution
   - Performance maximale
   - Facilement distribuable

2. **Guide rapide** :

```cmd
REM 1. Installer Go (une fois)
REM Téléchargez depuis https://go.dev/dl/ et installez

REM 2. Compiler (une fois)
cd C:\Users\MRO\Desktop\PowerShell-text-to-excel-VF
build.bat

REM 3. Utiliser (autant de fois que vous voulez)
extract-sections.exe -i ".\mes_textes" -o "resultats.csv"
```

---

## 📚 Liens utiles

- **Guide complet version Go** : [BUILD_GO.md](BUILD_GO.md)
- **README version Go** : [README_GO.md](README_GO.md)
- **Documentation générale** : [DOCUMENTATION.md](DOCUMENTATION.md)
- **Télécharger Go** : https://go.dev/dl/

---

## 🆘 Besoin d'aide ?

### J'ai installé Go mais "go: command not found"

**Solution** :
1. Redémarrez votre terminal (très important !)
2. Vérifiez l'installation : `where go`
3. Si rien, ajoutez `C:\Program Files\Go\bin` au PATH manuellement

### La compilation échoue

**Solution** :

```cmd
REM Nettoyer et réessayer
go clean
go mod download
go mod tidy
go build -o extract-sections.exe extract-sections.go
```

### L'exe ne démarre pas (antivirus bloque)

**Solution** :
1. Ajoutez `extract-sections.exe` aux exceptions de l'antivirus
2. Ou copiez-le dans un dossier de confiance (ex: `C:\Program Files\`)

### Je n'ai pas les droits pour installer Go

**Solution** :
1. **Demandez à votre IT** d'installer Go OU de compiler `extract-sections.exe` pour vous
2. Une fois compilé, l'exe fonctionne sans Go installé
3. Distribuez simplement l'exe (~10 Mo)

---

## ✅ Checklist de migration vers Go

- [ ] Télécharger Go (https://go.dev/dl/)
- [ ] Installer le `.msi`
- [ ] Redémarrer le terminal
- [ ] Vérifier : `go version`
- [ ] Naviguer : `cd C:\Users\MRO\Desktop\PowerShell-text-to-excel-VF`
- [ ] Compiler : `build.bat`
- [ ] Tester : `extract-sections.exe -i ".\mes_textes" -o "test.csv"`
- [ ] Vérifier le CSV dans Excel
- [ ] 🎉 C'est terminé !

---

## 💡 Astuce bonus

Une fois compilé, vous pouvez :

1. **Copier l'exe** sur une clé USB
2. **L'exécuter** depuis n'importe où (même sans Go installé)
3. **Le distribuer** à vos collègues (aucune installation requise)

```cmd
REM Copier sur clé USB
copy extract-sections.exe E:\

REM Utiliser depuis la clé USB
E:\extract-sections.exe -i "C:\Documents" -o "C:\Export\resultats.csv"
```

**L'exe est autonome = Aucune dépendance !**

---

**🎉 Plus jamais de problème de politique d'exécution avec la version Go !**
