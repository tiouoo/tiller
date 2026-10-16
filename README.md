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

There is intentionally no reusable workflow that calculates a version, builds packages, creates tags, publishes packages, and mirrors releases in one hidden call.

## Stable version rule

With no stable tag, `version` returns `1.0.0`. Patch versions run from 0 through 9 and then increment the unbounded minor component: `1.0.9 -> 1.1.0` and `1.9.9 -> 1.10.0`. The major component changes only through an explicit input. After explicitly publishing `2.0.0`, the next automatic version is `2.0.1`.

The version action only calculates `version`, `tag`, and `previous-tag`. Creating and pushing the tag remains an explicit step in the caller. The NuGet action only pushes packages that the caller has already built and authenticated.

Use the moving `v2` tag for compatible v2 updates, or pin an immutable release such as `v2.0.0`.
