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
├── .github/
│   └── workflows/
│       └── ci.yml                  # CI de comprobación (GitHub Actions)
├── bottasso-iso/
│   ├── bottasso-installer/         # 🟦 Perfil de instalación (KDE Plasma 6 + PyQt6)
│   │   ├── profiledef.sh
│   │   ├── pacman.conf
│   │   ├── packages.x86_64
│   │   ├── airootfs/               # chroot con instalador + rebrand
│   │   └── efiboot/grub/syslinux/  # arranque
│   ├── bottasso/                   # 🟨 Perfil base CachyOS (fuente)
│   │   ├── airootfs/ ...
│   │   ├── grub/syslinux/...
│   │   └── ...
│   ├── out/          # ISO compilados (ignorados por git)
│   ├── out-installer/  # ISO de la instalación (ignorados por git)
│   ├── work/         # cache mkarchiso (ignorados por git)
│   └── work-installer/
├── BUILD.md
├── README.md
├── scripts/
│   └── rebrand.sh            # aplica la rebrand en un sistema vivo (sudo)
├── src/
│   ├── os-release/base       # plantilla de os-release
│   ├── themes/bottasso/      # tema SDDM
│   └── assets/logo/          # logotipo de la distro
└── .gitignore
```

## cómo contribuir
1. Haz fork y clona este repositorio.
2. Crea una rama desde `main` para tu cambio.
3. Edita únicamente los ficheros **fuente** (estan en `src/`, `bottasso-iso/bottasso-installer/`, `bottasso-iso/bottasso/` y `scripts/`).
4. No metas artefactos de compilación (ISO `.iso`, directorios `out/`, `work/`, `work-installer/`) — ya están en `.gitignore`.
5. Revisa los scripts con `bash -n` y el instalador con `python3 -m py_compile`.
6. Abre un Pull Request a `main`.

## referencias
- [Actualización de rebrand en vivo](BUILD.md#1-reactivar-la-rebrand-en-un-sistema-vivo)
- Proyecto: https://bottasso.dev/
