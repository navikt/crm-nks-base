global class NKS_ChatTranscriptService {
    //INITIATE INTERNAL MAP OF NAV IDENT --> User ID
    @testVisible
    private static Map<String, Id> navIdentUserMap {
        get {
            if (navIdentUserMap == null) {
                navIdentUserMap = new Map<String, Id>();
                for (User usr : [
                    SELECT Id, CRM_NAV_Ident__c
                    FROM User
                    WHERE
                        Id IN (
                            SELECT AssigneeId
                            FROM PermissionSetAssignment
                            WHERE PermissionSetGroup.DeveloperName = 'Kontaktsenter'
                        )
                        AND IsActive = TRUE
                        AND CRM_NAV_Ident__c != NULL
                        AND CRM_NAV_Ident__c != ''
                ]) {
                    navIdentUserMap.put(usr.CRM_NAV_Ident__c, usr.Id);
                }
            }
            return navIdentUserMap;
        }
        private set {
        }
    }

    private static LoggerUtility logger = new LoggerUtility();
    /**
     * @description: Handles storing the chat conversation directly to solve issue
     * with omni channel delayed transcript body generation
     * @author Stian Ruud Schikora | 10-27-2020
     * @param chatId
     * @param jsonConversation
     **/
    @AuraEnabled
    public static void storeConversation(String chatId, String jsonConversation) {
        LiveChatTranscript chatTranscript = getChatDetails(chatId);
        List<Message> messageList = (List<Message>) JSON.deserialize(jsonConversation, List<Message>.class);
        messageList.sort();
        if (
            chatTranscript.NKS_Authentication_Timestamp__c == null ||
            (chatTranscript.NKS_Last_Message_Datetime__c ==
            Datetime.newInstance(Long.valueOf(messageList[messageList.size() - 1].timestamp)))
        ) {
            //Compare last message timestamp from thread to handle issues with multiple EndEvents
            //If the chat was not authenticated, the messages cannot be related to end users
            return;
        }
        List<Message__c> threadMessages = new List<Message__c>();

        try {
            threadMessages = converToThreadMessages(messageList, chatTranscript);
            if (threadMessages.size() > 0)
                insert threadMessages;
            updateThreadClosedate(chatTranscript.NKS_Thread__c, System.now());
        } catch (Exception ex) {
            logger.exception(ex, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    /**
     * @description: Handles conversion of a list of message wrappers into thread messages.
     * @author Stian Ruud Schikora | 02-09-2022
     * @param wrapperMessages
     * @param chatTrans
     * @return List<Message__c>
     **/
    private static List<Message__c> converToThreadMessages(
        List<Message> wrapperMessages,
        LiveChatTranscript chatTrans
    ) {
        List<Message__c> returnMessages = new List<Message__c>();
        Map<Datetime, Message__c> existingMessageMap = getExistingMessages(chatTrans.NKS_Thread__c);
        if (!hasAuthEvent(existingMessageMap.values(), chatTrans.NKS_Authentication_Timestamp__c))
            //If the authentication event has not been added to the thread we create the event
            returnMessages.add(createAuthEventMessage(chatTrans));

        for (Integer i = wrapperMessages.size() - 1; i >= 0; i--) {
            //As message list is sorted we only add messages that does not already exist and stop when we hit an existing entry
            if (!existingMessageMap.containsKey(DateTime.newInstance(Long.valueOf(wrapperMessages[i].timestamp)))) {
                returnMessages.add(convertToThreadMessage(wrapperMessages[i], chatTrans));
            } else {
                break;
            }
        }

        return returnMessages;
    }

    /**
     * @description: Iterates a list of chat messages on a thread and returns true if an event is included.
     * @author Stian Ruud Schikora | 02-09-2022
     * @param threadMessages
     * @return Boolean
     **/
    private static Boolean hasAuthEvent(List<Message__c> threadMessages, Datetime authTimestamp) {
        Boolean hasAuthEvent = false;
        for (Message__c msg : threadMessages) {
            if (msg.CRM_Type__c.equalsIgnoreCase('Event') && msg.CRM_Sent_date__c == authTimestamp) {
                hasAuthEvent = true;
                break;
            }
        }

        return hasAuthEvent;
    }

    /**
     * @description: Gets a map of messages sent times to their message record
     * @author Stian Ruud Schikora | 02-09-2022
     * @param threadId
     * @return List<Message__c>
     **/
    private static Map<Datetime, Message__c> getExistingMessages(String threadId) {
        Map<DateTime, Message__c> returnMap = new Map<DateTime, Message__c>();
        for (Message__c msg : [
            SELECT Id, CRM_Type__c, CRM_Sent_date__c
            FROM Message__c
            WHERE CRM_Thread__c = :threadId
            ORDER BY CRM_Sent_date__c DESC
        ]) {
            returnMap.put(msg.CRM_Sent_date__c, msg);
        }

        return returnMap;
    }

    /**
     * @description: Updating the thread close date. In future context to prevent issue with i.e. record lock when inserting new messages
     * @author Stian Ruud Schikora | 02-09-2022
     * @param threadId
     * @param closeDate
     **/
    @future
    private static void updateThreadClosedate(String threadId, Datetime closeDate) {
        update new Thread__c(Id = threadId, CRM_Closed_Date__c = closeDate);
    }

    /**
     * @description: Creates a message of type event to properly display the authentication event in the thread.
     * @author Stian Ruud Schikora | 02-09-2022
     * @param chatTrans
     * @return Message__c
     **/
    private static Message__c createAuthEventMessage(LiveChatTranscript chatTrans) {
        String authText = chatTrans.LiveChatButton?.WindowLanguage == 'en_US'
            ? 'Started authenticated chat: '
            : 'Startet innlogget chat: ';
        return new Message__c(
            CRM_Thread__c = chatTrans.NKS_Thread__c,
            CRM_Type__c = 'Event',
            CRM_Sent_date__c = chatTrans.NKS_Authentication_Timestamp__c,
            CRM_Read__c = true,
            CRM_Read_Datetime__c = chatTrans.NKS_Authentication_Timestamp__c,
            CRM_Message_Text__c = authText
        );
    }

    /**
     * @description: Converts a message wrapper from the LiveAgent API to a Message__c record
     * @author Stian Ruud Schikora | 01-31-2022
     * @param wrapperMessages
     * @param chatTrans
     * @return List<Message__c>
     **/
    private static Message__c convertToThreadMessage(Message wrapperMessage, LiveChatTranscript chatTrans) {
        Message__c convertedMessage = new Message__c();
        convertedMessage.CRM_Thread__c = chatTrans.NKS_Thread__c;
        convertedMessage.CRM_Message_Text__c = wrapperMessage.content;
        convertedMessage.CRM_Type__c = wrapperMessage.getThreadMessageType();
        convertedMessage.CRM_Sent_date__c = DateTime.newInstance(Long.valueOf(wrapperMessage.timestamp));
        convertedMessage.CRM_Read__c = true;
        convertedMessage.CRM_Read_Datetime__c = convertedMessage.CRM_Sent_date__c;
        if (wrapperMessage.isAgentMessage()) {
            //Agent name is designed to include the NAV ident in parenthesis i.e. (<NAV_IDENT>)
            String navIdent = wrapperMessage.name.substringBetween('(', ')');
            if (!navIdentUserMap.containsKey(navIdent)) {
                logger.error('Could not find user record for agent', chatTrans, CRM_ApplicationDomain.Domain.NKS);
            } else {
                convertedMessage.CRM_From_User__c = navIdentUserMap.get(navIdent);
            }
        } else {
            convertedMessage.CRM_From_Contact__c = chatTrans.ContactId;
        }

        return convertedMessage;
    }

    /**
     * @description: Appends conversation between frida ane end user to the log
     * @author Stian Ruud Schikora | 10-30-2020
     * @param botConversation
     * @return String
     **/
    private static String formatBotConversation(LiveChatTranscript chatTranscript) {
        String conversationText = chatTranscript.LiveChatButton?.WindowLanguage == 'en_US' ? 'Conversation' : 'Samtale';
        String returnText = '<div style="text-align: center">';
        returnText += '<p align="center"><b>' + conversationText + ' - Frida</b></p>';
        returnText += '</div><br>';
        String message;

        String botConversation = chatTranscript.Case.Description;

        //For long conversations string.split() has a chance to encounter regex exceptions. Using custom iterator instead
        BotConversation_Iterator conversationIterator = new BotConversation_Iterator(botConversation);
        while (conversationIterator.hasNext()) {
            message = '<p>' + conversationIterator.next().replaceAll('\r', '<br>').replaceAll('\n', '') + '</p>';
            if (!conversationIterator.hasNext()) {
                message = '<br>' + message;
            }
            returnText += message;
        }

        return returnText;
    }

    private static LiveChatTranscript getChatDetails(String chatId) {
        return [
            SELECT
                AccountId,
                ContactId,
                NKS_Last_Message_Datetime__c,
                NKS_Thread__c,
                NKS_Agent_Greeting_Name__c,
                Body,
                NKS_Conversation__c,
                CaseId,
                Case.NKS_Conversation_Stored__c,
                Case.Description,
                NKS_Authentication_Timestamp__c,
                LiveChatButton.WindowLanguage,
                NKS_Conversation_Stored__c
            FROM LiveChatTranscript
            WHERE Id = :chatId
            FOR UPDATE
        ];
    }

    global class Message implements Comparable {
        private String content;
        public String name;
        private String recordId;
        private String timestamp;
        private String type;

        global Integer compareTo(Object compareTo) {
            Message curMessage = (Message) compareTo;
            Long thisTimestamp = Long.valueOf(timestamp);
            Long curTimestamp = Long.valueOf(curMessage.timestamp);

            if (thisTimestamp < curTimestamp) {
                return -1;
            }
            if (thisTimestamp > curTimestamp) {
                return 1;
            }
            return 0;
        }

        /**
         * @description: Method to translate the live agent message type to the Message__c types
         * @author Stian Ruud Schikora | 01-31-2022
         * @return String
         **/
        public String getThreadMessageType() {
            return type.equalsIgnoreCase('OperatorTransferred') ? 'Event' : 'Message';
        }

        private boolean isAgentMessage() {
            return type.equalsIgnoreCase('agent');
        }
    }

    private class BotConversation_Iterator implements Iterator<String> {
        private String conversation;
        private Integer messageIndex;
        private String message_rowDelimiter = '\r\n';

        public BotConversation_Iterator(String fileData) {
            conversation = fileData;
            messageIndex = fileData.length();
        }

        public Boolean hasNext() {
            return messageIndex >= 0;
        }

        public String next() {
            Integer key = conversation.lastIndexOf(message_rowDelimiter, messageIndex);
            if (key == -1)
                key = 0;

            String row = messageIndex == this.conversation.length()
                ? conversation.subString(key, messageIndex)
                : conversation.subString(key, messageIndex + 1);
            messageIndex = key - 1;
            return row;
        }
    }
}
