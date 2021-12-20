public with sharing class CRM_SecurityQuestionPicker {
    static final List<String> questions = new List<String>{
        'Hva er bankkontonummeret ditt?',
        'Hva er eposten din?',
        'Hva er fødselsdatoen til barnet ditt?',
        'Hvilken dato giftet du deg?'
    };

    private static SecurityQuestionWrapper getRecursiveQuestion(String accountId, List<Integer> usedQuestions) {
        if (usedQuestions.size() == questions.size()) {
            return new SecurityQuestionWrapper(
                'Klarte ikke å finne et spørsmål',
                'Trykk på "nytt" knappen for å prøve igjen',
                usedQuestions
            );
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

        String ident = [SELECT Id, INT_ActorId__c FROM Person__c WHERE CRM_Account__c = :accountId LIMIT 1][0]
        ?.INT_ActorId__c;

        usedQuestions.add(random);
        String returnAnswer = null;
        switch on random {
            when 0 {
                //Fra TPS
                returnAnswer = getBankAccount(ident);
            }
            when 1 {
                //Fra KRR
                returnAnswer = getEmail(ident, accountId);
            }
            when 2 {
                //Fra PDL
                returnAnswer = getChildBirthday(ident);
            }
            when 3 {
                //Fra PDL
                returnAnswer = getMarriageDate(ident);
            }
            when else {
                returnAnswer = null;
            }
        }

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

    private static String getBankAccount(String ident) {
        TPS_Bankkonto bankkonto = TPS_Persons.getBankkonto(ident);
        return bankkonto?.bankkontoNorge?.bankkontonummer;
    }

    private static String getEmail(String ident, String accountId) {
        List<KrrCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(new List<String>{ ident });
        return (personer[0]?.kontaktinformasjon?.epostadresse != null)
            ? personer[0]?.kontaktinformasjon?.epostadresse
            : [SELECT INT_KrrEmail__c FROM Person__c WHERE CRM_Account__c = :accountId LIMIT 1][0]?.INT_KrrEmail__c;
    }

    private static String getChildBirthday(String ident) {
        PDL_API_Response person = getPersonFields(ident);
        List<String> childrenIdents = PDL_API_Query.getRelationsByRole(person, PDL_ForelderBarnRelasjonRolle.BARN);
        PDL_HentPerson randomChild = null;
        while (childrenIdents.size() > 0) {
            String randomChildIdent = childrenIdents[Integer.valueOf(Math.Random() * childrenIdents.size())];
            PDL_API_Response child = getChild(randomChildIdent);
            if (isValidChild(child, person)) {
                randomChild = child.data.hentPerson;
                break;
            }
        }
        String navn = randomChild.navn[0].fornavn;
        if (randomChild?.navn != null && randomChild?.navn.isEmpty() && randomChild?.navn[0]?.mellomnavn != null) {
            navn += ' ' + randomChild?.navn[0]?.mellomnavn;
        }
        if (randomChild?.navn != null && randomChild?.navn.isEmpty() && randomChild?.navn[0]?.etternavn != null) {
            navn += ' ' + randomChild?.navn[0]?.etternavn;
        }
        return navn;
    }

    private static String getMarriageDate(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.sivilstand.type = true;
        query.hentPerson.sivilstand.gyldigFraOgMed = true;
        PDL_API_Response resp = query.execute();
        if (resp.data.hentPerson.sivilstand[0].type == PDL_Sivilstandstype.GIFT) {
            return resp.data.hentPerson.sivilstand[0].gyldigFraOgMed.format();
        }
        return null;
    }

    private static PDL_API_Response getPersonFields(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.forelderBarnRelasjon.selectAll();
        query.hentPerson.bostedsadresse.vegadresse.selectAll();
        query.hentPerson.bostedsadresse.matrikkeladresse.selectAll();
        return query.execute();
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
        @AuraEnabled
        public List<Integer> usedQuestions;

        public SecurityQuestionWrapper(String question, String answer, List<Integer> usedQuestions) {
            this.question = question;
            this.answer = answer;
            this.usedQuestions = usedQuestions;
        }
    }
}
