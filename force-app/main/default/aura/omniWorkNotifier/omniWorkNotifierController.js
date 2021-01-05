({
    doInit: function (component, event, helper) {
        component.set('v.iconUrl', $A.get('$Resource.logo'));
        helper.verifyNotificationPermission(component);
    },

    onWorkAssigned: function (component, event, helper) {
        const notificationsEnabled = component.get('v.notificationsEnabled');

        if (notificationsEnabled) {
            let notification = new Notification("Ny innkommende chat!", {
                body: "Ønsker du å svare på den?",
                requireInteraction: true,
                icon: component.get('v.iconUrl'),
                silent: false,
            });
            notification.onclick = function (event) {
                //Try passing custom event back to the parent to accept work item
                try {
                    event.preventDefault(); // prevent the browser from focusing the Notification's tab
                    window.focus();
                    notification.close();
                }
                catch (ex) {

                }
            };

            window.notification = notification;
        }
    }
})