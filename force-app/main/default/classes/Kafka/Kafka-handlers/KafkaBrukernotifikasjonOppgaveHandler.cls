public with sharing class KafkaBrukernotifikasjonOppgaveHandler extends KafkaBrukernotifikasjonHandler {
    protected override void buildNotification(String decodedValue, UserNotification__c notification) {
        KafkaBrukernotifikasjonOppgave oppgave = (KafkaBrukernotifikasjonOppgave) JSON.deserialize(
            decodedValue,
            KafkaBrukernotifikasjonOppgave.class
        );

        emptyFieldValues(notification);

        notification.INT_EventTime__c = oppgave.tidspunktFormated;
        notification.INT_SocialSecurityNumber__c = oppgave.fodselsnummer;
        notification.INT_GroupingId__c = oppgave.grupperingsId;
        notification.INT_Description__c = oppgave.tekst;
        notification.INT_Link__c = oppgave.link;
        notification.INT_SecurityLevel__c = oppgave.sikkerhetsnivaa;
        notification.INT_ExternalNotification__c = cleanBoolean(oppgave.eksternVarsling);

        notification.INT_Type__c = 'OPPGAVE';
    }
}
