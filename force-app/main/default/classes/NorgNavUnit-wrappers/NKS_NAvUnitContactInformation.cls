public with sharing class NKS_NAvUnitContactInformation {
    @AuraEnabled
    public String enhetNr;
    @AuraEnabled
    public String faksnummer;
    @AuraEnabled
    public Integer id;
    @AuraEnabled
    public String spesielleOpplysninger;
    @AuraEnabled
    public String telefonnummer;
    @AuraEnabled
    public String telefonnummerKommentar;
    @AuraEnabled
    public Epost epost;
    @AuraEnabled
    public Adresse besoeksadresse;
    @AuraEnabled
    public Adresse postadresse;
    @AuraEnabled
    public List<publikumsmottak> publikumsmottak;

    public class Epost {
        @AuraEnabled
        public String adresse;
        @AuraEnabled
        public String kommentar;
        @AuraEnabled
        public Boolean kunIntern;

        public Epost() {
            this.adresse = null;
            this.kommentar = null;
            this.kunIntern = false;
        }
    }

    public class Adresse {
        @AuraEnabled
        public String postnummer;
        @AuraEnabled
        public String poststed;
        @AuraEnabled
        public String adresseTilleggsnavn;
        @AuraEnabled
        public String gatenavn;
        @AuraEnabled
        public String husbokstav;
        @AuraEnabled
        public String husnummer;
        @AuraEnabled
        public String postboksnummer;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String postboksanlegg;
        @AuraEnabled
        public String concatenatedAddress {
            public get {
                return concatAddress();
            }
            private set;
        }

        public Adresse() {
            this.postnummer = null;
            this.poststed = null;
            this.adresseTilleggsnavn = null;
            this.gatenavn = null;
            this.husbokstav = null;
            this.husnummer = null;
            this.postboksnummer = null;
            this.type = null;
            this.postboksanlegg = null;
        }

        public Adresse(
            String gatenavn,
            String husnummer,
            String husbokstav,
            String poststed,
            String postnummer
        ) {
            this.type = 'stedsadresse';
            this.postnummer = postnummer;
            this.poststed = poststed;
            this.adresseTilleggsnavn = null;
            this.gatenavn = gatenavn;
            this.husbokstav = husbokstav;
            this.husnummer = husnummer;
            this.postboksnummer = null;
            this.type = null;
            this.postboksanlegg = null;
        }

        public Adresse(
            String postboksanlegg,
            String postboksnummer,
            String poststed,
            String postnummer
        ) {
            this.type = 'postboksadresse';
            this.postnummer = postnummer;
            this.poststed = poststed;
            this.adresseTilleggsnavn = null;
            this.gatenavn = null;
            this.husbokstav = null;
            this.husnummer = null;
            this.postboksnummer = postboksnummer;
            this.postboksanlegg = postboksanlegg;
        }

        public String concatAddress() {
            String address = '';
            String postalCity = '';

            address += addString(address, adresseTilleggsnavn);

            if (
                true == String.isNotBlank(type) &&
                type.equalsIgnoreCase('postboksadresse')
            ) {
                address += addString(address, 'Postboks');
            }

            address += addString(address, postboksnummer);
            address += addString(address, postboksanlegg);
            address += addString(address, gatenavn);
            address += addString(address, husnummer);
            address += addString(address, husbokstav);

            postalCity += addString(postalCity, postnummer);
            postalCity += addString(postalCity, poststed);

            address += String.isNotBlank(address) &&
                String.isNotBlank(postalCity)
                ? ', '
                : '';
            address += postalCity;

            return address;
        }

        private String addString(String originalString, String stringToAdd) {
            if (String.isBlank(stringToAdd)) {
                return '';
            }

            return String.isNotBlank(originalString)
                ? ' ' + stringToAdd
                : stringToAdd;
        }
    }

    public class Aapningstider {
        @AuraEnabled
        public String dag;
        @AuraEnabled
        public Date dato;
        @AuraEnabled
        public String fra;
        @AuraEnabled
        public Integer id;
        @AuraEnabled
        public String kommentar;
        @AuraEnabled
        public Boolean stengt;
        @AuraEnabled
        public String til;

        public Aapningstider() {
            this.dag = null;
            this.dato = null;
            this.fra = null;
            this.id = null;
            this.kommentar = null;
            this.stengt = false;
            this.til = null;
        }

        public Aapningstider(
            Integer id,
            Date dato,
            String fra,
            String til,
            String kommentar
        ) {
            this.dag = null;
            this.dato = dato;
            this.fra = fra;
            this.id = id;
            this.kommentar = kommentar;
            this.stengt = stengt;
            this.til = til;
        }

        public Aapningstider(
            Integer id,
            String dag,
            String fra,
            String til,
            String kommentar
        ) {
            this.dag = dag;
            this.dato = null;
            this.fra = fra;
            this.id = id;
            this.kommentar = kommentar;
            this.stengt = stengt;
            this.til = til;
        }
    }

    public class Publikumsmottak {
        @AuraEnabled
        public Integer id;
        @AuraEnabled
        public String stedsbeskrivelse;
        @AuraEnabled
        public Adresse besoeksadresse;
        @AuraEnabled
        public List<Aapningstider> aapningstider;

        public Publikumsmottak() {
            this.id = null;
            this.stedsbeskrivelse = null;
            this.besoeksadresse = null;
            this.aapningstider = null;
        }
    }
}
