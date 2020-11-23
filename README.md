# crm-nks-base

[![Build](https://github.com/navikt/crm-nks-base/workflows/master/badge.svg)](https://github.com/navikt/crm-nks-base/actions?query=workflow%3ABuild)
[![GitHub version](https://badgen.net/github/release/navikt/crm-nks-base/stable)](https://github.com/navikt/crm-nks-base)
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/navikt/XXXXXXXXXXXXX/blob/master/LICENSE)

## Arbeidsflyt

All utvikling av ny funksjonalitet gjøres i separate feature branches. Ved merge til master i dette repositoriet vil det automatisk genereres en pakkeversjon som installeres i følgende sandboxer:
* [NKS](https://navdialog--nks.my.salesforce.com)
* [SIT](https://navdialog--sit.my.salesforce.com)

## Dependencies

Pakken er avhengig av følgende pakker:

* [crm-platform-base](https://github.com/navikt/crm-platform-base)
* [crm-platform-access-control](https://github.com/navikt/XXXXXXXXXXXXX)
* [crm-arbeidsgiver-base](https://github.com/navikt/crm-arbeidsgiver-base)

## Funksjonelt oppsett

Det er noen viktige elementer som må sette opp korrekt for at funksjonalitet for NKS skal fungere som den skal.
* Opprettelse av nødvendige delingsregler for Case, NavTask__c og LiveChatTranscript for håndtering av henvendelser som inneholder informasjon om sosiale tjenester (Regler ligger i unpackagable)
* Assignment til public group **NKS Veiledere**. 
	- Dette er viktig da de nevnte delingsreglene deler all data med medlemmer av denne gruppen såfremt dataen ikke inneholder sensitiv informasjon om sosiale tjenester
* Oppdatering av custom setting **Access Token Scope** med riktige scopes for APIene man ønsker å sette opp (f.eks Oppgave, og Dokarkiv)
	- Har man tilgang kan f.eks disse finnes  for preprod ved å navigere til riktig klient i [Azure](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps)

## Komme i gang

1. Salesforce DX-bruker. Kontakt #crm-plattform-team på Slack om du ikke har dette
2. Installer Salesforce DX CLI (SFDX)
	- Last ned fra [Salesforce.com](https://developer.salesforce.com/tools/sfdxcli)
    - Eller benytt npm: `npm install sfdx-cli --global`
3. Klon dette repoet ([GitHub Desktop](https://desktop.github.com) anbefales for ikke-utviklere)
4. Installer [SSDX](https://github.com/navikt/ssdx)
    - Med SSDX kan du lage scratch orger og gjøre deklarative endringer (gjøre endringer i nettleseren på Salesforce, altså ikke-utvikling)
	- **Trenger du ikke verktøy utvikling kan du stoppe her**
5. Installer [VS Code](https://code.visualstudio.com) (anbefalt)
6. Installer [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
7. Installer [AdoptOpenJDK](https://adoptopenjdk.net) (kun versjon 8 eller 11)
8. Åpne VS Code Settings og søk etter `salesforcedx-vscode-apex`
9. Under `Java Home`, legg inn følgende:
    - macOS: `/Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home`
    - Windows: `C:\\Program Files\\AdoptOpenJDK\\jdk-11.0.3.7-hotspot` (merk at versjonsnummer kan endre seg)

## Utvikling

Utvikling foregår i hovedsak på to fronter, i nettleseren i din scratch org og på din maskin i din prefererte IDE. Ved endringer i nettleseren på din scratch org (som lever i skyen), så må alle endringer pulles til din maskin. Ved endringer av metadata i din IDE, må endringer pushes til din scratch org.

Ved å bruke VS Code som IDE, er det lagt inn konfigurasjon som automatisk pusher endringer av metadata til din scratch org ved lagring. For å pulle endringer fra kan man enten bruke Salesforce DX CLI til å pulle, men også pushe om man ikke ønsker automatisk push. Se under for kommandoer. Man kan også bruke hjelpeverktøyet SSDX (nevnt over) for å pushe, pulle, åpne scratch org-er, slette gamle, blant annet.

* `sfdx force:org:open` for å åpne instansen(salesforce applikasjonen din).
* `sfdx force:source:pull` for å hente endringer som du gjør i konfigurasjon i applikasjonen online.
* `sfdx force:source:push` for å publisere endringer du gjør i kode lokalt til applikasjonen online.

## Annet

For spørsmål om denne applikasjonen, bruk #crm-nks på Slack.
