# Inlämningsuppgift 2 - Erika Bladh

## Introduktion

Jag kommer använda mig av den ToDo-applikation som varit demonstration under fredagar.

__Några verktyg:__

- Windows 11
- Git och GitBash
- Azure CLI
- VSCode
- jq
- GitHub CLI

## Infrastruktur

### Översikt

![infrastructure.JPG](infrastructure.JPG)

Jag kommer basera den infrastruktur jag provisionerar på den mall som vi tagit del av på lektionerna och jag har beskrivit detta i en _ARM-Template_.

#### Maskiner

Dessa kommer samtliga bestå av `Standard_B1s` instanser med `Ubuntu2204` som operativsystem, dom kommer också att ha var sitt nätverksgränssnitt och vara kopplade till var sin _Application Security Group_.

##### Applikationsserver

Denna maskin kommer köra vår applikation samt en runner som hanterar driftsättningen från Github. Jag bifogar till den här ett cloud-init skript liknande det jag använde i förra inlämningsuppgiften för att installera runtime och köra applikationen som en service. Men jag har även lagt till instruktioner för att installera och köra den runner som hanterar driftsättningen av applikationen. Jag valde även att provisionera denna med en statisk intern ipadress (`10.0.0.10`) för att förenkla konfigurationen av reverse proxy instansen.

##### Reverse Proxy

Denna maskin har som uppgift att hantera trafiken från användare som försöker nå min applikationen genom att vidarebefordra trafiken till applikationsservern. Del av denna uppgift bör inkludera att hantera användartrafik av skadlig karaktär (men i min lösning så varken installerar eller konfigurerar jag några verktyg i det syftet). Jag utnytjar i min lösning att applikationsservern har en statisk adress internt i min konfiguration, men jag kan se hur lösningen hade varit mer elegant ifall konfigurationen var mer dynamisk.

##### Bastion Host

Likt Reverse Proxy maskinen så har denna maskin som uppgift att hantera trafik från internet med skillnaden att denna hanterar administrativ trafik över SSH.

#### Nätverk

##### VNet

Det virtuella nätverket är den grund på vilka övriga nätverkskomponenter vilar.

##### Subnet

Subnätet är en mindre del av det virtuella nätverkets helhet och jag har i min lösning låtit detta vara ansvarigt för att hålla i dom brandväggsregler jag definierar (istället för att binda dessa direkt till nätverksgränssnitten). Nätverksgränsnitten kopplas till subnätet.

##### Network Security Group

###### Network Security Rules

#### Lagring

##### Blob Storage

##### Cosmos MongoDB

## Implementation av lösningen



## Övrigt

### Installation av verktyg

#### GitHub CLI

```bash
gh auth login
```

```bash
gh auth status
```

#### jq

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

### Felsökning av cloud-init

Om vi har tillgång till den VM som strular så kan vi få information om vad som skedde när vårt cloud-init skript kördes i filen `/var/log/cloud-init-output.log`.

## Mina Filer
