public with sharing class KafkaBrukernotifikasjonDoneHandler extends KafkaBrukernotifikasjonHandler {
    protected override void buildNotification(
        String decodedValue,
        UserNotification__c notification
    ) {
        KafkaBrukernotifikasjonDone done = (KafkaBrukernotifikasjonDone) JSON.deserialize(
            decodedValue,
            KafkaBrukernotifikasjonDone.class
        );

        notification.CRM_Done__c = true;
        notification.INT_DoneEventTime__c = done.tidspunktFormated;
        notification.INT_SocialSecurityNumber__c = done.fodselsnummer;
    }
}
