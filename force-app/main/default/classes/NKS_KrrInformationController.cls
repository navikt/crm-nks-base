public class NKS_KrrInformationController {
    static LoggerUtility logger = new LoggerUtility();

    @AuraEnabled
    public static void updateKrrInformation(String personIdent) {
        Person__c personToUpdate;
        try {
            List<KrrCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
                new List<String>{ personIdent }
            );
            if (!personer.isEmpty()) {
                Id personId = [
                    SELECT Id
                    FROM Person__c
                    WHERE Name = :personIdent
                ]
                ?.Id;
                personToUpdate = new Person__c(
                    Id = personId,
                    INT_KrrEmail__c = personer[0]
                        ?.kontaktinformasjon
                        ?.epostadresse,
                    INT_KrrMobilePhone__c = personer[0]
                        ?.kontaktinformasjon
                        ?.mobiltelefonnummer
                );
                personToUpdate.INT_KRR_Reservation__c =
                    personer[0]?.reservasjon == 'JA';
            }

            if (personToUpdate != null)
                update personToUpdate;
        } catch (Exception e) {
            logger.exception(e, personToUpdate);
            logger.publish();
            throw new AuraHandledException(
                'Failed to refresh KRR information.'
            );
        }
    }
}
