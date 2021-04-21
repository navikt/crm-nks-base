@isTest
public class KafkaOppgaveHandler_Test {
    static KafkaOppgaveHandler handler = new KafkaOppgaveHandler();
    static KafkaOppgave version1;
    static KafkaOppgave version2;
    static KafkaOppgave errorTest;
    static KafkaOppgave invalidNavUnitTest;
    static KafkaOppgave updateTest;

    private static void makeMocks() {
        KafkaOppgave.LegacyIdent idt = new KafkaOppgave.LegacyIdent();
        idt.identType = 'AKTOERID';
        idt.verdi = '123456789';

        KafkaOppgave testOppgave = new KafkaOppgave();
        testOppgave.id = 53336;
        testOppgave.tildeltEnhetsnr = '2990';
        testOppgave.tilordnetRessurs = 'Z994995';
        testOppgave.tema = 'BAR';
        testOppgave.oppgavetype = 'KONT_BRUK';
        testOppgave.versjon = 1;
        testOppgave.beskrivelse = 'TEST DESCRIPTION';
        testOppgave.fristFerdigstillelse = '2021-01-14';
        testOppgave.opprettetTidspunkt = '2021-01-12';
        testOppgave.prioritet = 'NORM';
        testOppgave.status = 'AAPNET';
        testOppgave.ident = idt;

        version1 = testOppgave;

        version2 = testOppgave.clone();
        version2.versjon = 2;
        version2.beskrivelse = 'NEW TEST DESCRIPTION';

        errorTest = testOppgave.clone();
        errorTest.id = 53337;
        errorTest.ident = new KafkaOppgave.LegacyIdent();
        errorTest.ident.verdi = '0000000';
        errorTest.ident.identType = 'AKTOERID';

        invalidNavUnitTest = testOppgave.clone();
        invalidNavUnitTest.id = 53338;
        invalidNavUnitTest.tildeltEnhetsnr = '0000';

        updateTest = testOppgave.clone();
        updateTest.id = 53339;
    }
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789'));
        UTIL_TestDataFactory.createRecord(new NavUnit__c(INT_UnitNumber__c = '2990'));
        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'BAR', Name = 'Barnebidrag', CRM_Code_Set__c = 'Tema')
        );
        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'KONT_BRUK', Name = 'Kontakt Bruker', CRM_Code_Set__c = 'Oppgavetyper')
        );
        UTIL_TestDataFactory.createRecord(new NavTask__c(Name = 'TEST TASK', INT_External_Reference__c = 53339));
    }

    @isTest
    static void testMessageProcessing() {
        List<KafkaMessage__c> messages = new List<KafkaMessage__c>();
        makeMocks();

        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53336',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(version1)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53336',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(version2)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53337',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(errorTest)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53338',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(invalidNavUnitTest)))
            )
        );
        messages.add(
            new KafkaMessage__c(
                CRM_Key__c = '53339',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(updateTest)))
            )
        );

        Test.startTest();
        handler.processMessages(messages);
        Test.stopTest();

        System.debug([SELECT Log_Message__c, Pay_Load__c FROM Application_Log__c]);

        System.assert([SELECT COUNT() FROM NavTask__c] != 0);
        System.assert([SELECT COUNT() FROM NavTask__c WHERE CRM_NavUnit__c = NULL] == 1);
    }
}
