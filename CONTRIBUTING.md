# CONTRIBUTING — Cómo contribuir a BOTASSO OS

BOTASSO OS es una **rebrand de CachyOS** lanzada con **KDE Plasma 6**. 
El objetivo de este repositorio es almacenar los ficheros fuente que permiten
rebrandear una instalación base CachyOS a BOTASSO OS, y de forma futura generar
un ISO con el entorno de instalación gráfico.

## ¿Qué se almacena aquí?

| Directorio | Contenido |
|---|---|
| `src/` | Recursos de configuración y rebrand extraíbles (`os-release`, temas SDDM, logo) |
| `bottasso-iso/bottasso-installer/` | 🟦 **Perfil de instalación** (KDE Plasma 6, SDDM, instalador PyQt6 + script de instalación) |
| `bottasso-iso/bottasso/` | 🟨 Perfil **base CachyOS** usado como punto de partida |
| `BUILD.md`, `README.md`, `LICENSE` | Documentación, construcción e información del proyecto |
| `.github/workflows/ci.yml` | CI de comprobación (GitHub Actions) |

## ¿Qué NO se almacena aquí?

Los artefactos de compilación **nunca** deben subirse al repositorio:

* ISO compiladas (`*.iso`) → **gitignore** entre otros
* directorios de construcción (`out/`, `work/`, `work-installer/`)
* logs de compilación (`*.log`)

La regla `.gitattributes` **sí** marca `*.iso` con LFS, pero eso está
deshabilitado para evitar subir ISO de varios GB. Si un archivo ligero
está en `src/` o el perfil de instalación, se subirá normalmente.

## Cómo contribuir

1. **Fork** este repositorio.
2. **Clona** tu fork e instala las dependencias necesarias (`git`, `make`,
   `pacman`, `mkarchiso`, `python3`, `pyqt6`, `kdebase`…).
3. **Crea una rama** desde `main` para tu cambio:
   ```bash
   git checkout -b feature/su-cambio
   ```
4. **Edita los ficheros fuente.** Únicamente editan los ficheros de:
   * `src/`
   * `bottasso-iso/bottasso-installer/`
   * `bottasso-iso/bottasso/`
   * `scripts/`
5. **Comprueba** antes de subir:
   * `bash -n scripts/rebrand.sh`
   * `python3 -m py_compile bottasso-iso/bottasso-installer/airootfs/usr/share/bottasso/install/bottasso-installer.py`
   * Revisa los cambios con `git status` y `git diff`.
6. **Commitea** y envía un **Pull Request** a `main`.
   * Usa un mensaje de commit en español (o en inglés) y describe qué hace.
   * Abre la descripción del PR indicando el objetivo y cómo probarlo.

## Cómo probar el rebrand en un sistema vivo

```bash
sudo bash scripts/rebrand.sh
```

Esto reescribe `os-release`, el tema SDDM, el logo y el arranque sobre el
sistema donde se ejecuta el script.

## ¿Cómo probar el perfil de instalación?

La construcción autónoma requiere esos paquetes y herramientas:

```bash
sudo pacman -S --needed mkarchiso linux-cachyos limine python python-pyqt6
```

Luego:

```bash
mkarchiso -v -w ~/botassso-work -o ~/botassso-out -m iso bottasso-iso/bottasso-installer
```

El ISO resultante se encuentra en `bottasso-iso/out-installer/`.

## Contacto

* GitHub: https://github.com/adrianbotasso9/bottasso
