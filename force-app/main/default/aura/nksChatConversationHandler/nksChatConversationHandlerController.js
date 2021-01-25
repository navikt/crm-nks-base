({
    handleChatEnded: function (component, event, helper) {
        const chatToolkit = component.find("chatToolkit");
        const eventRecordId = event.getParam('recordId');


        chatToolkit.getChatLog({
            recordId: eventRecordId
        })
            .then(result => {
                let conversation = result.messages;
                let filteredConversation = conversation.filter(function (message, index, arr) {
                    //Filtering out all messages of type supervisor as these are "whispers" and should not be added to the journal
                    return message.type !== 'Supervisor';
                });

                helper.callStoreConversation(component, filteredConversation, eventRecordId);
            })
            .catch(error => {
                //Errors require manual handling.
            });
    }
})
