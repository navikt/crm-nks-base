public with sharing class NKS_NewsXMLGenerator {
    public String businessUnitId { get; set; }
    public String businessUnitName { get; set; }
    public String journalPostStatus { get; set; }
    public String journalPostType { get; set; }
    public String journalPostName { get; set; }
    public String journalCaseNumber { get; set; }
    public String userNavIdent { get; set; }
    public Date submissionDate { get; set; }
    public Map<String, String> documentNameFormat { get; set; }

    public String generateXML() {
        Dom.Document doc = new Dom.Document();
        dom.XmlNode rootNode = doc.createRootElement('NOARK.H', null, null);
        dom.XmlNode noArkSak = rootNode.addChildElement('NOARKSAK', null, null);
        dom.xmlNode caseNumber = noArkSak.addChildElement('SA.SAKID', null, null).addTextNode(journalCaseNumber);
        dom.xmlNode journalPostTab = noArkSak.addChildElement('JOURNALPOST.TAB', null, null);
        dom.xmlNode post = journalPostTab.addChildElement('JOURNALPOST', null, null);
        dom.xmlNode postContent = post.addChildElement('JP.INNHOLD', null, null).addTextNode(journalPostName);
        dom.xmlNode postDate = post.addChildElement('JP.DOKDATO', null, null)
            .addTextNode(formatDateString(submissionDate));
        dom.xmlNode journalPostType = post.addChildElement('JP.DOKTYPE', null, null).addTextNode(journalPostType);
        dom.xmlNode journalPostStatus = post.addChildElement('JP.STATUS', null, null).addTextNode(journalPostStatus);
        dom.xmlNode journalPostNavIdent = post.addChildElement('JP.SB', null, null).addTextNode(userNavIdent);
        dom.xmlNode journalPostUnitId = post.addChildElement('JP.ENHET', null, null).addTextNode(businessUnitId);
        dom.xmlNode journalPostUnitName = post.addChildElement('NAVN', null, null).addTextNode(businessUnitName);
        dom.XmlNode documentTab = post.addChildElement('DOKVERSJON.TAB', null, null);

        for (String docName : documentNameFormat.keyset()) {
            String fileName = docName;
            String fileFormat = documentNameFormat.get(docName);
            dom.XmlNode documentVersion = documentTab.addChildElement('DOKVERSJON', null, null);
            dom.XmlNode documentFormat = documentVersion.addChildElement('VE.DOKFORMAT', null, null)
                .addTextNode(fileFormat);
            dom.XmlNode documentReference = documentVersion.addChildElement('VE.FILREF', null, null)
                .addTextNode(fileName);
        }

        return doc.toXmlString();
    }

    private String formatDateString(Date input) {
        Datetime dateToFormat = input;
        return dateToFormat.formatGmt('YYYYMMdd');
    }
}
