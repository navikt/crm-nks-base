@IsTest
private class KafkaBrukernotifikasjonBeskjedTest {
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789', Name = '12345678901'));
    }
    @IsTest
    static void testCreateBeskjedEvent() {
        KafkaBrukernotifikasjonKey key = new KafkaBrukernotifikasjonKey();
        key.systembruker = 'testbruker';
        key.eventId = '12345ABcD';

        KafkaBrukernotifikasjonBeskjed beskjed = new KafkaBrukernotifikasjonBeskjed();
        beskjed.tidspunkt = Datetime.now().getTime();
        beskjed.fodselsnummer = '12345678901';
        beskjed.grupperingsId = '1234';
        beskjed.synligFremTil = Datetime.now().addDays(7).getTime();
        beskjed.tekst = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque id mattis lorem. Donec a dignissim dui, nec varius tellus.';
        beskjed.link = 'https://www.nav.no/no/ditt-nav';
        beskjed.sikkerhetsnivaa = 4;
        beskjed.eksternVarsling = false;

        KafkaMessage__c message = new KafkaMessage__c();
        message.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(key)));
        message.CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(beskjed)));
        message.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        message.CRM_Topic__c = 'aapen-brukernotifikasjon-nyBeskjed-v1';
        insert message;

        System.assertEquals(
            1,
            [SELECT Id FROM AsyncRequest__c WHERE CRM_Status__c = 'Pending'].size(),
            'Expected one async request record that is pending'
        );

        Test.startTest();
        Database.executeBatch(new AsyncRequestBatchable());
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT Id FROM AsyncRequest__c WHERE CRM_Status__c = 'Processed'].size(),
            'Expected one async request record that is processed'
        );

        message = [SELECT Id, CRM_Status__c FROM KafkaMessage__c WHERE Id = :message.Id];

        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message.CRM_Status__c,
            'Excpected that the message had been processed'
        );

        List<UserNotification__c> userNotificationList = [
            SELECT
                INT_EventId__c,
                INT_SystemUser__c,
                INT_Key__c,
                INT_EventTime__c,
                INT_SocialSecurityNumber__c,
                INT_GroupingId__c,
                INT_Description__c,
                INT_Link__c,
                INT_SecurityLevel__c,
                INT_VisibleUntil__c,
                INT_ExternalNotification__c,
                INT_Type__c,
                CRM_Account__c,
                INT_GlobalStatus__c,
                INT_InternalStatus__c,
                INT_CaseTheme__c,
                CRM_CaseTheme__c,
                CRM_Done__c,
                INT_DoneEventTime__c
            FROM UserNotification__c
        ];
        System.assertEquals(1, userNotificationList.size(), 'Excpected to get a user notification');

        UserNotification__c userNotification = userNotificationList[0];

        // prettier-ignore
        System.assertEquals(key.eventId, userNotification.INT_EventId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(key.systembruker, userNotification.INT_SystemUser__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(key.key, userNotification.INT_Key__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(beskjed.tidspunktFormated, userNotification.INT_EventTime__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(beskjed.fodselsnummer, userNotification.INT_SocialSecurityNumber__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(beskjed.grupperingsId, userNotification.INT_GroupingId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(beskjed.tekst, userNotification.INT_Description__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(beskjed.link, userNotification.INT_Link__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(beskjed.sikkerhetsnivaa, userNotification.INT_SecurityLevel__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(beskjed.synligFremTilFormated, userNotification.INT_VisibleUntil__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(beskjed.eksternVarsling, userNotification.INT_ExternalNotification__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals('BESKJED', userNotification.INT_Type__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(null, userNotification.CRM_Account__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_GlobalStatus__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_InternalStatus__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_CaseTheme__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.CRM_CaseTheme__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(false, userNotification.CRM_Done__c, 'Expected value to be false');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_DoneEventTime__c, 'Expected value to be null');
    }
}
