/**
 * This handler will try to convert a brukernotifikasjon events to UserNotification__c records. Virtual class that is meant to be overidden per Brukernotifikasjon topic.
 */
public without sharing virtual class KafkaBrukernotifikasjonHandler implements IKafkaMessageConsumer {
    //Custom exception
    public class KafkaBrukernotifikasjonException extends Exception {
    }

    private LoggerUtility logger;
    private Set<String> ssnSet;
    private Map<String, UserNotification__c> userNotificationMap;
    private Map<String, KafkaMessage__c> messageMap;
    protected Map<String, String> commonCodeMap;
    private Map<String, String> actorMap;

    public void processMessages(List<KafkaMessage__c> messages) {
        logger = new LoggerUtility();
        ssnSet = new Set<String>();
        userNotificationMap = new Map<String, UserNotification__c>();
        messageMap = new Map<String, KafkaMessage__c>();

        Savepoint sp = Database.setSavepoint();

        try {
            commonCodeMap = getCommonCodeMap();

            //Processs each message and create UserNotification__c records
            for (KafkaMessage__c message : messages) {
                try {
                    processMessage(message);
                } catch (Exception ex) {
                    setMessageError(ex, message);
                }
            }

            //Get all the accounts ased of social security numbers
            actorMap = getAccountMap(ssnSet);

            //Map all the UserNotification__c records to accounts
            for (String key : userNotificationMap.keySet()) {
                try {
                    mapNotificationToAccount(userNotificationMap.get(key));
                } catch (Exception ex) {
                    //Set message to error and remove from message map, remove notification from notification map
                    this.logger.warning(
                        'Error creating User Notification, actor not found. ' +
                        '\n Kafka key reference: ' +
                        messageMap.get(key).CRM_Key__c,
                        null,
                        CRM_ApplicationDomain.domain.NKS
                    );

                    setMessageError(ex, messageMap.get(key));
                    messageMap.remove(key);
                    userNotificationMap.remove(key);
                }
            }

            doUpsert(userNotificationMap.values()); //Save and handle save exceptions
        } catch (Exception ex) {
            //Rollback and mark all Kafka Messages as failed.
            Database.rollback(sp);
            for (KafkaMessage__c message : messages) {
                setMessageError(ex, message);
            }
        }

        logger.publishSynch();
    }

    private void processMessage(KafkaMessage__c message) {
        //Get user UserNotification__c record set with values from the Kafka Key
        UserNotification__c notification = getNewUserNotification(
            (KafkaBrukernotifikasjonKey) JSON.deserialize(
                KafkaMessageUtils.base64ULSafeDecode(message.CRM_Key__C).toString(),
                KafkaBrukernotifikasjonKey.class
            )
        );

        //Call on virtual message to populate the notification
        buildNotification(KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString(), notification);

        notification.INT_LastUpdatedFromKafka__c = message.CreatedDate;
        message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;

        ssnSet.add(notification.INT_SocialSecurityNumber__c);

        userNotificationMap.put(notification.INT_Key__c, notification);
        messageMap.put(notification.INT_Key__c, message);
    }

    /**
     * Method to be ovveridden with the desired mapping from the kafka value to the UserNotification__c record
     */
    protected virtual void buildNotification(String decodedValue, UserNotification__c notification) {
        System.debug('buildNotification');
    }

    /**
     * Map the notification to an account. Log and throw exception if we don't find an account.
     */
    private void mapNotificationToAccount(UserNotification__c notification) {
        String accountId = actorMap.get(notification.INT_SocialSecurityNumber__c);
        if (String.isBlank(accountId)) {
            throw new KafkaBrukernotifikasjonException('Cannot find account from fodselsnummer');
        }

        notification.CRM_Account__c = accountId;
    }

    private void doUpsert(List<UserNotification__c> notificationsToUpsert) {
        Schema.SObjectField extRef = UserNotification__c.Fields.INT_Key__c;

        List<Database.UpsertResult> upsList = Database.upsert(notificationsToUpsert, extRef, false);
        verifyUpsertResults(upsList, notificationsToUpsert);
    }

    private void verifyUpsertResults(
        List<Database.UpsertResult> upsList,
        List<UserNotification__c> notificationsToUpsert
    ) {
        for (Integer index = 0; index < upsList.size(); index++) {
            if (upsList[index].isSuccess()) {
                // Successful upsert
            } else {
                setMessageError(upsList[index].getErrors(), messageMap.get(notificationsToUpsert[index].INT_key__c));
            }
        }
    }

    private Map<String, String> getCommonCodeMap() {
        Map<String, String> commonCodeMap = new Map<String, String>();
        for (Common_Code__c comCode : [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c IN ('Tema')
        ]) {
            commonCodeMap.put(comCode.CRM_Code__c, comCode.Id);
        }

        return commonCodeMap;
    }

    private Map<String, String> getAccountMap(Set<String> ssnSet) {
        Map<String, String> actorMap = new Map<String, String>();
        for (Person__c person : [
            SELECT Id, CRM_Account__c, Name
            FROM Person__c
            WHERE INT_IsHasTombstone__c = FALSE AND Name IN :ssnSet
        ]) {
            actorMap.put(person.Name, person.CRM_Account__c);
        }

        return actorMap;
    }

    //NOTIFICATION HELPERS
    /**
     * Create base notification from the kafka key values
     */
    private UserNotification__c getNewUserNotification(KafkaBrukernotifikasjonKey key) {
        UserNotification__c notification = new UserNotification__c();
        notification.INT_EventId__c = key.eventId;
        notification.INT_SystemUser__c = key.systembruker;
        notification.INT_Key__c = key.key;
        return notification;
    }

    protected Boolean cleanBoolean(Boolean value) {
        return value == null ? false : value;
    }

    /**
     * Reset all fields on a record
     */
    protected void emptyFieldValues(UserNotification__c notification) {
        List<String> intFields = new List<String>{
            'INT_CaseTheme__c',
            'INT_Description__c',
            'INT_EventTime__c',
            'INT_ExternalNotification__c',
            'INT_GlobalStatus__c',
            'INT_GroupingId__c',
            'INT_InternalStatus__c',
            'INT_LastUpdatedFromKafka__c',
            'INT_Link__c',
            'INT_SecurityLevel__c',
            'INT_SocialSecurityNumber__c',
            'INT_Type__c',
            'INT_VisibleUntil__c',
            'CRM_CaseTheme__c',
            'CRM_Account__c'
        };

        for (String intField : intFields) {
            notification.put(intField, null);
        }
    }

    // SET ERROR MESSAGE HELPERS
    private void setMessageError(Exception exceptionError, KafkaMessage__c message) {
        String errorMsg =
            exceptionError.getTypeName() +
            ': ' +
            exceptionError.getMessage() +
            ' (' +
            exceptionError.getLineNumber() +
            ')';

        setMessageError(errorMsg, message);
    }

    private void setMessageError(List<Database.Error> errList, KafkaMessage__c message) {
        String errorMsg = '';
        for (Database.Error err : errList) {
            errorMsg = err.getStatusCode() + ': ' + err.getMessage() + ' - ' + 'FIELDS: ' + err.getFields();
        }
        setMessageError(errorMsg, message);
    }

    private void setMessageError(String errorMsg, KafkaMessage__c message) {
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters
        message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
    }
}
