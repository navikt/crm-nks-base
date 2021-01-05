({
    verifyNotificationPermission: function (component) {
        // first check whether browser support notifications
        if (!window.Notification) {
            alert('Notification API not supported for this browser');
        } else {
            //Permission is already granted
            if (Notification.permission === 'granted') {
                component.set('v.notificationsEnabled', true);
            } else {
                if (Notification.permission === 'default') {
                    Notification.requestPermission().then(
                        (permissionRequestResult) => {
                            if (permissionRequestResult === 'granted') {
                                component.set('v.notificationsEnabled', true);
                            } else {
                                console.log('Notification request was denied by user');
                            }
                        }
                    ).catch(
                        (error) => {
                            console.log('Failed to request notification permission');
                        }
                    );
                } else {
                    //Permission has already been denies
                    console.log('The user has denied notificatons');
                }
            }
        }
    }
})