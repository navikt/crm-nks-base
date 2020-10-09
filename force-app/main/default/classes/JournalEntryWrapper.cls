public class JournalEntryWrapper {

	public class Dokumentvarianter {
		public String filtype; //Filtype string
		public String fysiskDokument; // Base 64 binary
        public String variantformat; 
        
        public Dokumentvarianter(String filtype, String fysiskDokument, String variantformat) {
            this.filtype = filtype;
            this.fysiskDokument = fysiskDokument;
            this.variantformat = variantformat;
        }
	}

	public class Dokumenter {
		public String tittel;
		public String brevkode;
        public List<Dokumentvarianter> dokumentvarianter;
        
        public Dokumenter(String tittel, String brevkode, List<Dokumentvarianter> dokumentvarianter) {
            this.tittel = tittel;
            this.brevkode = brevkode;
            this.dokumentvarianter = dokumentvarianter;
        }
	}

	public class Sak {
		public String fagsakId;
		public String fagsaksystem;
		public String sakstype;
	}

	public class AvsenderMottaker {
		public String id;
		public String idType;
		public String navn;
	}

	public class Bruker {
		public String id;
		public String idType;
	}

	public String tittel;
	public String journalpostType;
	public String tema;
	public String behandlingstema;
	public String kanal;
	public String journalfoerendeEnhet;
	public AvsenderMottaker avsenderMottaker;
	public Bruker bruker;
	public Sak sak;
	public List<Dokumenter> dokumenter;

	
	public static JournalEntryWrapper parse(String json) {
		return (JournalEntryWrapper) System.JSON.deserialize(json, JournalEntryWrapper.class);
	}
}