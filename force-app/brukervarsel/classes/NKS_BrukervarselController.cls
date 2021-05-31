public with sharing class NKS_BrukervarselController {
    @AuraEnabled(cacheable=true)
    public static List<BrukervarslingBestilling> getBrukerVarselFromActorId(String actorId) {
        HttpResponse response = NKS_BrukervarselService.getBrukerVarslerFromActorId(actorId);

        Integer statusCode = response.getStatusCode();

        if (statusCode == 200) {
            return (List<BrukervarslingBestilling>) JSON.deserialize(
                response.getBody(),
                List<BrukervarslingBestilling>.class
            );
        } else {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error retrieving brukervarsel \n ' + 'Status: ' + response.getStatus(), null);
            logger.publish();
            AuraHandledException ex = new AuraHandledException('Error retrieving brukervarsel');
            ex.setMessage('Error retrieving brukervarsel');
            throw ex;
        }
    }

    // public static void doBrukervarselSynch(String personId) {
    //     List<UserNotification__c> unList = new List<UserNotification__c>();
    //     Person__c person = [SELECT Id, CRM_Account__c, INT_ActorId__c FROM Person__c WHERE Id = :personId LIMIT 1];

    //     if (person != null) {
    //         for (BrukervarslingBestilling bestilling : getBrukerVarselFromActorId(person.INT_ActorId__c)) {
    //             for (Brukervarsel varsel : bestilling.varselListe) {
    //                 unList.add(transformVarselIntoNotification(bestilling, varsel, person.CRM_Account__c));
    //             }
    //         }

    //         if (unList.size() > 0) {
    //             Database.upsert(unList, UserNotification__c.INT_Key__c);
    //         }
    //     } else {
    //         LoggerUtility logger = new LoggerUtility();
    //         logger.error('Error retrieving brukervarsel \n ' + 'no person found with id ' + personId, null);
    //         logger.publish();
    //         AuraHandledException ex = new AuraHandledException('Error retrieving brukervarsel');
    //         ex.setMessage('Error retrieving brukervarsel');
    //         throw ex;
    //     }
    // }

    // private static UserNotification__c transformVarselIntoNotification(
    //     BrukervarslingBestilling bestilling,
    //     Brukervarsel varsel,
    //     String accountId
    // ) {
    //     UserNotification__c notification = new UserNotification__c();
    //     notification.CRM_Account__c = accountId;
    //     notification.INT_Description__c =
    //         (String.isNotBlank(varsel.varseltittel) ? varsel.varseltittel + ': ' : '') + varsel.varseltekst;
    //     notification.INT_EventId__c = varsel.kanal + bestilling.varseltypeId + varsel.sendt.getTime();
    //     notification.INT_SystemUser__c = 'sfInternalBrukervarsel';
    //     notification.INT_EventTime__c = varsel.sendt;
    //     notification.INT_ExternalNotification__c = varsel.kanal.equals('EPOST') || varsel.kanal.equals('SMS')
    //         ? true
    //         : false;
    //     notification.INT_Key__c = notification.INT_EventId__c + '' + notification.INT_SystemUser__c;
    //     notification.INT_Link__c = varsel.varselURL;
    //     notification.INT_Type__c = 'VARSEL';
    //     notification.NotificationType__c = bestilling.varseltypeId;

    //     return notification;
    // }
}
