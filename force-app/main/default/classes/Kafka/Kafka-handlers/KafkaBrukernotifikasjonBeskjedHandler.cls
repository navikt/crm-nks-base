public with sharing class KafkaBrukernotifikasjonBeskjedHandler extends KafkaBrukernotifikasjonHandler {
    protected override void buildNotification(String decodedValue, UserNotification__c notification) {
        KafkaBrukernotifikasjonBeskjed beskjed = (KafkaBrukernotifikasjonBeskjed) JSON.deserialize(
            decodedValue,
            KafkaBrukernotifikasjonBeskjed.class
        );

        emptyFieldValues(notification);

        notification.INT_EventTime__c = beskjed.tidspunktFormated;
        notification.INT_SocialSecurityNumber__c = beskjed.fodselsnummer;
        notification.INT_GroupingId__c = beskjed.grupperingsId;
        notification.INT_Description__c = beskjed.tekst;
        notification.INT_Link__c = beskjed.link;
        notification.INT_SecurityLevel__c = beskjed.sikkerhetsnivaa;
        notification.INT_VisibleUntil__c = beskjed.synligFremTilFormated;
        notification.INT_ExternalNotification__c = cleanBoolean(beskjed.eksternVarsling);

        notification.INT_Type__c = 'BESKJED';
    }
}
