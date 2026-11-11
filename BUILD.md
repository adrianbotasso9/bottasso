# BUILD.md — guía de construcción y aplicación de BOTASSO OS

BOTASSO OS es una *rebrand* de CachyOS. Como no partimos de un ISO limpio,
lo que se instala es la distribución base (CachyOS), y luego se aplica la 
capa de rebrand a partir de este repositorio.

## 1) Reactivar la rebrand en un sistema vivo
```bash
sudo bash scripts/rebrand.sh
```
Esto hace lo siguiente:
1. Escribe la base de `os-release` (`/usr/lib/os-release`) con los datos de **BOTASSO OS**.
2. Convierte `/etc/os-release` en un enlace simbólico al archivo base.
3. Instala el tema de login SDDM (`bottasso.conf` + `bottasso-logo.png`) en
   `/usr/share/sddm/themes/bottasso/`.
4. Instala el icono de la distro (`LOGO=bottasso`) en `/usr/share/pixmaps/bottasso.png`.
5. Deja un respaldo de `/etc/os-release` original como `/etc/os-release.bottasso.bak`.

## 2) Revisar lo instalado
```bash
cat /etc/os-release                 # NAME=PRETTY_NAME=OS BOTASSO OS
ls -la /etc/os-release              # -> /usr/lib/os-release (symlink)
hostnamectl | grep -E 'Operating|Kernel|Architecture'
ls /usr/share/sddm/themes/bottasso/ # debe mostrar bottasso.conf + bottasso-logo.png
ls /usr/share/pixmaps/bottasso.png
```

## 3) Organización de las fuentes
| Ruta | Contenido |
|---|---|
| `src/os-release/base` | Plantilla de la base de `os-release` (datos BOTASSO) |
| `src/themes/bottasso/` | Tema SDDM: `bottasso.conf` + logo |
| `src/assets/logo/bottasso-logo.png` | Logotipo de la distro |
| `scripts/rebrand.sh` | Script de aplicación (automático) |

## 4) Notas de construcción futuras
Si se decide empaquetar como ISO (por ejemplo con `mkarchiso`), la idea es
crear un `PKGBUILD` o script de construcción que escriba los ficheros de
`src/` sobre el sistema de archivos raíz del ISO antes de grabarlo.
