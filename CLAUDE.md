# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

enhancd is an enhanced `cd` command that aliases `cd` and, on plain invocation, opens an interactive fuzzy finder (fzf/fzy/peco/sk/zf) over previously-visited directories. Special args jump differently: `-` (MRU), `..` (any ancestor, like zsh-bd), `.` (subdirs of cwd), home. It also accepts piped stdin (`echo $HOME | cd`).

**This `fish` branch is a fork focused on the fish shell implementation** (see README improvements list). The bash/zsh implementation is kept but the active development target is fish.

## Two parallel implementations

The same feature set is implemented twice with a mirrored naming convention:

| Concern | bash/zsh | fish |
|---|---|---|
| Entry / bootstrap | `init.sh` (sources `src/*.sh`, sets `ENHANCD_*` env, aliases `cd`) | `conf.d/enhancd.fish` (`--on-event enhancd_install/uninstall` handlers set universal vars) |
| Core logic | `src/*.sh` | `functions/enhancd/*.fish` (autoloaded), main is `functions/enhancd.fish` |
| Function names | `__enhancd::CATEGORY::FUNC` | `_enhancd_CATEGORY_FUNC` |

Category files map 1:1 across both: `cd`, `command`, `filepath`, `filter`, `helper`, `history`, `ltsv`, `sources`. When changing behavior, keep the two sides in sync unless the change is fish-only.

**Shared awk scripts** live in `functions/enhancd/lib/*.awk` (`fuzzy`, `split`, `to_abspath`, `help`, `ltsv`, `cdpath`, …). Both shells shell out to these — heavy text processing is done in awk, not shell.

## Control flow (both shells, same shape)

`cd` → main function (`__enhancd::cd` / `enhancd`):
1. If not ready (no filter binary / no history), fall through to `builtin cd`.
2. Parse args in a `switch`/`case`: special args pick a **source**, flags are looked up in the LTSV option table, otherwise the arg is treated as a history search.
3. A **source** (`sources.sh` / `_enhancd_source*`) produces a candidate dir list → piped through **filter** (`filter.sh` / `_enhancd_filter_*`, ending in `interactive` which invokes the fuzzy finder) → selected path.
4. `builtin cd` the result, then `after` hook records history and runs `$ENHANCD_HOOK_AFTER_CD`.

## Options are data, not code

User-facing flags are declared in **LTSV** files, not hardcoded:
- bash/zsh: `config.ltsv`
- fish: `functions/enhancd/config.ltsv`

Columns: `short`, `long`, `desc`, `func` (command producing candidates), `condition` (guard), and optionally `format`. `ltsv.sh` / `_enhancd_ltsv_*` parse these; `--help` is rendered by `lib/help.awk`. Add/change an option by editing the LTSV, not the parser.

## fish-specific notes

- Directory history is stored in the **universal variable `ENHANCD_DIRECTORIES`** (migrated from the old `$ENHANCD_DIR/enhancd.log` file on install). bash/zsh still uses the `enhancd.log` file.
- Filter/awk commands are resolved once and cached in `ENHANCD_CURRENT_FILTER` / `ENHANCD_AWK_CMD` universal vars to avoid repeated `type -q` calls.
- Filters stream input to the fuzzy finder rather than buffering the whole list first — preserve this when editing `_enhancd_filter_*`.
- Installs as a fisher-style plugin (autoloaded `functions/` + `conf.d/` event handlers). `alt+f` (`\ef`) is bound to `_enhancd_complete`.

## Config knobs

All behavior is env/universal vars prefixed `ENHANCD_` (defined in `init.sh` and `conf.d/enhancd.fish`): `ENHANCD_FILTER` (colon-list of fuzzy finders in preference order), `ENHANCD_COMMAND` (alias name, default `cd`), `ENHANCD_DIR`, the `ENHANCD_ENABLE_*` / `ENHANCD_ARG_*` toggles for special args, `ENHANCD_HYPHEN_NUM`, `ENHANCD_USE_ABBREV`.

## Dev workflow

- **No automated test suite.** Verify manually by sourcing/loading and exercising `cd`.
  - bash/zsh: `source ./init.sh`
  - fish: load the plugin (fisher) or source the functions, then trigger the install event.
- `VERSION` is the single source of truth for the version; releases are automated via **tagpr** (`.tagpr`, `.github/workflows/tagpr.yaml`) — do not hand-edit `CHANGELOG.md` or tags.
- `docs/*.tape` are [VHS](https://github.com/charmbracelet/vhs) scripts that regenerate the README demo GIFs.

## Gotcha

`functions/enhancd.fish` has a pre-existing bug at the home case: it matches `$ENHANCED_HOME_ARG` (misspelled) instead of `$ENHANCD_ARG_HOME`. Be aware when touching that switch.
