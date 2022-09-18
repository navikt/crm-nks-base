@isTest
public with sharing class NKS_KnowledgeBrokenLinksFinderTest {
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
    static void testFindBrokenLinks() {
        NKS_KnowledgeBrokenLinksFinder finder = new NKS_KnowledgeBrokenLinksFinder();

        // make mock data
        List<String> links = new List<String>{ 'https://example.com/fakeLink' };
        Id articleId = [SELECT Id FROM Knowledge__kav LIMIT 1].Id;
        finder.finalList.put(articleId, links);

        Test.startTest();
        Id batchId = Database.executeBatch(finder);
        Test.stopTest();

        System.assertNotEquals(null, batchId);
        System.assertEquals(1, finder.finalList.size());
    }

    @isTest
    static void testdetectRedirect() {
        NKS_KnowledgeBrokenLinksFinder finder = new NKS_KnowledgeBrokenLinksFinder();

        Test.startTest();
        Boolean redirect = NKS_KnowledgeBrokenLinksFinder.detectRedirect(new HttpRequest(), new HttpResponse());
        Test.stopTest();
        System.assertEquals(true, redirect);
    }

    @isTest
    static void testCalloutHttpReqLinkFound() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));

        Test.startTest();
        HttpResponse res = NKS_KnowledgeBrokenLinksFinder.calloutHttpReq(new HttpRequest(), 'https://www.nav.no');
        Test.stopTest();

        System.assertEquals(200, res.getStatusCode());
    }

    @isTest
    static void testCalloutHttpReqLinkNotFound() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(404));

        Test.startTest();
        HttpResponse res = NKS_KnowledgeBrokenLinksFinder.calloutHttpReq(
            new HttpRequest(),
            'https://www.nav.no/testpath'
        );
        Test.stopTest();

        System.assertEquals(404, res.getStatusCode());
    }

    @IsTest
    static void testSendEmail() {
        // make mock data
        Map<Id, List<String>> listToSend = new Map<Id, List<String>>();
        List<String> links = new List<String>{ 'https://example.com/fakeLink' };
        Id articleId = [SELECT Id FROM Knowledge__kav LIMIT 1].Id;
        listToSend.put(articleId, links);
        String[] toAddresses = new List<String>{ 'navnnavnesen@nav.no' };

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        NKS_KnowledgeBrokenLinksFinder.sendEmail(listToSend, toAddresses);
        System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
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
