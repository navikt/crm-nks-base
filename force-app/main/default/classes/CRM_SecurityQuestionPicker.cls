public with sharing class CRM_SecurityQuestionPicker {
    static List<String> questions = new List<String>{
        'Hva er bankkontonummeret ditt?',
        'Hva er eposten din?',
        'Hva er fødselsdatoen til barnet ditt?',
        'Hvilken dato giftet du deg?'
    };

    private static SecurityQuestionWrapper getRecursiveQuestion(String accountId, List<Integer> usedQuestions) {
        if (usedQuestions.size() == questions.size()) {
            return new SecurityQuestionWrapper('Klarte ikke å finne et spørsmål', '', usedQuestions);
        }
        return getSecurityQuestion(accountId, usedQuestions);
    }

    @AuraEnabled(cacheable=true)
    public static SecurityQuestionWrapper getSecurityQuestion(String accountId, List<Integer> usedQuestions) {
        if (usedQuestions.size() == questions.size()) {
            usedQuestions.clear();
        }
        Integer random = Integer.valueOf(Math.Random() * (questions.size() - usedQuestions.size()));
        usedQuestions.sort();
        for (Integer n : usedQuestions) {
            if (random >= n) {
                random++;
            }
        }

        String ident = getIdentification(accountId);

        String returnAnswer = null;
        switch on random {
            when 0 {
                //Fra TPS
                // Sjekk at INT_BankAccountNumberLastModified__c og INT_LastUpdatedFromKRR__c er lik IKKE GJØR DETTE SJEKKE SLACK
                TPS_Bankkonto bankkonto = TPS_Persons.getBankkonto(ident);
                returnAnswer = bankkonto?.bankkontoNorge.bankkontonummer;
            }
            when 1 {
                //Fra KRR
                List<KrrCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
                    new List<String>{ ident }
                );
                returnAnswer = personer[0]?.kontaktinformasjon.epostadresse;
            }
            when 2 {
                //Fra PDL
                PDL_API_Response pdl = getPersonFields(ident);
                List<String> childrenIdents = PDL_API_Query.getRelationsByRole(pdl, PDL_ForelderBarnRelasjonRolle.BARN);
                List<PDL_API_Response> children = getChildren(childrenIdents);
                List<PDL_HentPerson> filteredChildren = filterChildren(children, pdl);
                if (filteredChildren.isEmpty()) {
                    returnAnswer = null;
                } else {
                    PDL_HentPerson randomChild = filteredChildren[
                        Integer.valueOf(Math.Random() * filteredChildren.size())
                    ];
                    returnAnswer =
                        randomChild.navn[0].fornavn +
                        ' ' +
                        randomChild.navn[0].mellomnavn +
                        ' ' +
                        randomChild.navn[0].etternavn +
                        '\n' +
                        randomChild.foedsel[0].foedselsdato.format();
                }
            }
            when 3 {
                PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
                query.hentPerson.sivilstand.type = true;
                query.hentPerson.sivilstand.gyldigFraOgMed = true;
                PDL_API_Response resp = query.execute();
                if (resp.data.hentPerson.sivilstand[0].type == PDL_Sivilstandstype.GIFT) {
                    returnAnswer = resp.data.hentPerson.sivilstand[0].gyldigFraOgMed.format();
                }
            }
            when else {
                returnAnswer = 'Ja';
            }
        }
        usedQuestions.add(random);
        if (returnAnswer == null) {
            return getRecursiveQuestion(accountId, usedQuestions);
        }
        SecurityQuestionWrapper securityQuestion = new SecurityQuestionWrapper(
            questions[random],
            returnAnswer,
            usedQuestions
        );
        return securityQuestion;
    }

    private static String getIdentification(String accountId) {
        Person__c person = [SELECT Id, INT_ActorId__c FROM Person__c WHERE CRM_Account__c = :accountId LIMIT 1][0];
        return person?.INT_ActorId__c;
    }

    private static PDL_API_Response getPersonFields(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.forelderBarnRelasjon.selectAll();
        query.hentPerson.bostedsadresse.vegadresse.husnummer = true;
        query.hentPerson.bostedsadresse.vegadresse.husbokstav = true;
        query.hentPerson.bostedsadresse.vegadresse.adressenavn = true;
        query.hentPerson.bostedsadresse.vegadresse.postnummer = true;
        return query.execute();
    }

    private static List<PDL_API_Response> getChildren(List<String> children) {
        List<PDL_API_Response> returnList = new List<PDL_API_Response>();
        for (String ident : children) {
            PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
            query.hentPerson.navn.fornavn = true;
            query.hentPerson.navn.mellomnavn = true;
            query.hentPerson.navn.etternavn = true;
            query.hentPerson.adressebeskyttelse.gradering = true;
            query.hentPerson.foedsel.foedselsdato = true;
            //query.hentPerson.bostedsadresse; // Vet ikke hvilken adresse jeg skal bruke.
            query.hentPerson.doedsfall.doedsdato = true;
            PDL_API_Response pdl = query.execute();
            returnList.add(pdl);
        }
        return returnList;
    }

    private static List<PDL_HentPerson> filterChildren(List<PDL_API_Response> children, PDL_API_Response parent) {
        List<PDL_HentPerson> viableChildren = new List<PDL_HentPerson>();
        for (PDL_API_Response child : children) {
            if (
                checkAge(child) &&
                NKS_FamilyViewController.hasSameAddress(parent, child) &&
                child.data.hentperson.doedsfall[0]?.doedsdato == null
            ) {
                viableChildren.add(child.data.hentPerson);
            }
        }
        return viableChildren;
        // harSammeBosted();
        // barn.tilPerson.diskresjonskode
        // !erDød(barn.tilPerson.personstatus)
        // !harDødsDato(barn)
    }

    private static Boolean checkAge(PDL_API_Response child) {
        Date foedselsdato = child.data.hentPerson.foedsel[0].foedselsdato;
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

    private static Boolean checkAdresse(PDL_API_Response child, PDL_Bostedsadresse adresse) {
        // Gidd ikke nå. Får se på det senere
        return true;
    }

    public class SecurityQuestionWrapper {
        @AuraEnabled
        public String question;
        @AuraEnabled
        public String answer;
        @AuraEnabled
        public List<Integer> usedQuestions;

        public SecurityQuestionWrapper(String question, String answer, List<Integer> usedQuestions) {
            this.question = question;
            this.answer = answer;
            this.usedQuestions = usedQuestions;
        }
    }
}
