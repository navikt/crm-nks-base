import { LightningElement, api } from 'lwc';

export default class NksBrukervarsel extends LightningElement {
    @api brukervarsel;

    showDetails = false;

    get showVarselListe() {
        return this.hasMessageList && this.showDetails === true;
    }

    get hasMessageList() {
        return this.brukervarsel.varselListe && this.brukervarsel.varselListe.length > 0 ? true : false;
    }

    get getDate() {
        return this.brukervarsel.bestilt
            ? new Date(this.brukervarsel.bestilt).toLocaleDateString('no-NO', {
                  year: 'numeric',
                  month: '2-digit',
                  day: '2-digit'
              })
            : null;
    }

    get channelList() {
        let channels = [];

        if (this.brukervarsel.varselListe) {
            this.brukervarsel.varselListe.forEach((varsel) => {
                let channelLabel = this.getChannelLabel(varsel.kanal);

                if (channelLabel && false === channels.includes(channelLabel)) {
                    channels.push(channelLabel);
                }
            });
        }
        return channels;
    }

    get varselType() {
        switch (this.brukervarsel.varseltypeId) {
            case 'tilbakemelding.EPOST':
                return 'Epost = ';
            case 'tilbakemelding.NAV.NO':
                return 'Sendt til Ditt NAV';
            case 'tilbakemelding.SMS':
                return 'Tlf. = ';
            case '1.GangVarselBrevPensj':
                return 'Brev fra pensjon';
            case '2.GangVarselBrevPensj':
                return 'Brev fra pensjon';
            case 'DOKUMENT':
                return 'Dokument';
            case 'DittNAV_000001':
                return 'Dokument - Møteinnkalling';
            case 'DittNAV_000002':
                return 'Dokument - Brev';
            case 'DittNAV_000003':
                return 'Dokument - Saksbehandlingstid';
            case 'DittNAV_000004':
                return 'Dokument - Vedtaksbrev';
            case 'DittNAV_000005':
                return 'Dokument - Vedtaksbrev';
            case 'DittNAV_000007':
                return 'Aktivitetsplan - Nye henvendelser';
            case 'DittNAV_000008':
                return 'Aktivitetsplan - Oppgave';
            case 'DittNAV_000010':
                return 'Dokument - Årsoppgave';
            case 'DittNAV_000011':
                return 'Dokument - Endringsoppgave';
            case 'DittNAV_000001_temp':
                return 'Innkalling til møte med NAV';
            case 'EessiPenVarsleBrukerUfore':
                return 'EØS- Opplysninger';
            case 'ForeldrepengerSoknadsvarsel':
                return 'Foreldrepengesøknad';
            case 'GodkjentAMO':
                return 'Aktivitetsplan - Godkjent AMO';
            case 'Gruppeaktivitet':
                return 'Gruppeaktivitet';
            case 'AktivitetsplanMoteVarsel':
                return 'Aktivitetsplan - Møte';
            case 'IkkeLevMeldekortNO':
                return 'Påminnelse om å sende meldekort';
            case 'IkkeLevMeldekortNY':
                return 'Påminnelse om å sende meldekort';
            case 'IkkeMeldtSegFristNO':
                return 'Informasjon om for sen melding uten inaktivering';
            case 'IkkeMeldtSegFristNY':
                return 'Informasjon om for sen melding uten inaktivering';
            case 'IndividuellSamtale':
                return 'Individuellsamtale';
            case 'KRR_NyeDigitaleBrukere':
                return 'Brev fra pensjon';
            case 'MOTE':
                return 'Møte';
            case 'PermitteringSnartOppbrukt':
                return 'Dagpenger under permittering';
            case 'RettTil4UkerFerie':
                return 'Rett til Dagpenger under ferie';
            case 'RettTil4UkerFerieKonvertertInn':
                return 'Rett til Dagpenger under ferie';
            case 'RettTil4UkerFerieOppbrukt':
                return 'Opphør av dagpenger under ferie';
            case 'SPORSMAL':
                return 'Spørsmål';
            case 'SVAR':
                return 'Svar';
            case 'INFOMELDING':
                return 'Infomelding';
            case 'SyfoAktivitetskrav':
                return 'Informasjon om aktivitetsplikt';
            case 'SyfoMoteAvbrutt':
                return 'Dialogmøte er avbrutt';
            case 'SyfoMoteNyeTidspunkt':
                return 'Dialogmøte nye tidspunkt foreslått';
            case 'SyfoMotebekreftelse':
                return 'Møtebekreftelse';
            case 'SyfoMoteforesporsel':
                return 'Dialogmøte';
            case 'SyfoOppgave':
                return 'Sykmelding';
            case 'SyfoSykepengesoknad':
                return 'Sykepengesøknad';
            case 'NyttSykepengevedtak':
                return 'Nytt sykepengevedtak';
            case 'UR_StoppPrint':
                return 'Utbetalingsmelding';
            case 'NySykmelding':
                return 'Ny sykmelding';
            case 'NySykmeldingUtenLenke':
                return 'Ny sykmelding';
            case 'SyfoplanOpprettetSyk':
                return 'Oppfølgingsplan påbegynt av leder';
            case 'SyfoplangodkjenningSyk':
                return 'Oppfølgingsplan venter godkjenning';
            case 'SyfoSvarMotebehov':
                return 'Avventer svar om behov for dialogmøte';
            case 'SyfoplanRevideringSyk':
                return 'Venter på revidering fra bruker';
            case 'SyfoMerVeiledning':
                return 'Snart slutt på sykepenger';
            case 'PAM_KONV01':
                return 'Ny og forbedret CV-løsning';
            case 'PAM_SYNLIGHET_01':
                return 'Informasjon om CV på Ditt NAV';
            case 'SyfomoteNyetidspunkt':
                return 'Forespørsel om nye tidspunkt for møte';
            case 'NaermesteLederMoteAvbrutt':
                return 'Møteforespørsel avbrutt';
            default:
                return brukervarsel.varseltypeId;
        }
    }

    getChannelLabel(value) {
        switch (value) {
            case 'DITT_NAV':
                return 'NAV.NO';
            default:
                return value;
        }
    }

    onShowHide() {
        this.showDetails = !this.showDetails;
    }
}
