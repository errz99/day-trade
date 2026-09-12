# Puesta en marcha en Linux

Pasos concretos y comprobados para compilar y ejecutar este repo en Linux (el
resumen multiplataforma está en [`../AGENTS.md`](../AGENTS.md)).

## 1. Toolchain

- **Odin** (el repo se ha venido compilando con la versión actual; comprueba
  `odin version`).
- **gcc o clang** y **pkg-config**: Odin resuelve los `foreign import "system:..."`
  a través de pkg-config.

## 2. Paquetes necesarios (⚠️ incluye GTK3, no es un error)

En la rama no-Windows, `lib/gtk4` enlaza:
`system:gtk-4`, **`system:gdk-3`**, `system:cairo`, `system:glib-2.0`,
`system:gobject-2.0`, `system:gio-2.0`, `system:adwaita-1`.

- `gdk-3`: `lib/gtk4/gtk/gtk.odin` importa el paquete `gdk`, y ese paquete enlaza
  **gdk-3** en Linux (en Windows esa línea está comentada, por eso allí no hace
  falta). Sin GTK3 instalado, el **enlazado** falla.
- `adwaita-1`: se enlaza **siempre**, aunque `use_adwaita` sea `false`, porque
  `ui/gtk` importa el paquete adwaita.

```bash
# Debian / Ubuntu
sudo apt install libgtk-4-dev libgtk-3-dev libadwaita-1-dev libglib2.0-dev libcairo2-dev pkg-config

# Fedora
sudo dnf install gtk4-devel gtk3-devel libadwaita-devel glib2-devel cairo-devel pkgconf-pkg-config

# Arch
sudo pacman -S gtk4 gtk3 libadwaita glib2 cairo pkgconf
```

Comprobación (si falla, fallará el enlazado; `odin check` **no** lo detecta porque
no enlaza):

```bash
pkg-config --exists gtk4 && pkg-config --exists gtk+-3.0 && pkg-config --exists libadwaita-1 && echo ok
```

## 3. Compilar y ejecutar

```bash
./build.sh gtk        # o ./build.sh (gtk es el target por defecto)
./day-trade-gtk       # interfaz GTK
./day-trade-gtk -t    # TUI en consola (Linux/macOS)
```

`build.ps1` es solo para Windows; `winforms` no se puede enlazar en Linux e IUP
está abandonado.

## 4. Datos

- `data.json` y `config.json` viven en el directorio de trabajo y están en
  `.gitignore`: **no vienen con el clon**.
- Si no existen, la app arranca con datos por defecto: `load_data` devuelve
  `ok = false` y `load_session_data` cae a `new_default_data` (brokers `ibkr` e
  `ibroker` sembrados con sus comisiones y una cuenta `Default`).
- Si quieres los mismos datos o la geometría de ventana que en Windows, copia esos
  dos ficheros a mano.

## 5. Verificación en Linux

El método de AGENTS.md (manejar ventanas con Win32 desde PowerShell) **no aplica**.
Lo razonable aquí:

1. `odin check . -define:UI=gtk` → tipos (no enlaza).
2. `./build.sh gtk` → compila y enlaza.
3. Ejecutar y comprobar el **efecto**: registrar un trade desde la UI y volver a
   leer `data.json`; mirar la salida de consola; probar el diálogo de Config
   (idioma y adwaita).
4. Al reportar: decir claramente qué se ha verificado ejecutando y qué no.
