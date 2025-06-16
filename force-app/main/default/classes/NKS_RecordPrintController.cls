public with sharing class NKS_RecordPrintController {
    public Id recordId { get; set; }
    public String objectType { get; set; }
    public RecordPrintWrapper convoWrapper { get; set; }
    public RecordPrintWrapper threadWrapper { get; set; }
    public String personIdent { get; set; }
    public String navUnitName { get; set; }
    public String accountName { get; set; }

    public NKS_RecordPrintController() {
        recordId = ApexPages.currentPage().getParameters().get('id');
        if (recordId == null) {
            return;
        } 

        objectType = getObjectType(recordId);
        if (objectType == 'Thread__c') {
            fetchThreadData();
        } else if (objectType == 'Conversation_Note__c') {
            fetchConversationNoteData();
        }
    }

    private static String getObjectType(Id recordId) {
        return recordId.getSObjectType().getDescribe().getName();
    }

    private void fetchThreadData() {
        Thread__c thread = [
            SELECT
                Id,
                CRM_Theme_Group_Name__c,
                STO_Category__c,
                CRM_Thread_Type__c,
                Name,
                CRM_Account__r.INT_PersonIdent__c,
                CRM_Account__r.Name
            FROM Thread__c
            WHERE Id = :recordId
        ];

        personIdent = thread.CRM_Account__r.INT_PersonIdent__c;
        accountName = thread.CRM_Account__r.Name;

        List<Message__c> threadMessages = [
            SELECT
                CRM_Message_Text__c,
                CRM_External_Message__c,
                CRM_Sent_date__c,
                CRM_Read__c,
                CRM_Read_Datetime__c,
                CRM_From_First_Name__c,
                CRM_From_Ident_Formula__c
            FROM Message__c
            WHERE CRM_Thread__c = :recordId
        ];

        List<MessageWrapper> messages = new List<MessageWrapper>();
        for (Message__c message : threadMessages) {
            messages.add(new MessageWrapper(message, personIdent));
        }
        threadWrapper = new RecordPrintWrapper(thread, messages);
    }

    private void fetchConversationNoteData() {
        Conversation_Note__c cnote = [
            SELECT
                CRM_Conversation_Note__c,
                CRM_Theme_Group_Name__c,
                CRM_Theme_Name__c,
                CRM_Account__c,
                CRM_Account__r.INT_PersonIdent__c,
                CRM_Account__r.Name,
                CRM_Communication_Channel__c,
                CRM_Date_Time_Registered__c,
                CRM_Created_By_Ident__c,
                CRM_Created_By_NAV_Unit__c
            FROM Conversation_Note__c
            WHERE Id = :recordId
        ];

        NavUnit__c getUnitName = [ 
            SELECT Name FROM NavUnit__c WHERE INT_UnitNumber__c = :cnote.CRM_Created_By_NAV_Unit__c
        ];

        navUnitName = getUnitName.Name;

        personIdent = cnote.CRM_Account__r.INT_PersonIdent__c;
        accountName = cnote.CRM_Account__r.Name;
        convoWrapper = new RecordPrintWrapper(cnote); 
    }

    public class RecordPrintWrapper {
        public SObject mainRecord { get; set; }
        public String createdDate { get; set; }

        // Conversation Note fields
        public String comChannelNorwegian { get; set; }

        // Thread fields
        public List<MessageWrapper> messages { get; set; }
        public String messageFrom { get; set; }
        public String messageRead { get; set; }

        // Thread constructor
        public RecordPrintWrapper (sObject mainRecord, List<MessageWrapper> messages) {
            this.mainRecord = mainRecord;
            this.messages = messages;
        }

        // Conversation Note constructor
        public RecordPrintWrapper (sObject mainRecord) {
            this.mainRecord = mainRecord;
            this.createdDate = dateTimeFormatter((Datetime)mainRecord.get('CRM_Date_Time_Registered__c'));
            this.comChannelNorwegian = translateCommunicationChannel((String)mainRecord.get('CRM_Communication_Channel__c'));
        }

        private String dateTimeFormatter(Datetime dt) {
            return dt?.format();
        }


        private String translateCommunicationChannel(String communicationChannel){
            Map<String, String> communicationChannelMap = new Map<String, String>{'Phone' => 'telefon', 'Meeting' => 'møte'};
            
            if (!String.isBlank(communicationChannel)){
                return communicationChannelMap.get(communicationChannel) ?? communicationChannel;
            }

            return '';
        }
    }

    public class MessageWrapper {
        public Message__c message { get; set; }
        public String createdDate { get; set; }
        public String messageFrom { get; set; }
        public String messageRead { get; set; }
        public String personIdent { get; set; }

        public MessageWrapper(Message__c message, String personIdent) {
            this.message = message;
            this.personIdent = personIdent;
            this.createdDate = message?.CRM_Sent_date__c != null ? message.CRM_Sent_date__c.format() : '';
            this.messageFrom = setMessageFrom(message);
            this.messageRead = setMessageRead(message);
        }

        private String setMessageFrom(Message__c msg) {
            if (msg == null) {
                return '';
            }
            if (msg.CRM_External_Message__c) {
                return (personIdent != null ? personIdent : 'Ukjent') + ' (Bruker)';
            } else {
                return (msg.CRM_From_Ident_Formula__c != null ? msg.CRM_From_Ident_Formula__c : 'Ukjent') + ' (Veileder)';
            }
        }

        private String setMessageRead(Message__c msg) {
            if (msg == null) {
                return '';
            }
            return msg.CRM_Read__c ? 'Lest: ' + msg.CRM_Read_Datetime__c : 'Ulest';
        }
    }
}
