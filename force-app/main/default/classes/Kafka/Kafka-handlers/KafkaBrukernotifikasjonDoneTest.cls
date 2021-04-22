@IsTest
private class KafkaBrukernotifikasjonDoneTest {
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(
            new Person__c(INT_ActorId__c = '123456789', Name = '12345678901')
        );

        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        UTIL_TestDataFactory.createRecord(
            new UserNotification__c(
                INT_EventId__c = '12345ABcD',
                INT_SystemUser__c = 'testbruker',
                INT_Key__c = 'testbruker12345ABcD',
                INT_EventTime__c = DateTime.now().addDays(-10),
                INT_SocialSecurityNumber__c = '12345678901',
                INT_GroupingId__c = '1234',
                INT_Description__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque id mattis lorem. Donec a dignissim dui, nec varius tellus.',
                INT_Link__c = 'https://www.nav.no/no/ditt-nav',
                INT_SecurityLevel__c = 4,
                INT_VisibleUntil__c = Datetime.now().addDays(-3),
                INT_ExternalNotification__c = false,
                INT_Type__c = 'BESKJED',
                CRM_AccountId__c = accountId,
                INT_GlobalStatus__c = null,
                INT_InternalStatus__c = null,
                INT_CaseTheme__c = null,
                CRM_CaseThemeId__c = null,
                CRM_Done__c = false,
                INT_DoneEventTime__c = null
            )
        );

