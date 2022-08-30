global with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject> {
    private String articleId;
    private Map<Id, List<String>> finalList = new Map<Id, List<String>>();

    global NKS_KnowledgeBrokenLinksFinder(Id articleId) {
        this.articleId = articleId;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query =
            'SELECT Id,AdvisorInformation__c,AdvisorInformationInternal__c,Article__c,EmployerInformation__c,EmployerInformationInternal__c,NKS_English__c,InternationalInformation__c,InternationalInformationInternal__c,NKS_Legislation__c,NKS_Nav_no__c,NKS_Nynorsk__c,NKS_Resources__c,NKS_Summary__c,NKS_UserInformation__c,WhoDoesWhat__c,OwnerId FROM Knowledge__kav WHERE Id = ' +
            articleId;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        String regex1 = '(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&/=]*)';
        Pattern linksPattern = Pattern.compile(regex1);
        //String regex2 = '<a.+<\\/a>';
        //Pattern anchorsPattern = Pattern.compile(regex2);

        for (Knowledge__kav article : scope) {
            Set<String> matches = new Set<String>();
            List<String> resultList = new List<String>();

            // get all text fields for each article
            List<String> strList = new List<String>{
                article.AdvisorInformation__c,
                article.AdvisorInformationInternal__c,
                article.Article__c,
                article.EmployerInformation__c,
                article.EmployerInformationInternal__c,
                article.NKS_English__c,
                article.InternationalInformation__c,
                article.InternationalInformationInternal__c,
                article.NKS_Legislation__c,
                article.NKS_Nav_no__c,
                article.NKS_Nynorsk__c,
                article.NKS_Resources__c,
                article.NKS_Summary__c,
                article.NKS_UserInformation__c,
                article.WhoDoesWhat__c
            };

            if (strList.size() > 0) {
                // find all links
                for (String str : strList) {
                    try {
                        Matcher matcher = linksPattern.matcher(str);

                        while (matcher.find()) {
                            String groupValue = matcher.group();
                            matches.add(groupValue);
                        }
                    } catch (Exception ex) {
                        System.debug(ex.getMessage());
                    }
                }
            }

            for (String str : matches) {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(str);
                req.setMethod('GET');
                Http http = new Http();
                HTTPResponse res = http.send(req);
                if (res.getStatusCode() != 200) {
                    resultList.add(str);
                }
            }

            finalList.put(articleId, resultList);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // First, reserve email capacity for the current Apex transaction to ensure
        // that we won't exceed our daily email limits when sending email after
        // the current transaction is committed.
        //Messaging.reserveSingleEmailCapacity(2);

        // Processes and actions involved in the Apex transaction occur next,
        // which conclude with sending a single email.

        // Now create a new single email message object
        // that will send out a single email to the addresses in the To, CC & BCC list.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Strings to hold the email addresses to which you are sending the email.
        String[] toAddresses = new List<String>{ 'sara.mohammadi@nav.no' };
        String[] ccAddresses = new List<String>{ 'sara.mohammadi@nav.no' };

        // Assign the addresses for the To and CC lists to the mail object.
        mail.setToAddresses(toAddresses);
        mail.setCcAddresses(ccAddresses);

        // Specify the address used when the recipients reply to the email.
        //mail.setReplyTo('support@acme.com');

        // Specify the name used as the display name.
        mail.setSenderDisplayName('Knowledge Broken Links Finder');

        // Specify the subject line for your email address.
        mail.setSubject('Broken Links Raport');

        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);

        // Optionally append the Salesforce email signature to the email.
        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);

        // Specify the text content of the email.
        String body = '';

        for (Id key : finalList.keySet()) {
            List<String> links = finalList.get(key);
            body += 'Article: ' + key + ' has the following dead links:\n';
            for (String str : links) {
                body += str + ', ';
            }
            body += '\n';
        }
        mail.setPlainTextBody(body);
        /*
        mail.setHtmlBody(
            'Your case:<b> ' +
            case.Id +
            ' </b>has been created.<p>' +
            'To view your case <a href=https://MyDomainName.my.salesforce.com/' +
            case.Id +
            '>click here.</a>'
        );
        */

        // Send the email you have created.
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}
