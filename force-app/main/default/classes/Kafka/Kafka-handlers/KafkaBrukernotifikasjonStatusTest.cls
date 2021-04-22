@IsTest
private class KafkaBrukernotifikasjonStatusTest {
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(
            new Person__c(INT_ActorId__c = '123456789', Name = '12345678901')
        );

        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'BAR', Name = 'Barnebidrag', CRM_Code_Set__c = 'Tema')
        );

        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'DAG', Name = 'Dagpenger', CRM_Code_Set__c = 'Tema')
        );

        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'PEN', Name = 'Pensjon', CRM_Code_Set__c = 'Tema')
        );
    }

    @IsTest
    static void testCreateStatusoppdateringEvent() {
        KafkaBrukernotifikasjonKey key = new KafkaBrukernotifikasjonKey();
        key.systembruker = 'testbruker';
        key.eventId = '12345ABcD';

        KafkaBrukernotifikasjonStatusoppdatering statusoppdatering = new KafkaBrukernotifikasjonStatusoppdatering();
        statusoppdatering.tidspunkt = Datetime.now().getTime();
        statusoppdatering.fodselsnummer = '12345678901';
        statusoppdatering.grupperingsId = '1234';
        statusoppdatering.link = 'https://www.nav.no/no/ditt-nav';
        statusoppdatering.sikkerhetsnivaa = 4;
        statusoppdatering.eksternVarsling = false;
        statusoppdatering.statusGlobal = 'MOTTATT';
        statusoppdatering.statusIntern = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
        statusoppdatering.sakstema = 'BAR';

        KafkaMessage__c message = new KafkaMessage__c();
        message.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(key)));
        message.CRM_Value__c = EncodingUtil.base64Encode(
            Blob.valueOf(JSON.serialize(statusoppdatering))
        );
        message.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        message.CRM_Topic__c = 'aapen-brukernotifikasjon-nyStatusoppdatering-v1';
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
                CRM_AccountId__c,
                INT_GlobalStatus__c,
                INT_InternalStatus__c,
                INT_CaseTheme__c,
                CRM_CaseThemeId__c,
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
        System.assertEquals(statusoppdatering.tidspunktFormated, userNotification.INT_EventTime__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.fodselsnummer, userNotification.INT_SocialSecurityNumber__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.grupperingsId, userNotification.INT_GroupingId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.tekst, userNotification.INT_Description__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.link, userNotification.INT_Link__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.sikkerhetsnivaa, userNotification.INT_SecurityLevel__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_VisibleUntil__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(false, userNotification.INT_ExternalNotification__c, 'Expected value to be false');
        // prettier-ignore
        System.assertEquals('STATUSOPPDATERING', userNotification.INT_Type__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(null, userNotification.CRM_AccountId__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(statusoppdatering.statusGlobal, userNotification.INT_GlobalStatus__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.statusIntern, userNotification.INT_InternalStatus__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.sakstema, userNotification.INT_CaseTheme__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(null, userNotification.CRM_CaseThemeId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(false, userNotification.CRM_Done__c, 'Expected value to be false');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_DoneEventTime__c, 'Expected value to be null');
    }

    @IsTest
    static void testCreateStatusoppdateringEventNoCommonCode() {
        KafkaBrukernotifikasjonKey key = new KafkaBrukernotifikasjonKey();
        key.systembruker = 'testbruker';
        key.eventId = '12345ABcD';

        KafkaBrukernotifikasjonStatusoppdatering statusoppdatering = new KafkaBrukernotifikasjonStatusoppdatering();
        statusoppdatering.tidspunkt = Datetime.now().getTime();
        statusoppdatering.fodselsnummer = '12345678901';
        statusoppdatering.grupperingsId = '1234';
        statusoppdatering.link = 'https://www.nav.no/no/ditt-nav';
        statusoppdatering.sikkerhetsnivaa = 4;
        statusoppdatering.eksternVarsling = false;
        statusoppdatering.statusGlobal = 'MOTTATT';
        statusoppdatering.statusIntern = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
        statusoppdatering.sakstema = 'AAA';

        KafkaMessage__c message = new KafkaMessage__c();
        message.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(key)));
        message.CRM_Value__c = EncodingUtil.base64Encode(
            Blob.valueOf(JSON.serialize(statusoppdatering))
        );
        message.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        message.CRM_Topic__c = 'aapen-brukernotifikasjon-nyStatusoppdatering-v1';
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
                CRM_AccountId__c,
                INT_GlobalStatus__c,
                INT_InternalStatus__c,
                INT_CaseTheme__c,
                CRM_CaseThemeId__c,
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
        System.assertEquals(statusoppdatering.tidspunktFormated, userNotification.INT_EventTime__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.fodselsnummer, userNotification.INT_SocialSecurityNumber__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.grupperingsId, userNotification.INT_GroupingId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.tekst, userNotification.INT_Description__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.link, userNotification.INT_Link__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.sikkerhetsnivaa, userNotification.INT_SecurityLevel__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_VisibleUntil__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(false, userNotification.INT_ExternalNotification__c, 'Expected value to be false');
        // prettier-ignore
        System.assertEquals('STATUSOPPDATERING', userNotification.INT_Type__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(null, userNotification.CRM_AccountId__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(statusoppdatering.statusGlobal, userNotification.INT_GlobalStatus__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.statusIntern, userNotification.INT_InternalStatus__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(statusoppdatering.sakstema, userNotification.INT_CaseTheme__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(null, userNotification.CRM_CaseThemeId__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(false, userNotification.CRM_Done__c, 'Expected value to be false');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_DoneEventTime__c, 'Expected value to be null');
    }
}
