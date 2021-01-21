({
    //Handles event from LWC to init the auth process using the conversation toolkit API
    requestAuthentication: function (component, event, helper) {
        const chatToolkit = component.find("chatToolkit");
        const recordId = component.get("v.recordId");
        const authInfoCmp = component.find("chatAuthInfo");
        let authUrl = event.getParam('authUrl');

        chatToolkit.sendMessage({
            recordId: recordId,
            message: {
                text: "Init:Auth:" + authUrl + recordId
            }
        })
            .then(function (result) {
                //Call child to handle message result
                authInfoCmp.authRequestHandling(result);
            });
    },

    showLoginMsg: function (component, event, helper) {
        const chatToolkit = component.find("chatToolkit");
        const recordId = component.get("v.recordId");
        const loginMsg = event.getParam('loginMessage');

        chatToolkit.sendMessage({
            recordId: recordId,
            message: {
                text: loginMsg
            }
        })
            .then(function (result) {
                //Message success
            });
    },

    handleChatEnded: function (component, event, helper) {
        const chatToolkit = component.find("chatToolkit");
        const recordId = component.get("v.recordId");
        const eventRecordId = event.getParam('recordId');

        //Record if from chatEnded event is 15 chars
        let thisChatEnded = recordId.substring(0, 15).localeCompare(eventRecordId.substring(0, 15)) === 0 ? true : false;
        if (thisChatEnded === true) {
            chatToolkit.getChatLog({
                recordId: recordId
            })
                .then(result => {
                    let conversation = result.messages;
                    let filteredConversation = conversation.filter(function (message, index, arr) {
                        //Filtering out all messages of type supervisor as these are "whispers" and should not be added to the journal
                        return message.type !== 'Supervisor';
                    });

                    helper.callStoreConversation(component, filteredConversation);
                })
                .catch(error => {
                    //Errors require manual handling.
                });
        }
    }
})
