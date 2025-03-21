import { LightningElement, api } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';
import newDesignTemplate from './newDesignTemplate.html';
import standardTemplate from './nksBrukervarsel.html';

export default class NksBrukervarsel extends LightningElement {
    @api brukervarsel;
    @api newDesign = false;

    sortedVarselList;
    showDetails = false;

    render() {
        return this.newDesign ? newDesignTemplate : standardTemplate;
    }

    get showVarselListe() {
        let retValue = this.hasMessageList && this.showDetails;
        if (retValue && this.sortedVarselList == null)
            this.sortedVarselList = [...this.brukervarsel.varselListe].sort(
                (a, b) => (a.sendt < b.sendt) - (a.sendt > b.sendt)
            );
        return retValue;
    }

    get showNotifikasjon() {
        return this.brukervarsel.brukernotifikasjon && this.showDetails;
    }

    get hasMessageList() {
        return this.brukervarsel.varselListe && this.brukervarsel.varselListe.length > 0;
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

        if (this.brukervarsel.brukernotifikasjon) {
            channels.push(`NOTIFIKASJON${this.brukervarsel.brukernotifikasjon.aktiv ? '' : ' (Inaktiv)'}`);
        }

        return channels;
    }

    get varselType() {
        switch (this.brukervarsel.varseltypeId) {
            case 'tilbakemelding.EPOST':
                return 'E-post = ';
            case 'tilbakemelding.NAV.NO':
                return 'Sendt til Ditt Nav';
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
                return 'Innkalling til møte med Nav';
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
                return 'Informasjon om CV på Ditt Nav';
            case 'SyfomoteNyetidspunkt':
                return 'Forespørsel om nye tidspunkt for møte';
            case 'NaermesteLederMoteAvbrutt':
                return 'Møteforespørsel avbrutt';
            default:
                return this.brukervarsel.varseltypeId;
        }
    }

    getChannelLabel(value) {
        switch (value) {
            case 'EPOST':
                return 'E-POST';
            case 'DITT_NAV':
                return 'NAV.NO';
            default:
                return value;
        }
    }

    onShowHide(event) {
        this.showDetails = this.newDesign ? event?.detail?.isExpanded : !this.showDetails;
        publishToAmplitude('UN List', { type: 'toggle show details' });
    }
}
