# Tiller

Tiller provides small, single-purpose GitHub composite actions. The calling repository keeps checkout, tag creation, packaging, release ordering, and project-specific commands visible in its own workflow.

## Atomic actions

| Action | One responsibility |
| --- | --- |
| `tiouoo/tiller/version@v2` | Calculate the next stable version |
| `tiouoo/tiller/rolling-version@v2` | Calculate a time-based build version |
| `tiouoo/tiller/metadata@v2` | Format supplied values as metadata JSON |
| `tiouoo/tiller/changelog@v2` | Write one changelog file |
| `tiouoo/tiller/nuget@v2` | Push already-built NuGet packages |
| `tiouoo/tiller/cnb-tag@v2` | Push one tag to CNB |
| `tiouoo/tiller/cnb-release@v2` | Create or replace one CNB Release |
| `tiouoo/tiller/gitcode-tag@v2` | Push one tag to GitCode |
| `tiouoo/tiller/gitcode-release@v2` | Create or update one GitCode Release |
| `tiouoo/tiller/aur@v2` (unreleased) | Validate and publish one rendered AUR package |

There is intentionally no reusable workflow that calculates a version, builds packages, creates tags, publishes packages, and mirrors releases in one hidden call.

## Stable version rule

With no stable tag, `version` returns `1.0.0`. Patch versions run from 0 through 9 and then increment the unbounded minor component: `1.0.9 -> 1.1.0` and `1.9.9 -> 1.10.0`. The major component changes only through an explicit input. After explicitly publishing `2.0.0`, the next automatic version is `2.0.1`.

The version action only calculates `version`, `tag`, and `previous-tag`. Creating and pushing the tag remains an explicit step in the caller. The NuGet action only pushes packages that the caller has already built and authenticated.

Use the moving `v2` tag for compatible v2 updates, or pin an immutable release such as `v2.0.0`.

## Additional options (unreleased)

`version` accepts `minor-limit: '9'` for Portal-compatible decimal carry (`1.9.9 -> 2.0.0`). Its default remains `0` (unbounded minor). Explicit versions must not already exist and must use canonical numeric components without leading zeroes.

`changelog` accepts `base-ref` (`auto`, an explicit tag/ref, or `none`), `head-ref` (default `HEAD`), and `initial-history` (`recent` or `all`). Supply the previous tag calculated **before** creating a stable tag, so the new release does not generate an empty changelog against itself. Invalid refs fail the action.

`aur` requires an Arch Linux environment with `base-devel`, `git` and `openssh`. The caller renders a directory with `PKGBUILD` and local source files, then passes `package-directory`, `package-name`, `ssh-private-key`, `username` and `commit-message`. The action builds the package with `makepkg`, generates `.SRCINFO`, and commits/pushes only recipe files to that AUR package's `master`. Download URLs, channel names, checksum policy and project packaging stay in the caller. It removes its temporary SSH key on exit.

Run version validation with `bash tests/version.sh` and `bash tests/rolling-version.sh`.
