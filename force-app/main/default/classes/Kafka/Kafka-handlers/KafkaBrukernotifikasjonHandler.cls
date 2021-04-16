public without sharing class KafkaBrukernotifikasjonHandler implements IKafkaMessageConsumer {
    private LoggerUtility logger = new LoggerUtility();
    private Map<String, UserNotification__c> userNotificationMap;

    private Map<String, List<KafkaMessage__c>> messageMap;
    private Map<Id, KafkaBrukernotifikasjon> brukernotifikasjonMap;
    private Map<Id, KafkaBrukernotifikasjonDone> brukernotifikasjonDoneMap;

    private Map<String, String> actorMap;
    private Map<String, String> commonCodeMap;

    private static final String OPPGAVE_TOPIC = 'aapen-brukernotifikasjon-nyOppgave-v1';
    private static final String BESKJED_TOPIC = 'aapen-brukernotifikasjon-nyBeskjed-v1';
    private static final String DONE_TOPIC = 'aapen-brukernotifikasjon-nyDone-v1';
    private static final String STATUS_OPPDATERING_TOPIC = 'aapen-brukernotifikasjon-nyStatusoppdatering-v1';

    public void processMessages(List<KafkaMessage__c> messages) {
        for (KafkaMessage__c message : messages) {
            try {
                if (DONE_TOPIC == message.CRM_Topic__c) {
                    convertToKafkaBrukernotifikasjonDone(message);
                } else {
                    convertToKafkaBrukernotifikasjon(message);
                }
            } catch (Exception ex) {
                setMessageError(ex, message);
            }
        }

        initAccountMap();
        initCommonCodeMap();

        for (KafkaMessage__c message : messages) {
            if (
                KafkaMessageService.STATUS_PENDING == message.CRM_Status__c &&
                brukernotifikasjonMap.containsKey(message.Id)
            ) {
                try {
                    if (DONE_TOPIC == message.CRM_Topic__c) {
                        processDoneNotification(brukernotifikasjonDoneMap.get(message.Id));
                        messageMap.get(brukernotifikasjonDoneMap.get(message.Id).key.key)
                            .add(message);
                    } else {
                        processNotification(brukernotifikasjonMap.get(message.Id));
                        messageMap.get(brukernotifikasjonMap.get(message.Id).key.key).add(message);
                    }
                    message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                } catch (Exception ex) {
                    setMessageError(ex, message);
                }
            }
        }

        doUpsert(userNotificationMap.values());
        logger.publish();
    }

    private void initCommonCodeMap() {
        commonCodeMap = new Map<String, String>();
        for (Common_Code__c comCode : [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c IN ('Tema')
        ]) {
            commonCodeMap.put(comCode.CRM_Code__c, comCode.Id);
        }
    }

    private void initAccountMap() {
        actorMap = new Map<String, String>();
        for (Person__c person : [
            SELECT Id, CRM_Account__c, Name
            FROM Person__c
            WHERE INT_IsHasTombstone__c = FALSE AND Name IN :this.actorMap.keySet()
        ]) {
            this.actorMap.put(person.Name, person.CRM_Account__c);
        }
    }

    private void convertToKafkaBrukernotifikasjonDone(KafkaMessage__c message) {
        String decodedKey = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Key__c).toString();
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();

        KafkaBrukernotifikasjonKey key = (KafkaBrukernotifikasjonKey) JSON.deserialize(
            decodedKey,
            KafkaBrukernotifikasjonKey.class
        );

        KafkaBrukernotifikasjonDone notification = (KafkaBrukernotifikasjonDone) JSON.deserialize(
            decodedValue,
            KafkaBrukernotifikasjonDone.class
        );
        actorMap.put(notification.fodselsnummer, '');
        brukernotifikasjonDoneMap.put(message.Id, notification);
    }

    private void convertToKafkaBrukernotifikasjon(KafkaMessage__c message) {
        String decodedKey = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Key__c).toString();
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();

        KafkaBrukernotifikasjonKey key = (KafkaBrukernotifikasjonKey) JSON.deserialize(
            decodedKey,
            KafkaBrukernotifikasjonKey.class
        );

        KafkaBrukernotifikasjon notification;
        notification = (KafkaBrukernotifikasjon) JSON.deserialize(
            decodedValue,
            KafkaBrukernotifikasjon.class
        );
        notification.key = key;
        notification.kafkaCreatedDate = message.CreatedDate;
        notification.kafkaKey = message.CRM_Key__c;
        if (BESKJED_TOPIC == message.CRM_Topic__c) {
            notification.type = 'BESKJED';
        } else if (OPPGAVE_TOPIC == message.CRM_Topic__c) {
            notification.type = 'OPPGAVE';
        } else if (STATUS_OPPDATERING_TOPIC == message.CRM_Topic__c) {
            notification.type = 'STATUS_OPPDATERING';
        }
        actorMap.put(notification.fodselsnummer, '');
        brukernotifikasjonMap.put(message.Id, notification);

        notification.key = key;
        notification.kafkaCreatedDate = message.CreatedDate;

        actorMap.put(notification.fodselsnummer, '');
        brukernotifikasjonMap.put(message.Id, notification);
    }

    private void processDoneNotification(KafkaBrukernotifikasjonDone notification) {
        String accountId = actorMap.get(notification.fodselsnummer);
        if (String.isBlank(accountId)) {
            throw new ProcessingErrorException('Cannot find account from fodselsnummer');
        }

        UserNotification__c userNotification = brukernotifikasjonMap.containsKey(
                notification.key.key
            )
            ? userNotificationMap.get(notification.key.key)
            : getNewUserNotification(notification.key);

        emptyDoneEventFieldValues(userNotification);
        userNotification.Done__c = true;
        userNotification.DoneEventTime__c = notification.tidspunktFormated;
    }

    private void processNotification(KafkaBrukernotifikasjon notification) {
        String accountId = actorMap.get(notification.fodselsnummer);
        if (String.isBlank(accountId)) {
            this.logger.error(
                'Error creating User Notification, actor not found. ' +
                '\n User Notification reference: ' +
                notification.kafkaKey,
                null,
                CRM_ApplicationDomain.domain.NKS
            );
            throw new ProcessingErrorException('Cannot find account from fodselsnummer');
        }

        UserNotification__c userNotification = brukernotifikasjonMap.containsKey(
                notification.key.key
            )
            ? userNotificationMap.get(notification.key.key)
            : getNewUserNotification(notification.key);

        emptyFieldValues(userNotification);
        userNotification.EventTime__c = notification.tidspunktFormated;
        userNotification.VisibleUntil__c = notification.synligFremTilFormated;
        userNotification.SocialSecurityNumber__c = notification.fodselsnummer;
        userNotification.GroupingId__c = notification.grupperingsId;
        userNotification.Description__c = notification.tekst;
        userNotification.Link__c = notification.link;
        userNotification.SecurityLevel__c = notification.sikkerhetsnivaa;
        userNotification.ExternalNotification__c = notification.eksternVarsling;
        userNotification.Type__c = notification.type;
        userNotification.GlobalStatus__c = notification.statusGlobal;
        userNotification.InternalStatus__c = notification.statusIntern;
        userNotification.CaseTheme__c = notification.sakstema;
        userNotification.CaseThemeId__c = commonCodeMap.get(notification.sakstema);
        userNotification.AccountId__c = accountId;
        userNotification.LastUpdatedFromKafka__c = notification.kafkaCreatedDate;
        userNotificationMap.put(userNotification.Key__c, userNotification);
    }

    private UserNotification__c getNewUserNotification(KafkaBrukernotifikasjonKey key) {
        return new UserNotification__c(
            EventId__c = key.eventId,
            SystemUser__c = key.systembruker,
            Key__c = key.key
        );
    }

    private void emptyFieldValues(UserNotification__c notification) {
        List<String> intFields = new List<String>{
            'CaseTheme__c',
            'Description__c',
            'EventTime__c',
            'ExternalNotification__c',
            'GlobalStatus__c',
            'GroupingId__c',
            'InternalStatus__c',
            'LastUpdatedFromKafka__c',
            'Link__c',
            'SecurityLevel__c',
            'SocialSecurityNumber__c',
            'Type__c',
            'VisibleUntil__c'
        };

        for (String intField : intFields) {
            notification.put(intField, null);
        }
    }

    private void emptyDoneEventFieldValues(UserNotification__c notification) {
        List<String> intFields = new List<String>{ 'Done__c', 'DoneEventTime__c' };

        for (String intField : intFields) {
            notification.put(intField, null);
        }
    }

    private void doUpsert(List<UserNotification__c> notificationsToUpsert) {
        Schema.SObjectField extRef = null;

        List<Database.UpsertResult> upsList = Database.upsert(notificationsToUpsert, extRef, false);
        verifyUpsertResults(upsList, notificationsToUpsert);
    }

    private void verifyUpsertResults(
        List<Database.UpsertResult> upsList,
        List<UserNotification__c> notificationsToUpsert
    ) {
        for (Integer index = 0; index < upsList.size(); index++) {
            if (upsList[index].isSuccess()) {
                //Successful upsert
            } else {
                //Sets an error on every kafka message with the unique key
                for (
                    KafkaMessage__c message : messageMap.get(notificationsToUpsert[index].key__c)
                ) {
                    setMessageError(upsList[index].getErrors(), message);
                }
            }
        }
    }

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
            errorMsg =
                err.getStatusCode() +
                ': ' +
                err.getMessage() +
                ' - ' +
                'FIELDS: ' +
                err.getFields();
        }
        setMessageError(errorMsg, message);
    }

    private void setMessageError(String errorMsg, KafkaMessage__c message) {
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters
        message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
    }

    public class ProcessingErrorException extends Exception {
    }
}
