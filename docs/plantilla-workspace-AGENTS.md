# AGENTS.md — workspace <nombre del workspace>

Plantilla para el `AGENTS.md` de la **raíz de un workspace con varios
repositorios**. Cópiala ahí (fuera de este repo) y rellena lo que corresponda.
Lo específico de cada repo vive en el `AGENTS.md` de ese repo, no aquí.

## Cómo se cargan estas instrucciones

El harness inyecta `$DSH_HOME/AGENTS.md` (global del usuario) y después la cadena
desde la raíz del proyecto (primer directorio con `.git` subiendo desde el
directorio de trabajo) hasta el directorio de trabajo de la sesión. Son los
**ancestros** del directorio de trabajo, no sus hijos:

- Si la sesión arranca en la raíz del workspace → se carga este fichero; los
  `AGENTS.md` de cada repo se cargan al leer/escribir/editar algo dentro de ellos
  (o si se piden explícitamente).
- Si la sesión arranca dentro de un repo → se carga el `AGENTS.md` de ese repo, y
  **este fichero no**. Por eso lo imprescindible debe estar también en el repo.

## Repositorios del workspace

| Directorio | Qué es | Instrucciones |
|---|---|---|
| `day-trade/` | App Odin de registro de trades ya cerrados (multi-UI: GTK/WinForms/IUP) | `day-trade/AGENTS.md` + `day-trade/docs/estado-actual.md` |
| `<repo-2>/` | <descripción> | `<repo-2>/AGENTS.md` |
| `<repo-3>/` | <descripción> | `<repo-3>/AGENTS.md` |

**Antes de tocar un repo, lee su `AGENTS.md`.**

## Convenciones comunes

- Conversación en **español**; **commits en inglés y cortos**.
- El agente prepara el commit; **el usuario hace push**. No afirmar cuántos
  commits hay pendientes sin comprobarlo (`git status -sb` / `git log @{u}..HEAD`).
- Verificar los cambios de comportamiento **ejecutando**, no solo compilando; no
  afirmar nada sin comprobarlo (y citar fuentes al decidir sobre una librería).
- <estilo de código, formateadores, ramas, idioma de los identificadores...>

## Entorno

- Sistema operativo y shell: <p. ej. Linux + bash / macOS + zsh / Windows + pwsh>
- Toolchains: <p. ej. odin, gcc/clang, gtk4, .NET...>
- Comandos de comprobación y test comunes: <...>

## Cómo trabajar entre varios repos

- Si un cambio en un repo afecta a otro (interfaz, formato de datos compartido),
  decirlo y actualizar **los dos** `AGENTS.md`/docs si cambia algo estructural.
- Mantener el estado vivo de cada proyecto en su `docs/` (no solo en el chat).
