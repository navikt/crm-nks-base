# crm-nks-base

[![Build](https://github.com/navikt/crm-nks-base/workflows/%5BPUSH%5D%20Create%20Package/badge.svg)](https://github.com/navikt/crm-nks-base/actions?query=workflow%3Acreate)
[![GitHub version](https://badgen.net/github/release/navikt/crm-nks-base/stable)](https://github.com/navikt/crm-nks-base)
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/navikt/XXXXXXXXXXXXX/blob/master/LICENSE)

## Arbeidsflyt

All utvikling av ny funksjonalitet gjøres i separate feature branches. Ved merge til master i dette repositoriet vil det automatisk genereres en pakkeversjon som installeres i følgende sandboxer:

-   [NKS](https://navdialog--nks.my.salesforce.com)
-   [SIT](https://navdialog--sit.my.salesforce.com)

## Dependencies

Pakken er avhengig av følgende pakker:

-   [crm-platform-base](https://github.com/navikt/crm-platform-base)
-   [crm-platform-access-control](https://github.com/navikt/XXXXXXXXXXXXX)
-   [crm-arbeidsgiver-base](https://github.com/navikt/crm-arbeidsgiver-base)
-   [crm-nks-integration](https://github.com/navikt/crm-nks-integration)

## Funksjonelt oppsett

Det er noen viktige elementer som må sette opp korrekt for at funksjonalitet for NKS skal fungere som den skal.

-   Opprettelse av nødvendige delingsregler for Case og MessagingSession for å dele alle records med NKS veiledere
-   Assignment til public group **NKS Veiledere**.
    -   Dette er viktig da de nevnte delingsreglene deler all data med medlemmer av denne gruppen såfremt dataen ikke inneholder sensitiv informasjon om sosiale tjenester
-   Oppdatering av custom setting **Access Token Scope** med riktige scopes for APIene man ønsker å sette opp (f.eks Oppgave, og Dokarkiv)
    -   Har man tilgang kan f.eks disse finnes for preprod ved å navigere til riktig klient i [Azure](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps)

## BankID-status for telefoni

Puzzel sender `"<caseId>","authenticated":"true"` i `sfdc_case_id`, som integrasjonen
lagrer i `puzzel__EnquiryLog__c.puzzel__CaseId__c`. Dette er et tekstformat, ikke
et komplett JSON-objekt. Hele verdien må matche en ikke-tom, sitert case-ID uten
anførselstegn, mellomrom eller omvendt skråstrek, etterfulgt av egenskapen
`"authenticated":"true"`. Mellomrom rundt skilletegnene mellom ID og status tillates.
Statusen er tekst og må være nøyaktig `"true"`; `"false"`, `"error"`, manglende status
og feilformede verdier gir ikke en grønn badge.

CaseId inneholder her oppslagsverdien som Puzzel sender, for eksempel personnummer,
organisasjonsnummer eller telefonnummer, ikke Salesforce-sakens ID.
Organisasjonsnummer og telefonnummer kan fortsatt sendes uendret. For fødselsnummer
brukes `"fødselsnummer","authenticated":"false"` ved manglende autentisering,
`"fødselsnummer","authenticated":"true"` ved vellykket autentisering og
`"fødselsnummer","authenticated":"error"` når Puzzel melder en BankID-feil.
At brukeren ikke har BankID, er bare en feilstatus hvis Puzzel definerer det slik.

Et fødselsnummer (11 sifre) uten bekreftet autentisering viser en gul badge med
teksten «Ikke bekreftet identitet».
Dette gjelder både dagens uendrede fødselsnummer og status `"false"`/`"error"`.
Organisasjonsnummer, telefonnummer, manglende logg og feilformede verdier viser
ikke gul badge. `"true"` viser grønn badge med teksten «Bekreftet identitet».
Eksisterende oppslag fungerer dermed også før Puzzel tar i bruk det nye formatet;
gul badge for dagens uautentiserte fødselsnumre er en tilsiktet visningsendring.

Ved oppstart av `NKS_Inbound_Call` normaliseres det innkommende `Search` til
`LOOKUP_VALUE`: vanlige verdier beholdes, mens det avtalte tekstformatet pakkes ut
til den opprinnelige verdien. Dette gjelder likt for `"true"`, `"false"` og
`"error"`, og innledende nuller beholdes. Hvis `Search` er tomt, brukes CaseId fra
EnquiryLog for samme `SessionId`. Et ikke-tomt `Search` overstyres ikke av loggen.
Feilformede autentiseringsfragmenter pakkes ikke ut.

Eksisterende ruting bruker deretter `LOOKUP_VALUE`: 11 tegn gir personoppslag,
9 tegn gir organisasjonsoppslag, og øvrige verdier følger telefonnummerløpet.
Autentiseringsstatus styrer bare badgen, ikke Account-oppslaget. Senere endringer
i EnquiryLog oppdaterer ikke Account-koblingen eller starter rutingen på nytt.
Deploy controlleren og den oppdaterte flowen sammen for å ta i bruk normaliseringen.
Det eksisterende inputnavnet `sessionIds` beholdes, og `search` er et nytt,
valgfritt input til Apex-handlingen.

`NKS_Inbound_Call` bevarer sesjons-ID på den opprettede saken i
`NKS_Puzzel_Session_Id__c`. Samtalereferatkomponenten bruker denne til å slå opp
riktig EnquiryLog og bruker eksisterende `Case.AccountId` for kontotilknytningen.
Sesjonsfeltet gis lesetilgang via `NKS_Case` og skal ikke være redigerbart for
veiledere. Eksisterende saker uten sesjonskobling viser ikke badgen.

Personbytte skal gå gjennom `NKS_Case_Change_Account`, som oppretter en ny sak uten
å kopiere sesjonskoblingen. Badgen skjules også hvis komponenten observerer at
kontoen endres på den åpne saken. Det lagres ikke noe separat øyeblikksbilde av
opprinnelig konto; direkte endring av `AccountId` med bevart sesjonskobling er
derfor ikke en støttet måte å bytte person på, og kan ikke oppdages etter ny
innlasting. En slik arbeidsflyt må håndteres separat før den eventuelt tas i bruk.

Oppdateringene er hendelsesstyrte, uten polling, retry-timere eller tidsgrense. Den aktive
etter-lagring-flowen `NKS_Puzzel_Notify_Authentication_Change` sender
`NKS_Call_Authentication_Changed__e` når en EnquiryLog med sesjons-ID opprettes,
eller når CaseId/sesjons-ID endres. Hendelsen publiseres etter commit og inneholder
bare sesjons-ID, ikke fødselsnummer eller autentiseringsstatus.
Ved endring av sesjons-ID varsles både den tidligere og den nye sesjonen.
Hvis sesjons-ID fjernes, varsles den tidligere sesjonen slik at badgen skjules.

Badgen abonnerer gjennom `lightning/empApi` når saken har gyldig samtalekontekst.
Ferske Apex-oppslag gjøres ved oppstart, når komponenten kobles til igjen, eller
ved en hendelse for den aktuelle sesjonen.
Et ekstra oppslag etter abonnementsbekreftelsen dekker endringer som skjer under
oppstart. Samtidige hendelser samles slik at oppslag ikke overlapper.
Dette dekker både forsinkede EnquiryLogger og autentisering som veilederen ber om
senere i samtalen. Også endringer fra bekreftet til ubekreftet status oppdaterer
badgen. Dette trenger ikke vente på den daglige CallLog-batchen og virker også
for køer uten NKS_Call_Log. Resultatet lagres ikke som en varig autentisering av
personen.

Deploy eventdefinisjonen, den oppdaterte `NKS_Case`-tillatelsen og komponenten
sammen med Apex-/Case-endringene. Installer deretter flowen fra
`force-app\unpackagable-with-auto-deploy\flows` i miljøer med Puzzel-pakken.
Flowen ligger utenfor pakken slik at scratch-orger uten Puzzel fortsatt støttes.
Den må være aktiv for at eksterne oppdateringer skal bli synlige automatisk.
Publiseringsfeil logges med `LoggerUtility`.
Flowen logger også en applikasjonsfeil når et gyldig fødselsnummer-payload med
`"authenticated":"error"` opprettes eller endres. Loggmeldingen inneholder ikke
fødselsnummer eller råpayload. Uendrede payloads og badge-oppslag lager ikke nye
feillogger, og `"false"` eller manglende autentisering logges ikke som feil.

Abonnenter trenger bare lesetilgang til den nye plattformhendelsen via `NKS_Case`;
det gis ikke publiseringstilgang eller utvidet tilgang til EnquiryLog. Direkte
CDC-abonnement ville krevd `View All Records` på EnquiryLog og er derfor ikke brukt.
Apex kontrollerer sakstilgang i brukermodus og leser EnquiryLog i eksplisitt
systemmodus. Manglende EnquiryLog logges ikke som et varsel; bare feil logges.
`lightning/empApi` krever en støttet Lightning Experience-skrivebordsnettleser.
Badgen vises automatisk både ved allerede bekreftet identitet og når brukeren
autentiserer seg senere. Det finnes ingen oppdateringsknapp.
Ubekreftet autentisering for fødselsnummer viser bare gul badge, uten toast-varsel.
Når identifikatortype eller samtalekobling ikke kan fastslås, skjules badgen.
Bare faktiske oppslagsfeil, feil i abonnementet for BankID-hendelsen eller feil
i den felles streamingforbindelsen varsles. Feil for andre hendelsesabonnementer
utløser ikke BankID-varsler. Det startes ingen timer eller polling ved feil;
neste relevante hendelse gjør et nytt statusoppslag. EMP API håndterer
streamingforbindelsen, uten egen timerstyrt gjenoppkobling i komponenten.
Hendelser bruker organisasjonens plattformhendelseskvoter. Leveringsvolumet
avhenger også av antall innloggede abonnenter, ikke bare antall samtaler.

For testen må Puzzel bekrefte at markøren gjelder BankID-identiteten til samme
person som Salesforce finner gjennom `Search`, i samme sesjon. Salesforce kan
ikke bevise denne koblingen fra feltinnholdet alene. Kontroller med et
testanrop at `Search` fortsatt inneholder den opprinnelige søkeverdien, og at
endringen ikke bryter Puzzels eksisterende bruk av case-ID. Råverdiene i `Search`
og CaseId beholdes; `LOOKUP_VALUE` brukes til den eksisterende identifikatorrutingen.

Test vellykket autentisering, avbrutt/feilet BankID, gamle verdier uten markør,
forsinket EnquiryLog og bytte av person/sak. Sammenlign bare anonymiserte data.

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

-   `sfdx force:org:open` for å åpne instansen(salesforce applikasjonen din).
-   `sfdx force:source:pull` for å hente endringer som du gjør i konfigurasjon i applikasjonen online.
-   `sfdx force:source:push` for å publisere endringer du gjør i kode lokalt til applikasjonen online.

## Scratch oppsett

For å gjøre utvikling og testing enklere så er det lagt inn en del metadata under `force-app\scratch-org`. Metadataen består av permissions, apps og flexipages som gjør innholdet lettere tilgjengelig sånn at man slipper å sette opp dette hver gang man spinner opp en scratch org.

Innholdet pushes og pulles til/fra scratch orgen på samme måte som annen metadata. Denne mappen slettes når vi bruker github actions for å lage pakker.

## Annet

For spørsmål om denne applikasjonen, bruk #crm-nks på Slack.
