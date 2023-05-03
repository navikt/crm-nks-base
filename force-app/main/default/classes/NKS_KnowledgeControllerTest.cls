@isTest
public with sharing class NKS_KnowledgeControllerTest {
    @TestSetup
    static void makeData() {
        List<Knowledge__kav> articles = new List<Knowledge__kav>();
        for (Integer i = 0; i < 10; i++) {
            articles.add(
                new Knowledge__kav(
                    Title = 'TestArticle ' + i,
                    UrlName = 'TestArticle-' + i,
                    Summary = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' +
                        'test url ' +
                        i +
                        ': <a href="https://www.nav.no/testpath" target="_blank">test url</a>',
                    Article__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' +
                        'test url ' +
                        i +
                        ':<a href="https://www.nav.no" target="_blank">nav.no</a>'
                )
            );
        }
        insert articles;

        List<Knowledge__kav> aList = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 10];
        for (Knowledge__kav a : aList) {
            KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);
        }
    }

    @isTest
    static void testGetBrokenLinks() {
        Knowledge__kav article = [
            SELECT
                Id,
                Title,
                AdvisorInformation__c,
                AdvisorInformationInternal__c,
                Article__c,
                EmployerInformation__c,
                EmployerInformationInternal__c,
                NKS_English__c,
                InternationalInformation__c,
                InternationalInformationInternal__c,
                NKS_Legislation__c,
                NKS_Nav_no__c,
                NKS_Nynorsk__c,
                NKS_Resources__c,
                NKS_Summary__c,
                NKS_UserInformation__c,
                WhoDoesWhat__c
            FROM Knowledge__kav
            LIMIT 1
        ];

        Test.startTest();
        Map<String, List<String>> res = NKS_KnowledgeController.getBrokenLinks(article);
        Test.stopTest();

        System.assertEquals(0, res.size());
    }

    @isTest
    static void testSendEmail() {
        // make mock data
        Map<String, Map<String, List<String>>> listToSend = new Map<String, Map<String, List<String>>>();
        Map<String, List<String>> fieldLinks = new Map<String, List<String>>();
        List<String> links = new List<String>{ 'https://example.com/fakeLink' };
        String field = 'NKS_Summary__c';
        fieldLinks.put(field, links);
        String title = [SELECT Id, Title FROM Knowledge__kav LIMIT 1].Title;
        listToSend.put(title, fieldLinks);
        String[] toAddresses = new List<String>{ 'testUser1@example.com' };
        String[] bccAddresses = new List<String>{ 'testUser2@example.com' };

        Test.startTest();
        try {
            System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
            NKS_KnowledgeController.sendEmail(listToSend, toAddresses, bccAddresses);
            System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
        } catch (Exception ex) {
            System.assertEquals('System.EmailException', ex.getTypeName());
        }
        Test.stopTest();
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        Integer statusCode;
        public MockHttpResponseGenerator(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            // Send a mock response for a specific endpoint
            System.assertEquals('GET', req.getMethod());

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            return res;
        }
    }
}
