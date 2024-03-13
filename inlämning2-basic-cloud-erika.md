# Inlämningsuppgift 2 - Basic cloud - Erika Bladh

## Introduktion

Mina verktyg:

- Windows 11
- Git och GitBash
- Azure CLI
- VSCode
- jq
- GitHub CLI

### GitHub CLI

```bash
gh auth login
```

```bash
gh auth status
```

### jq

Ett verktyg för att hantera JSON-data. Jag hämtade [senaste versionen (jq-1.7.1)](https://github.com/jqlang/jq/releases) och placerade den i `/path/to/Git/usr/bin`. För att smidigare kunna använda verktyget i mina skript så lade jag även till följande funktion i min `.bashrc`.

```bash
function jq() {
    /path/to/Git/usr/bin/jq-win64.exe "$@"
}
export -f jq
```

Sedan läste jag in förändringen med `source ~/.bashrc` samt verifierade att det fungerade med ett `test.sh` skript:

```bash
#!/bin/bash

jq --version
```

Output: `jq-1.7.1`

## Skapa repository på Github

## Provisionera värdmiljö

## Konfigurera Github Actions

## Utveckla applikationen
