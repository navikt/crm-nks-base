public with sharing class CRM_SecurityQuestionPicker {
    /**
     * @description get questions regarding registered bank account in TPS
     * @author Tor Håkon Sigurdsen
     * @param  ident ident description
     * @return       List with questions
     */
    @AuraEnabled(cacheable=true)
    public static List<SecurityQuestionWrapper> getQuestionsTPS(String ident) {
        List<SecurityQuestionWrapper> questions = new List<SecurityQuestionWrapper>();
        TPS_Bankkonto bankkonto = TPS_Persons.getBankkonto(ident);
        String bankAccountNumber = bankkonto?.bankkontoNorge?.bankkontonummer;
        if (String.isNotBlank(bankAccountNumber)) {
            questions.add(new SecurityQuestionWrapper('Hva er bankkontonummeret ditt?', bankAccountNumber));
        }

        return questions;
    }

    /**
     * @description Get question regarding the email registered in KRR
     * @author Tor Håkon Sigurdsen
     * @param  ident ident description
     * @return       List with questions
     */
    @AuraEnabled(cacheable=true)
    public static List<SecurityQuestionWrapper> getQuestionsKRR(String ident) {
        List<SecurityQuestionWrapper> questions = new List<SecurityQuestionWrapper>();
        List<KrrCalloutService.Person> personer = KrrCalloutService.doPersonOppslag2(new List<String>{ ident }, null);

        if (personer != null && personer.size() > 0) {
            String email = personer[0]?.epostadresse;
            if (String.isNotBlank(email) || email != null || email != 'null') {
                questions.add(new SecurityQuestionWrapper('Hva er e-posten din?', email));
            }
        }

        return questions;
    }

    /**
     * @description Used to generate questions regarding marriage date and name/birth of child
     * @author Tor Håkon Sigurdsen
     * @param  ident actorId or natural ident
     * @return       List of security questions
     */
    @AuraEnabled(cacheable=true)
    public static List<SecurityQuestionWrapper> getQuestionsPDL(String ident) {
        List<SecurityQuestionWrapper> questions = new List<SecurityQuestionWrapper>();

        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.sivilstand.type = true;
        query.hentPerson.sivilstand.gyldigFraOgMed = true;
        query.hentPerson.forelderBarnRelasjon.selectAll();
        query.hentPerson.bostedsadresse.vegadresse.selectAll();
        query.hentPerson.bostedsadresse.matrikkeladresse.selectAll();
        PDL_API_Response person = query.execute();

        if (person?.data?.hentPerson != null) {
            if (
                person.data.hentPerson.sivilstand.size() > 0 &&
                person.data.hentPerson.sivilstand[0].type == PDL_Sivilstandstype.GIFT &&
                person.data.hentPerson.sivilstand[0].gyldigFraOgMed != null
            ) {
                questions.add(
                    new SecurityQuestionWrapper(
                        'Hvilken dato giftet du deg?',
                        person.data.hentPerson.sivilstand[0].gyldigFraOgMed.format()
                    )
                );
            }

            if (person.data.hentPerson.forelderBarnRelasjon.size() > 0) {
                for (String childIdent : PDL_API_Query.getRelationsByRole(person, PDL_ForelderBarnRelasjonRolle.BARN)) {
                    PDL_API_Response child = getChild(childIdent);
                    if (isValidChild(child, person)) {
                        String name = getFullName(child);
                        String birthday = child.data.hentPerson.foedsel[0].foedselsdato.format();

                        questions.add(
                            new SecurityQuestionWrapper('Hva er fødselsdatoen til barnet ditt?', name + '\n' + birthday)
                        );
                    }
                }
            }
        }

        return questions;
    }

    private static String getFullName(PDL_API_Response person) {
        List<String> nameList = new List<String>();
        if (person?.data?.hentPerson?.navn != null && !person.data.hentPerson.navn.isEmpty()) {
            if (String.isNotBlank(person.data.hentPerson.navn[0].fornavn)) {
                nameList.add(person.data.hentPerson.navn[0].fornavn);
            }

            if (String.isNotBlank(person.data.hentPerson.navn[0].mellomnavn)) {
                nameList.add(person.data.hentPerson.navn[0].mellomnavn);
            }

            if (String.isNotBlank(person.data.hentPerson.navn[0].etternavn)) {
                nameList.add(person.data.hentPerson.navn[0].etternavn);
            }
        }
        return String.join(nameList, ' ').normalizeSpace();
    }

    private static PDL_API_Response getChild(String childIdent) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(childIdent);
        query.hentPerson.navn.fornavn = true;
        query.hentPerson.navn.mellomnavn = true;
        query.hentPerson.navn.etternavn = true;
        query.hentPerson.adressebeskyttelse.gradering = true;
        query.hentPerson.foedsel.foedselsdato = true;
        query.hentPerson.bostedsadresse.vegadresse.selectAll();
        query.hentPerson.bostedsadresse.matrikkeladresse.selectAll();
        query.hentPerson.deltBosted.vegadresse.selectAll();
        query.hentPerson.deltBosted.matrikkeladresse.selectAll();
        query.hentPerson.doedsfall.doedsdato = true;
        return query.execute();
    }

    private static Boolean isValidChild(PDL_API_Response child, PDL_API_Response parent) {
        // Sjekker diskresjonskode, at barn er under 21, ikke død og bor med forelderen.
        return (NKS_FamilyViewController.getConfidentialStatus(child) == null &&
        checkAge(child) &&
        NKS_FamilyViewController.hasSameAddress(parent, child) &&
        (child.data.hentperson?.doedsfall == null ||
        child.data.hentperson?.doedsfall?.isEmpty() ||
        child.data.hentperson?.doedsfall[0]?.doedsdato == null));
    }

    private static Boolean checkAge(PDL_API_Response child) {
        Date foedselsdato = child.data?.hentPerson?.foedsel[0]?.foedselsdato;
        if (foedselsdato == null) {
            return false;
        }
        Date today = Date.today();
        Integer alder = (today.year() - foedselsdato.year());
        // Checks if their birthday hasnt happened yet.
        if (
            (today.month() <= foedselsdato.month() &&
            (today.month() != foedselsdato.month() ||
            today.day() < foedselsdato.day()))
        ) {
            alder--;
        }
        return alder < 21;
    }

    public class SecurityQuestionWrapper {
        @AuraEnabled
        public String question;
        @AuraEnabled
        public String answer;

        public SecurityQuestionWrapper(String question, String answer) {
            this.question = question;
            this.answer = answer;
        }
    }
}
