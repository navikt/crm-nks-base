public with sharing class NKS_BrukervarselController {
    @AuraEnabled(cacheable=true)
    public static List<NKS_BrukervarslingBestilling> getBrukerNotifikasjonFromIdent(String fnr) {
        List<NKS_BrukervarslingBestilling> brukernotifikasjoner = new List<NKS_BrukervarslingBestilling>();

        try {
            for (UN_TmsEventApiEvent notification : new UN_TmsEventApi().getAllEvents(fnr)) {
                NKS_BrukervarslingBestilling bestilling = new NKS_BrukervarslingBestilling();
                bestilling.personIdent = fnr;
                bestilling.varseltypeId = notification.typeLabel + ': ' + notification.tekst;
                bestilling.bestilt = notification.forstBehandletDT;
                bestilling.sisteVarselutsendelse = notification.forstBehandletDT;
                bestilling.brukernotifikasjon = notification;
                brukernotifikasjoner.add(bestilling);
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error retrieving brukervarsel \n ' + 'Exception: ' + e, null);
            logger.publish();
            throw new AuraHandledException('Feil ved henting av brukernotifikasjoner: ' + e.getMessage());
        }
        return brukernotifikasjoner;
    }
}
