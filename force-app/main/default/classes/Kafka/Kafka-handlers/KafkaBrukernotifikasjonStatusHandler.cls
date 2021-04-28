public with sharing class KafkaBrukernotifikasjonStatusHandler extends KafkaBrukernotifikasjonHandler {
    protected override void buildNotification(String decodedValue, UserNotification__c notification) {
        KafkaBrukernotifikasjonStatusoppdatering statusoppdatering = (KafkaBrukernotifikasjonStatusoppdatering) JSON.deserialize(
            decodedValue,
            KafkaBrukernotifikasjonStatusoppdatering.class
        );

        emptyFieldValues(notification);

        notification.INT_EventTime__c = statusoppdatering.tidspunktFormated;
        notification.INT_SocialSecurityNumber__c = statusoppdatering.fodselsnummer;
        notification.INT_GroupingId__c = statusoppdatering.grupperingsId;
        notification.INT_Link__c = statusoppdatering.link;
        notification.INT_SecurityLevel__c = statusoppdatering.sikkerhetsnivaa;
        notification.INT_GlobalStatus__c = statusoppdatering.statusGlobal;
        notification.INT_InternalStatus__c = statusoppdatering.statusIntern;
        notification.INT_CaseTheme__c = statusoppdatering.sakstema;
        notification.INT_ExternalNotification__c = false;

        notification.INT_Type__c = 'STATUSOPPDATERING';
        notification.CRM_CaseTheme__c = commonCodeMap.get(statusoppdatering.sakstema);
    }
}
