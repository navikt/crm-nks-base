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

        chatToolkit.getChatLog({
            recordId: recordId
        })
            .then(result => {
                let conversation = result.messages;
                console.log("CONVERSATION: " + JSON.stringify(conversation));

                helper.callStoreConversation(component, conversation);
            })
            .catch(error => {
                //How should an error be handled?
            });
    }
})
