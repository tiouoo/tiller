# Tiller

Tiller is a small, opinionated release toolkit used by the `tiouoo` repositories. Project-specific build commands remain in each project; Tiller centralizes versioning, build metadata, changelogs, NuGet publishing, and release mirroring.

## Stable versions

With no stable tag the version is `1.0.0`. Patch versions run from 0 through 9, then increment the unbounded minor component: `1.0.9 -> 1.1.0` and `1.9.9 -> 1.10.0`. The major component changes only through an explicit version. After explicitly publishing `2.0.0`, the next automatic version is `2.0.1`.

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
- id: release
  uses: tiouoo/tiller@v1
  with:
    version: ${{ inputs.version }}
```

Outputs include `version`, `tag`, `previous_tag`, `commit`, `build_time`, `release_date`, `release_name`, and `json`. This action calculates metadata but deliberately does not push a tag.

## Other actions

- `tiouoo/tiller/build@v1` generates commit or nightly build metadata.
- `tiouoo/tiller/changelog@v1` writes a Markdown changelog.
- `tiouoo/tiller/cnb@v1` mirrors a tag, release notes, and optional assets to CNB.
- `tiouoo/tiller/gitcode@v1` mirrors a tag and release notes to GitCode.

Tokens are passed by the caller and never stored in Tiller. An empty mirror token safely skips that mirror.

## NuGet workflow

```yaml
jobs:
  publish:
    uses: tiouoo/tiller/.github/workflows/nuget.yml@v1
    with:
      version: ${{ inputs.version }}
      release-name-prefix: OvoUi
    secrets: inherit
```

The calling repository keeps `.github/scripts/pack-nuget.sh`. It receives `VERSION` and writes packages to `artifacts/`. This preserves project ordering while centralizing authentication, publishing, tagging, and GitHub Release creation.

Use the moving `v1` tag for compatible updates, or pin an immutable release such as `v1.0.0`.
