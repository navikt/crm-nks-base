@IsTest
private class KafkaBrukernotifikasjonHandlerTest {
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789', Name = '12345678901'));

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
    static void accountMissing() {
        KafkaBrukernotifikasjonKey key = new KafkaBrukernotifikasjonKey();
        key.systembruker = 'testbruker';
        key.eventId = '12345ABcD';

        KafkaBrukernotifikasjonBeskjed beskjed = new KafkaBrukernotifikasjonBeskjed();
        beskjed.tidspunkt = Datetime.now().getTime();
        beskjed.fodselsnummer = '00000000';
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

        message = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message.Id];

        System.assertEquals(
            KafkaMessageService.STATUS_ERROR,
            message.CRM_Status__c,
            'Excpected that the message was set to error'
        );

        System.assertEquals(
            true,
            message.CRM_ErrorMessage__c.containsIgnoreCase('Cannot find account from fodselsnummer'),
            'Excpected that the error message pointed to missing fodselsnummer'
        );

        List<UserNotification__c> userNotificationList = [SELECT Id FROM UserNotification__c];
        System.assertEquals(0, userNotificationList.size(), 'Excpected to get a user notification');
    }

    @IsTest
    static void errorOnUpdateWithOlderKafkamessage() {
        UTIL_TestDataFactory.createRecord(
            new UserNotification__c(
                INT_EventId__c = '12345ABcD',
                INT_SystemUser__c = 'testbruker',
                INT_Key__c = 'testbruker12345ABcD',
                INT_EventTime__c = DateTime.now().addDays(-9),
                INT_SocialSecurityNumber__c = '12345678901',
                INT_GroupingId__c = '1234',
                INT_Description__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque id mattis lorem. Donec a dignissim dui, nec varius tellus.',
                INT_Link__c = 'https://www.nav.no/no/ditt-nav',
                INT_SecurityLevel__c = 4,
                INT_VisibleUntil__c = null,
                INT_ExternalNotification__c = false,
                INT_Type__c = 'OPPGAVE',
                CRM_Account__c = [SELECT Id FROM Account LIMIT 1]
                .Id,
                INT_GlobalStatus__c = null,
                INT_InternalStatus__c = null,
                INT_CaseTheme__c = null,
                CRM_CaseTheme__c = null,
                CRM_Done__c = false,
                INT_DoneEventTime__c = null,
                INT_LastUpdatedFromKafka__c = DateTime.now().addDays(1)
            )
        );

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
            KafkaMessageService.STATUS_ERROR,
            message.CRM_Status__c,
            'Excpected that the message was set to error'
        );
    }
}
