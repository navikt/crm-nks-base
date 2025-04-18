/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 14-02-2023
 * @last modified by  : mamikals
 **/
@isTest
public without sharing class NKS_TestDataFactory {
    public static List<Person__c> createPersons(Integer amount) {
        TestDataFactory.getPublicGroup('Municipality group', 'group_4719');
        List<Person__c> persons = new List<Person__c>();
        for (Integer i = 0; i < amount; i++) {
            Person__c p = new Person__c(
                Name = '1234567890' + i,
                INT_MunicipalityNumber__c = '5501',
                INT_LastName__c = 'Test' + i,
                INT_Confidential__c = 'UGRADERT',
                INT_MaritalStatus__c = 'UOPPGITT'
            );
            persons.add(p);
        }
        insert persons;
        Integer i = 1;
        for (Person__c p : persons) {
            createPersonAccount(i, p);
            i++;
        }
        return persons;
    }

    public static void createPersonAccount(Integer i, Person__c p) {
        String personAccountRecordType = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account acc = new Account(
            FirstName = 'Harry',
            LastName = 'Potter',
            INT_PersonIdent__c = '1234567890' + i,
            RecordTypeId = personAccountRecordType,
            CRM_Person__c = p.Id
        );
        insert acc;
        p.CRM_Account__c = acc.Id;
        update p;
    }

    public static List<SecurityMeasure__c> createSecurityMeasures(Integer amount, Person__c person) {
        List<SecurityMeasure__c> securityMeasures = new List<SecurityMeasure__c>();
        for (Integer i = 0; i < amount; i++) {
            SecurityMeasure__c sm = new SecurityMeasure__c(
                INT_Person__c = person.Id,
                INT_SecurityMeasure__c = 'Telefonisk utestengelse',
                INT_ValidToDate__c = Date.today(),
                INT_ValidFromDate__c = Date.today()
            );
            securityMeasures.add(sm);
        }
        insert securityMeasures;
        return securityMeasures;
    }

    public static List<QuickText> createQuickTexts(Integer amount) {
        List<QuickText> quickTexts = new List<QuickText>();
        for (Integer i = 0; i < amount; i++) {
            QuickText qt = new QuickText(Name = 'Test ' + i, Message = 'Dette er en melding');
            quickTexts.add(qt);
        }
        insert quickTexts;
        return quickTexts;
    }

    public static LiveChatVisitor createLiveChatVisitor() {
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        return visitor;
    }

    public static List<LiveChatTranscript> createLiveChatTranscripts(Integer amount) {
        LiveChatVisitor v = NKS_TestDataFactory.createLiveChatVisitor();
        List<LiveChatTranscript> liveChatTranscripts = new List<LiveChatTranscript>();
        for (Integer i = 0; i < amount; i++) {
            LiveChatTranscript lct = new LiveChatTranscript(LiveChatVisitorId = v.Id);
            liveChatTranscripts.add(lct);
        }
        insert liveChatTranscripts;
        return liveChatTranscripts;
    }

    public static List<NavUnit__c> createNavUnits(Integer amount) {
        Group queue = new Group();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            queue = TestDataFactory.getQueue('NAV Arendal', 'queue_906', 'NavTask__c');
        }
        List<NavUnit__c> units = new List<NavUnit__c>();
        for (Integer i = 0; i < amount; i++) {
            units.add(new NavUnit__c(Name = 'Unit ' + i, CRM_QueueId__c = queue.Id));
        }
        units[0].CRM_QueueId__c = null;
        insert units;
        return units;
    }

    public static List<NKS_Announcement__c> createAnnouncements(Integer amount, Id recordTypeId) {
        List<NKS_Announcement__c> announcements = new List<NKS_Announcement__c>();
        for (Integer i = 0; i < amount; i++) {
            NKS_Announcement__c a = new NKS_Announcement__c(
                Name = 'Test ' + i,
                NKS_Information__c = 'Leveransen lørdag 31. oktober ble levert som planlagt, og NAV Arbeid og ytelser kan derfor nå innvilge dagpenger til personer også fra den 1. november eller senere. Opprinnelig melding 29.10.20: Hvis bruker har søkt om dagpenger med virkningstidspunkt fra 1.november eller senere, så kan vi få henvendelser hvor bruker etterlyser svar på søknaden. NAV Arbeid og ytelser behandler for tiden ingen søknader om dagpenger med virkningstidspunkt (startdato) fra 1. november eller senere. Årsaken er regelverksendringer fra den datoen, som vi må få oppdatert i fagsystemene først, for at utfall i saken skal bli rett.Informer gjerne bruker om dette, og henvis eller til saksbehandlingstidene på nav.no.!!!!',
                RecordTypeId = recordTypeId
            );
            announcements.add(a);
        }
        insert announcements;
        return announcements;
    }

    public static Account getAccount(String lastname) {
        Account a = [SELECT Id FROM Account WHERE LastName = :lastname];
        return a;
    }

    public static Case createCase(String lastname) {
        Account a = [SELECT Id FROM Account WHERE LastName = :lastname];
        Case c = new Case(AccountId = a.Id, Status = 'New', Origin = 'Web');
        insert c;
        return c;
    }
}
