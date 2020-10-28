public class NKS_ChatTranscriptService {

    /**
    * @description: Handles storing the chat conversation directly to solve issue
    * with omni channel delayed transcript boyd generation
    * @author Stian Ruud Schikora | 10-27-2020 
    * @param chatId 
    * @param jsonConversation 
    **/
    @AuraEnabled
    public static void storeConversation(String chatId, String jsonConversation) {
        String conversation = ''; //Potentially add generic header including date, queue origin and agent?
        List<Message> messageList = (List<Message>) JSON.deserialize(jsonConversation, List<Message>.class);

        for (Message msg : messageList) {
            conversation += msg.getFormattedMsg();
        }

        update new LiveChatTranscript(Id = chatId, 	NKS_Conversation__c = conversation);
    }

    private class Message{
        private String content;
        private String name;
        private String recordId;
        private String timestamp;
        private String type;

        private boolean isAgentMessage() {
            return type.equalsIgnoreCase('agent');
        }
    
        public String getFormattedMsg() {
            String formattedMessage = isAgentMessage() ? '<div style="text-align: left">' : '<div style="text-align: right"';
            DateTime convertedTimestamp = DateTime.newInstance(Long.valueOf(timestamp));
            formattedMessage += '<p>' + '<b>' + type + ': ' +  '</b> - ' + convertedTimestamp.hour() + ':' +  convertedTimestamp.minute() + ':' +  convertedTimestamp.second() + '</p>';
            formattedMessage += '<p>' + content.escapeXml() + '</p>'; //Escaping any xml tags sent by the end user in the chat
            formattedMessage += '</div><br>';

            return formattedMessage;
        }
    }

}
