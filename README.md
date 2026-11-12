# BOTASSO OS

Distribución Linux personalizada basada en **CachyOS** (Arch) con **KDE Plasma 6**. 
Este repositorio almacena la rebrand de CachyOS a **BOTASSO OS**, incluyendo:
configuración de sistema, tema de login SDDM, logo de la distro y guías de uso.

## datos básicos
| Campo | Valor |
|---|---|
| Nombre | BOTASSO OS |
| Base | CachyOS / Arch |
| ID de sistema | `bottasso` (ID_LIKE=arch) |
| Escritorio | KDE Plasma 6 |
| Kernel | 7.3.3-1-cachyos |
| Arquitectura | x86_64 |
| Boot | Limine (UEFI, dual-boot con Windows) |
| Zona horaria | America/Santiago (`-03`) |
| URL inicio | https://bottasso.dev/ |
| **Repositorio** | https://github.com/adrianbotasso9/bottasso |

## estructura del proyecto
```
bottasso/
├── README.md
├── BUILD.md
├── scripts/
│   └── rebrand.sh            # aplica la rebrand en un sistema vivo (sudo)
├── src/
│   ├── os-release/           # plantilla de os-release
│   │   └── base
│   ├── themes/
│   │   └── bottasso/         # tema SDDM
│   │       ├── bottasso.conf
│   │       └── bottasso-logo.png
│   └── assets/
│       └── logo/             # logotipo de la distro
│           └── bottasso-logo.png
└── .gitignore
```

## cómo contribuir
1. Haz fork y clona este repositorio.
2. Edita los ficheros fuente (no los de `/etc`/sistema directamente).
3. Prueba con `sudo bash scripts/rebrand.sh`.
4. Abre un Pull Request.