        UTIL_TestDataFactory.createRecord(
            new UserNotification__c(
                INT_EventId__c = '12345ABcDEFGH',
                INT_SystemUser__c = 'testbruker',
                INT_Key__c = 'testbruker12345ABcDEFGH',
                INT_EventTime__c = DateTime.now().addDays(-9),
                INT_SocialSecurityNumber__c = '12345678901',
                INT_GroupingId__c = '1234',
                INT_Description__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque id mattis lorem. Donec a dignissim dui, nec varius tellus.',
                INT_Link__c = 'https://www.nav.no/no/ditt-nav',
                INT_SecurityLevel__c = 4,
                INT_VisibleUntil__c = null,
                INT_ExternalNotification__c = false,
                INT_Type__c = 'OPPGAVE',
                CRM_AccountId__c = accountId,
                INT_GlobalStatus__c = null,
                INT_InternalStatus__c = null,
                INT_CaseTheme__c = null,
                CRM_CaseThemeId__c = null,
                CRM_Done__c = false,
                INT_DoneEventTime__c = null
            )
        );
    }
    @IsTest
    static void testSetBeskjedEventToDone() {
        KafkaBrukernotifikasjonKey key = new KafkaBrukernotifikasjonKey();
        key.systembruker = 'testbruker';
        key.eventId = '12345ABcD';

        KafkaBrukernotifikasjonBeskjed doneEvent = new KafkaBrukernotifikasjonBeskjed();
        doneEvent.tidspunkt = Datetime.now().getTime();
        doneEvent.fodselsnummer = '12345678901';
        doneEvent.grupperingsId = '1234';

        KafkaMessage__c message = new KafkaMessage__c();
        message.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(key)));
        message.CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(doneEvent)));
        message.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        message.CRM_Topic__c = 'aapen-brukernotifikasjon-nyDone-v1';
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

        message = [
            SELECT Id, CRM_Status__c, CRM_ErrorMessage__c
            FROM KafkaMessage__c
            WHERE Id = :message.Id
        ];

        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message.CRM_Status__c,
            'Excpected that the message had been processed. Error: ' + message.CRM_ErrorMessage__c
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
            WHERE INT_Type__c = 'BESKJED'
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
        System.assertNotEquals(null, userNotification.INT_EventTime__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(doneEvent.tidspunktFormated, userNotification.INT_EventTime__c, 'Expected INT_EventTime__c not to be equal doneEvent.tidspunktFormated');
        // prettier-ignore
        System.assertEquals(doneEvent.fodselsnummer, userNotification.INT_SocialSecurityNumber__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(doneEvent.grupperingsId, userNotification.INT_GroupingId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque id mattis lorem. Donec a dignissim dui, nec varius tellus.', userNotification.INT_Description__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals('https://www.nav.no/no/ditt-nav', userNotification.INT_Link__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(4, userNotification.INT_SecurityLevel__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(null, userNotification.INT_VisibleUntil__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(false, userNotification.INT_ExternalNotification__c, 'Expected value to be false');
        // prettier-ignore
        System.assertEquals('BESKJED', userNotification.INT_Type__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(null, userNotification.CRM_AccountId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_GlobalStatus__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_InternalStatus__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_CaseTheme__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.CRM_CaseThemeId__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(true, userNotification.CRM_Done__c, 'Expected value to be true');
        // prettier-ignore
        System.assertEquals(doneEvent.tidspunktFormated, userNotification.INT_DoneEventTime__c, 'Expected value to be set');
    }

    @IsTest
    static void testSetOppgaveEventToDone() {
        KafkaBrukernotifikasjonKey key = new KafkaBrukernotifikasjonKey();
        key.systembruker = 'testbruker';
        key.eventId = '12345ABcDEFGH';

        KafkaBrukernotifikasjonBeskjed doneEvent = new KafkaBrukernotifikasjonBeskjed();
        doneEvent.tidspunkt = Datetime.now().getTime();
        doneEvent.fodselsnummer = '12345678901';
        doneEvent.grupperingsId = '1234';

        KafkaMessage__c message = new KafkaMessage__c();
        message.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(key)));
        message.CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(doneEvent)));
        message.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        message.CRM_Topic__c = 'aapen-brukernotifikasjon-nyDone-v1';
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

        message = [
            SELECT Id, CRM_Status__c, CRM_ErrorMessage__c
            FROM KafkaMessage__c
            WHERE Id = :message.Id
        ];

        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message.CRM_Status__c,
            'Excpected that the message had been processed. Error: ' + message.CRM_ErrorMessage__c
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
            WHERE INT_Type__c = 'OPPGAVE'
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
        System.assertNotEquals(null, userNotification.INT_EventTime__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(doneEvent.tidspunktFormated, userNotification.INT_EventTime__c, 'Expected INT_EventTime__c not to be equal doneEvent.tidspunktFormated');
        // prettier-ignore
        System.assertEquals(doneEvent.fodselsnummer, userNotification.INT_SocialSecurityNumber__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(doneEvent.grupperingsId, userNotification.INT_GroupingId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque id mattis lorem. Donec a dignissim dui, nec varius tellus.', userNotification.INT_Description__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals('https://www.nav.no/no/ditt-nav', userNotification.INT_Link__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(4, userNotification.INT_SecurityLevel__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_VisibleUntil__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(false, userNotification.INT_ExternalNotification__c, 'Expected value to be false');
        // prettier-ignore
        System.assertEquals('OPPGAVE', userNotification.INT_Type__c, 'Expected value to be set');
        // prettier-ignore
        System.assertNotEquals(null, userNotification.CRM_AccountId__c, 'Expected value to be set');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_GlobalStatus__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_InternalStatus__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.INT_CaseTheme__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(null, userNotification.CRM_CaseThemeId__c, 'Expected value to be null');
        // prettier-ignore
        System.assertEquals(true, userNotification.CRM_Done__c, 'Expected value to be true');
        // prettier-ignore
        System.assertEquals(doneEvent.tidspunktFormated, userNotification.INT_DoneEventTime__c, 'Expected value to be set');
    }

    @IsTest
    static void testEventToDoneTimeError() {
        KafkaBrukernotifikasjonKey key = new KafkaBrukernotifikasjonKey();
        key.systembruker = 'testbruker';
        key.eventId = '12345ABcD';

        KafkaBrukernotifikasjonBeskjed doneEvent = new KafkaBrukernotifikasjonBeskjed();
        doneEvent.tidspunkt = Datetime.now().addDays(-30).getTime();
        doneEvent.fodselsnummer = '12345678901';
        doneEvent.grupperingsId = '1234';

        KafkaMessage__c message = new KafkaMessage__c();
        message.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(key)));
        message.CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(doneEvent)));
        message.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        message.CRM_Topic__c = 'aapen-brukernotifikasjon-nyDone-v1';
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
            KafkaMessageService.STATUS_ERROR,
            message.CRM_Status__c,
            'Excpected that the message was set to error'
        );
    }
}
