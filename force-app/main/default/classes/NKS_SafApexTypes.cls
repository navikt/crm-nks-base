/**
 * Apex types returned from SAF
 * ! Enums should potentially be set as Strings. Might change soon.
 */
public with sharing class NKS_SafApexTypes {
    /**
     * SF Defined Apex Types
     */
    public class safQuery {
		@AuraEnabled public String query;
		@AuraEnabled public SafQueryVariables variables;
	}
    
    public class SafQueryVariables {
		@AuraEnabled public BrukerIdInput brukerId;
		@AuraEnabled public FagsakInput fagsakId;
		@AuraEnabled public String dokumentInfoId;
		@AuraEnabled public Tilknytning tilknytning;
		@AuraEnabled public String fraDato;
		@AuraEnabled public String tilDato;
		@AuraEnabled public List<Tema> tema;
		@AuraEnabled public List<Journalposttype> journalposttyper;
		@AuraEnabled public List<Journalstatus> journalstatuser;
		@AuraEnabled public Integer foerste;
		@AuraEnabled public String etter;
	}
	
	public class SafQueryResponse {
		@AuraEnabled public Dokumentoversikt documentOverview;
		@AuraEnabled public boolean isSuccess;
		@AuraEnabled public safError error;
	}
	
	public class SafGetDocumentResponse {
		@AuraEnabled public boolean isSuccess;
		@AuraEnabled public SafError error;
        @AuraEnabled public string documentString;
        @AuraEnabled public string contentType;
        @AuraEnabled public string contentDisposition;
	}
	
	public class SafError {
		@AuraEnabled public DateTime timestamp;
		@AuraEnabled public Integer status;
		@AuraEnabled public String error;
		@AuraEnabled public String message;
		@AuraEnabled public String path;
    }
    
    public class SafQueryField {
        public string name;
        public List<SafQueryField> queryFields;

        public override String toString() {
            String stringToReturn = name;

            if(null != queryFields && false == queryFields.isEmpty()) {
                stringToReturn += ' { ';

                for(SafQueryField qf : queryFields) {
                    stringToReturn += qf.toString() + ' ';
                }
                stringToReturn += '}';
            }

            return stringToReturn;
        }
    }

    /**
     * SAF Apex types
     */

    public class BrukerIdInput {
		@AuraEnabled public String id;
		@AuraEnabled public BrukerIdType type; //-> Enum
	}
	
	public class FagsakInput {
		@AuraEnabled public String fagsakId;
		@AuraEnabled public String fagsaksystem;
	}
	
	public class AvsenderMottaker {
		@AuraEnabled public String id;
		@AuraEnabled public AvsenderMottakerIdType type; //-> ENUM
		@AuraEnabled public String navn;
		@AuraEnabled public String land;
		@AuraEnabled public String erLikBruker;
	}
	
	public class Bruker {
		@AuraEnabled public String id;
		@AuraEnabled public AvsenderMottakerIdType type; //-> Enum
	}
	
	public class DokumentInfo {
		@AuraEnabled public String dokumentInfoId;
		@AuraEnabled public String tittel;
		@AuraEnabled public String brevkode;
		@AuraEnabled public Dokumentstatus dokumentstatus; //-> Enum
		@AuraEnabled public DateTime datoFerdigstilt;
		@AuraEnabled public String orginalJournalpostId;
		@AuraEnabled public SkjermingsType skjerming; //-> Enum
		@AuraEnabled public List<LogiskVedlegg> logiskeVedlegg;
		@AuraEnabled public List<Dokumentvariant> dokumentVarianter;
	}
	
	public class Dokumentoversikt {
		@AuraEnabled public List<Journalpost> journalposter;
		@AuraEnabled public SideInfo sideInfo;
	}
	
	public class Dokumentvariant {
		@AuraEnabled public String variantformat; //-> Enum VariantFormat
		@AuraEnabled public String filnavn;
		@AuraEnabled public Boolean saksbehandlerHarTilgang;
		@AuraEnabled public String skjerming; //-> Enum SkjermingsType
	}
	
	public class Journalpost {
		@AuraEnabled public String journalpostId;
        @AuraEnabled public String tittel;
        @AuraEnabled public String journalposttype; //-> Enum Journalposttype
        @AuraEnabled public Journalstatus journalstatus; //-> Enum
        @AuraEnabled public Tema tema; //-> Enum
		@AuraEnabled public String temaNavn;
		@AuraEnabled public String behandlingstema;
		@AuraEnabled public String behandlingstemanavn;
		@AuraEnabled public Sak sak;
		@AuraEnabled public Bruker bruker;
		@AuraEnabled public AvsenderMottaker avsenderMottaker;
		@AuraEnabled public String journalforendeEnhet;
		@AuraEnabled public String journalfortAvNavn;
		@AuraEnabled public String opprettetAvNavn;
		@AuraEnabled public Kanal kanal; //-> Enum
		@AuraEnabled public String kanalnavn;
		@AuraEnabled public SkjermingsType skjerming; //-> Enum
		@AuraEnabled public String datoOpprettet; //->Datetime
		@AuraEnabled public List<RelevantDato> relevanteDatoer;
		@AuraEnabled public String antallRetur;
		@AuraEnabled public String eksternReferanseId;
		@AuraEnabled public List<Tilleggsopplysning> tillegsopplysninger;
        @AuraEnabled public List<DokumentInfo> dokumenter;
	}
	
	public class LogiskVedlegg {
		@AuraEnabled public String logiskVedleggId;
		@AuraEnabled public String tittel;
	}
	
	public class RelevantDato {
		@AuraEnabled public DateTime dato;
		@AuraEnabled public Datotype datoType; //-> Enum
	}
	
	public class Sak {
		@AuraEnabled public DateTime datoOpprettet;
		@AuraEnabled public String fagsakId;
		@AuraEnabled public String fagsaksystem;
	}
	
	public class SideInfo {
		@AuraEnabled public String sluttpeker;
		@AuraEnabled public boolean finnesNesteSide;
	}
	
	public class Tilleggsopplysning {
		@AuraEnabled public String nokkel;
		@AuraEnabled public String verdi;
	}
	
	public enum Tilknytning { GJENBRUK, SPLITT }
	public enum AvsenderMottakerIdType { FNR, ORGNR, HPRNR, UTL_ORG, UKJENT }
	public enum SkjermingsType { POL, FEIL }
	public enum Arkivsaksystem { GSAK, PSAK }
	public enum BrukerIdType { AKTOERID, FNR, ORGNR }
	public enum Datotype { DATO_SENDT_PRINT, DATO_EKSPEDERT, DATO_JOURNALFOERT, DATO_REGISTRERT, DATO_AVS_RETUR, DATO_DOKUMENT }
	public enum Dokumentstatus { FERDIGSTILT, AVBRUTT, UNDER_REDIGERING, KASSERT }
	public enum Journalposttype { I, U, N }
	public enum Journalstatus { MOTTATT, JOURNALFOERT, FERDIGSTILT, EKSPEDERT, UNDER_ARBEID, FEILREGISTRERT, UTGAAR, AVBRUTT, UKJENT_BRUKER, RESERVERT, OPPLASTING_DOKUMENT, UKJENT }
	public enum Kanal { ALTINN, EIA, NAV_NO, NAV_NO_UINNLOGGET, SKAN_NETS, SKAN_PEN, SKAN_IM, INNSENDT_NAV_ANSATT, EESSI, EKST_OPPS, SENTRAL_UTSKRIFT, LOKAL_UTSKRIFT, SDP, TRYGDERETTEN, HELSENETTET, INGEN_DISTRIBUSJON, UKJENT }
	public enum Tema { AAP, AAR, AGR, BAR, BID, BIL, DAG, ENF, ERS, FAR, FEI, xFOR, FOS, FUL, FRI, GEN, GRA, GRU, HEL, HJE, IAR, IND, KON, KTR, MED, MOB, OMS, OPA, OPP, PEN, PER, REH, REK, RPO, RVE, SAA, SAK, SAP, SER, SIK, STO, SUP, SYK, SYM, TIL, TRK, xTRY, TSO, TSR, UFM, UFO, UKJ, VEN, YRA, YRK }
    public enum VariantFormat { ARKIV, FULLVERSJON, PRODUKSJON, PRODUKSJON_DLF, SLADDET, ORIGINAL }
    
    /**
     * Helper method for parsin the enums
     * ! Might be moved/removed based on enum decision
     */
    public static Object parseEnum(String enumString, Type enumType) {
        Type cType = Type.forName(String.format('List<{0}>', new List<String>{ enumType.getName() }));
        return ((List<Object>) JSON.deserialize(String.format('["{0}"]', new List<String>{ enumString }), cType))[0];
    }
}
