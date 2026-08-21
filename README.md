# Teams Macro

Petit utilitaire pour **rester en ligne sur Microsoft Teams** en simulant un léger mouvement de souris.

| Plateforme | Techno | Emplacement |
|---|---|---|
| **macOS** | SwiftUI (menu bar) | racine du dépôt |
| **Windows** | Python (icone système) | `windows/` |

Fonctions communes :
- Activer / désactiver depuis la barre d’état
- Planification (heures, pause midi, jours exclus)
- Raccourcis clavier
- Lancement au démarrage de la session

---

## macOS

### Prérequis
- macOS 14+
- Xcode Command Line Tools (`xcode-select --install`)

### Installation

```bash
cd "/chemin/vers/TeamsMacro"
make install
open /Applications/TeamsMacro.app
```

Ou sans installer dans Applications :

```bash
make run
```

### Accessibilité (obligatoire)
1. **Réglages Système → Confidentialité et sécurité → Accessibilité**
2. Supprime les anciennes entrées « Teams Macro » si besoin
3. Ajoute **uniquement** `/Applications/TeamsMacro.app`
4. Coche la case, puis **relance** l’app (menu → Relancer l’app)

Sans ça, macOS bloque le mouvement de souris.

### Utilisation
- Clic sur l’icone menu bar (cercle) → Activer / Désactiver / Réglages
- Raccourci bascule par défaut : `⌃⌥⌘T`
- Onglet **Planning** : horaires, pause midi, jours exclus
- Onglet **Général** : intervalle, amplitude, lancement au login

### Désinstallation

```bash
make uninstall
```

---

## Windows

### Prérequis
- Windows 10 ou 11
- [Python 3.10+](https://www.python.org/downloads/)  
  Pendant l’install : coche **Add python.exe to PATH**

### Installation

1. Copie le dossier `windows/` sur le PC (ou clone tout le dépôt)
2. Double-clique **`install.bat`**
3. Double-clique **`run.bat`**

Une icone apparaît près de l’horloge (parfois dans `^` de la barre des tâches).

En ligne de commande :

```bat
cd windows
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
pythonw -m teamsmacro
```

### Utilisation
- Clic droit sur l’icone → **Activer** / **Désactiver** / **Réglages** / **Quitter**
- **Réglages → Général** : intervalle, amplitude, démarrage Windows
- **Réglages → Planning** : 09:00–18:00, pause midi, week-end exclus (par défaut)
- **Réglages → Raccourcis** : format `pynput`, ex. `<ctrl>+<alt>+t`

Raccourci bascule par défaut : `Ctrl+Alt+T`

### Démarrage automatique
Activé par défaut au premier lancement (clé Registre `HKCU\...\Run` → `start-hidden.bat`).  
Désactivable dans **Réglages → Lancer au démarrage de Windows**.

### Désinstallation
1. Quitte l’app
2. Décoche le démarrage auto dans les réglages (ou lance une fois puis décoche)
3. Supprime le dossier `windows/`
4. Optionnel : supprime `%APPDATA%\TeamsMacro\`

---

## Réglages par défaut

| Paramètre | Valeur |
|---|---|
| Intervalle | 240 s (4 min) |
| Amplitude | 1 px |
| Actif | 09:00 → 18:00 |
| Pause midi | 12:00 → 13:30 |
| Jours exclus | samedi, dimanche |
| Démarrage session | oui |

---

## Structure du dépôt

```
TeamsMacro/
├── README.md
├── Package.swift          # app macOS
├── Makefile
├── Sources/TeamsMacro/
├── App/Info.plist
└── windows/
    ├── install.bat
    ├── run.bat
    ├── start-hidden.bat
    ├── requirements.txt
    └── teamsmacro/        # code Windows
```

Les deux versions sont indépendantes (pas de binaire partagé) mais offrent la même logique métier.
