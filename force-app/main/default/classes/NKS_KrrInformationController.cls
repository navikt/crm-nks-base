public without sharing class NKS_KrrInformationController {
    static LoggerUtility logger = new LoggerUtility();

    @AuraEnabled
    public static void updateKrrInformation(String personIdent) {
        List<Person__c> personsToUpdate = new List<Person__c>();        
        try {
            List<KrrCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
                new List<String>{ personIdent }
            );
            if (personer != null && !personer.isEmpty()) {
                for (Person__c person : [SELECT Id FROM Person__c WHERE Name = :personIdent]) {
                    personsToUpdate.add(
                        new Person__c(
                            Id = person.Id,
                            INT_KrrEmail__c = personer[0]?.kontaktinformasjon?.epostadresse,
                            INT_KrrMobilePhone__c = personer[0]?.kontaktinformasjon?.mobiltelefonnummer,
                            INT_LastUpdatedFromKRR__c = sistVerifisertDato(personer[0]),
                            INT_KRR_Reservation__c = personer[0]?.reservasjon == 'JA'
                        )
                    );
                }
            }

            if (!personsToUpdate.isEmpty())
                update personsToUpdate;
        } catch (Exception e) {
            logger.exception(e, personsToUpdate[0]);
            logger.publish();
            throw new AuraHandledException('Failed to refresh KRR information.');
        }
    }

    private static Datetime sistVerifisertDato(KrrCalloutService.Personer pers) {
        Datetime emailVerifisertDato = pers?.kontaktinformasjon?.epostadresse_sist_verifisert;
        Datetime mobileVerifisertDato = pers?.kontaktinformasjon?.mobiltelefonnummer_sist_verifisert;
        if (emailVerifisertDato < mobileVerifisertDato) {
            return mobileVerifisertDato;
        }
        return emailVerifisertDato;
    }
}
