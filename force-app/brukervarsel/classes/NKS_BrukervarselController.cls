public with sharing class NKS_BrukervarselController {
    @AuraEnabled(cacheable=true)
    public static List<NKS_BrukervarslingBestilling> getBrukerVarselFromActorId(
        String actorId,
        Date fromDate,
        Date toDate
    ) {
        HttpResponse response = NKS_BrukervarselService.getBrukerVarslerFromActorId(actorId, fromDate, toDate);

        Integer statusCode = response.getStatusCode();

        if (statusCode == 200) {
            return (List<NKS_BrukervarslingBestilling>) JSON.deserialize(
                response.getBody(),
                List<NKS_BrukervarslingBestilling>.class
            );
        } else {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error retrieving brukervarsel \n ' + 'Status: ' + response.getStatus(), null);
            logger.publish();

            if (statusCode == 401) {
                throw new AuraHandledException('Feil med tilganger mot baksystem');
            } else if (statusCode == 500) {
                throw new AuraHandledException(
                    'Feil ved henting av brukervarsel (' +
                    'Status: ' +
                    response.getStatus() +
                    ' Melding: ' +
                    response.getBody() +
                    ')'
                );
            } else {
                throw new AuraHandledException(
                    'Feil ved henting av brukervarsel \n ' +
                    'Status: ' +
                    response.getStatus()
                );
            }
        }
    }
}
