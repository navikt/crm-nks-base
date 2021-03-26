public class KafkaOppgaveHandler implements IKafkaMessageConsumer {
    private LoggerUtility logger = new LoggerUtility();
    private Map<String, String> actorAccMap = new Map<String, String>();
    private Map<String, List<KafkaMessage__c>> messageMap = new Map<String, List<KafkaMessage__c>>(); //Maps CRM_Key__c to a list of KafkaMessages for that key
    private Map<String, NavUnit__c> navUnitMap;
    private Map<String, String> commonCodeMap;

    //Default constructor
    public KafkaOppgaveHandler() {
        initCommonCodeMap();
        initNavUnitMap();
    }

    /**
     * @description: Initializes a map for all relevant records from common code
     * @author Stian Ruud Schikora | 03-26-2021
     **/
    private void initCommonCodeMap() {
        commonCodeMap = new Map<String, String>();
        for (Common_Code__c comCode : [
            SELECT Id, CRM_Code__c, CRM_Code_Set__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c IN ('Tema', 'Behandlingstema', 'Oppgavetyper')
        ]) {
            commonCodeMap.put(comCode.CRM_Code_Set__c + comCode.CRM_Code__c, comCode.Id);
        }
    }

    /**
     * @description: Initializes a map of NAV units
     * @author Stian Ruud Schikora | 03-26-2021
     **/
    private void initNavUnitMap() {
        navUnitMap = new Map<String, NavUnit__c>();
        for (NavUnit__c navUnit : [SELECT Id, INT_UnitNumber__c, Name FROM NavUnit__c]) {
            navUnitMap.put(navUnit.INT_UnitNumber__c, navUnit);
        }
    }

    public void processMessages(List<KafkaMessage__c> messages) {
        List<NavTask__c> tasksToUpsert = new List<NavTask__c>();
        Map<Decimal, NavTask__c> existingTaskMap = new Map<Decimal, NavTask__c>();
        Map<Decimal, List<KafkaOppgave>> kafkaTaskMap = convertToKafkaTasks(messages);
        List<KafkaOppgave> tasksToConvert = new List<KafkaOppgave>();

        for (NavTask__c navTask : [
            SELECT
                Id,
                INT_External_Reference__c,
                CRM_Comments__c,
                NKS_Task_Version__c,
                NKS_Comment_History__c
            FROM NavTask__c
            WHERE INT_External_Reference__c IN :kafkaTaskMap.keySet()
        ]) {
            existingTaskMap.put(navTask.INT_External_Reference__c, navTask);
        }

        for (Decimal taskRef : kafkaTaskMap.keySet()) {
            String newestComment;
            String commentHistory = '';
            Integer existingTaskVersion = 0;
            if (existingTaskMap.containsKey(taskRef)) {
                newestComment = existingTaskMap.get(taskRef).CRM_Comments__c;
                commentHistory = existingTaskMap.get(taskRef).NKS_Comment_History__c;
                existingTaskVersion = Integer.valueOf(
                    existingTaskMap.get(taskRef).NKS_Task_Version__c
                );
            }
            KafkaOppgave taskToConvert;
            for (KafkaOppgave kafkaOppgave : kafkaTaskMap.get(taskRef)) {
                //As list is sorted, the taskToConvert will always be set to the newest version after finishing the loop
                taskToConvert = kafkaOppgave;
                if (
                    String.isNotBlank(kafkaOppgave.beskrivelse) &&
                    (kafkaOppgave.beskrivelse != newestComment ||
                    taskToConvert.versjon == existingTaskVersion)
                ) {
                    newestComment = kafkaOppgave.beskrivelse;
                    //Newest comment first
                    commentHistory = String.isNotBlank(commentHistory)
                        ? newestComment + '\n\n' + commentHistory
                        : newestComment;
                }
            }
            taskToConvert.commentHistory = commentHistory;
            tasksToConvert.add(taskToConvert);
        }

        tasksToUpsert = convertToNavTasks(tasksToConvert);

        doUpsert(tasksToUpsert);
        logger.publish();
    }

    private void doUpsert(List<NavTask__c> tasksToUpsert) {
        Schema.SObjectField extRef = NavTask__c.Fields.INT_External_Reference__c;

        List<Database.UpsertResult> upsList = Database.upsert(tasksToUpsert, extRef, false);
        verifyUpsertResults(upsList, tasksToUpsert);
    }

    private void initAccountMap() {
        for (Person__c person : [
            SELECT Id, CRM_Account__c, INT_ActorId__c
            FROM Person__c
            WHERE INT_ActorId__c IN :this.actorAccMap.keySet()
        ]) {
            this.actorAccMap.put(person.INT_ActorId__c, person.CRM_Account__c);
        }
    }

    /**
     * @description: Deserialize the Kafka message value into the wrapper object
     * @author Stian Ruud Schikora | 01-15-2021
     * @param message
     * @return KafkaOppgave
     **/
    private KafkaOppgave convertToKafkaTask(KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        return (KafkaOppgave) JSON.deserialize(decodedValue, KafkaOppgave.class);
    }

    /**
     * @description: Generates a map of KafkaOppgave wrappers based on the kafka messages
     * @author Stian Ruud Schikora | 01-15-2021
     * @param messages
     * @return Map<Decimal, KafkaOppgave>
     **/
    private Map<Decimal, List<KafkaOppgave>> convertToKafkaTasks(List<KafkaMessage__c> messages) {
        Map<Decimal, List<KafkaOppgave>> returnMap = new Map<Decimal, List<KafkaOppgave>>();

        for (KafkaMessage__c message : messages) {
            try {
                Decimal messageKey = Decimal.valueOf(message.CRM_Key__c);
                KafkaOppgave kafkaOppgave = convertToKafkaTask(message);
                if (kafkaOppgave != null) {
                    if (kafkaOppgave.getActorId() != null)
                        actorAccMap.put(kafkaOppgave.getActorId(), ''); //Adding the actor ids to map for initialization aftert successful conversions
                    //If the map already contains the unique task reference, check which of the messages containcs the latest version number
                    if (returnMap.containsKey(messageKey)) {
                        List<KafkaOppgave> mapList = returnMap.get(messageKey);
                        mapList.add(kafkaOppgave);
                        returnMap.put(messageKey, mapList);
                    } else {
                        returnMap.put(messageKey, new List<kafkaOppgave>{ kafkaOppgave });
                    }
                    //Put in message map for later status update depending on DML
                    if (this.messageMap.containsKey(message.CRM_Key__c)) {
                        List<KafkaMessage__c> mappedMsgs = this.messageMap.get(message.CRM_Key__c);
                        mappedMsgs.add(message);
                        this.messageMap.put(message.CRM_Key__c, mappedMsgs);
                    } else {
                        this.messageMap.put(
                            message.CRM_Key__c,
                            new List<KafkaMessage__c>{ message }
                        );
                    }
                    message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                } else {
                    message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                }
            } catch (Exception ex) {
                message.CRM_ErrorMessage__c =
                    ex.getTypeName() +
                    ': ' +
                    ex.getMessage() +
                    ' (' +
                    ex.getLineNumber() +
                    ')';
                message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }
        initAccountMap();
        //Sorting the lists. First item is the oldest version
        for (List<KafkaOppgave> oppgaveList : returnMap.values()) {
            oppgaveList.sort();
        }
        return returnMap;
    }

    /**
     * @description: Performs converstion from KafkaOppgave => NavTask__c
     * @author Stian Ruud Schikora | 02-26-2021
     * @param kafkaOppgaver
     * @return List<NavTask__c>
     **/
    private List<NavTask__c> convertToNavTasks(List<KafkaOppgave> kafkaOppgaver) {
        List<NavTask__c> returnList = new List<NavTask__c>();
        NavTask__c convertedTask;

        for (KafkaOppgave kafkaOppgave : kafkaOppgaver) {
            try {
                convertedTask = convertToNavTask(kafkaOppgave);
            } catch (Exception ex) {
                //If conversion throws exception, add error to related kafka messages
                for (
                    KafkaMessage__c message : getRelatedMessages(String.valueOf(kafkaOppgave.id))
                ) {
                    String errorMsg =
                        'Exception: ' +
                        ex.getTypeName() +
                        ' - ' +
                        ex.getMessage() +
                        ' - ' +
                        ex.getStackTraceString();
                    message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters

                    setMessageError(errorMsg, message);
                }
            }
            if (convertedTask != null)
                returnList.add(convertedTask);
        }

        return returnList;
    }

    /**
     * @description: Maps fields from KafkaOppgave wrapper class to NavTask__c fields
     * @author Stian Ruud Schikora | 01-15-2021
     * @param kafkaOppgave
     * @return NavTask__c
     **/
    private NavTask__c convertToNavTask(KafkaOppgave kafkaOppgave) {
        NavTask__c navTask = new NavTask__c();
        Boolean actorExists =
            this.actorAccMap.containsKey(kafkaOppgave.getActorId()) &&
            String.isNotBlank(this.actorAccMap.get(kafkaOppgave.getActorId()));
        Boolean mappedTheme = this.commonCodeMap.containsKey('Tema' + kafkaOppgave.tema);
        if (actorExists && mappedTheme) {
            navTask.CRM_Account__c = this.actorAccMap.get(kafkaOppgave.getActorId());
            navTask.INT_External_Reference__c = kafkaOppgave.id;
            navTask.NKS_Task_Version__c = kafkaOppgave.versjon;
            navTask.CRM_NavUnit__c = navUnitMap.containsKey(kafkaOppgave.tildeltEnhetsnr)
                ? navUnitMap.get(kafkaOppgave.tildeltEnhetsnr).Id
                : null;
            navTask.Name = this.navUnitMap.containsKey(kafkaOppgave.tildeltEnhetsnr)
                ? 'Oppgave til ' + this.navUnitMap.get(kafkaOppgave.tildeltEnhetsnr).Name
                : 'Oppgave';
            navTask.NKS_Assignee__c = kafkaOppgave.tilordnetRessurs;
            navTask.CRM_Comments__c = kafkaOppgave.beskrivelse;
            navTask.NKS_TaskType__c = this.commonCodeMap.containsKey(
                    'Oppgavetyper' + kafkaOppgave.oppgavetype
                )
                ? this.commonCodeMap.get('Oppgavetyper' + kafkaOppgave.oppgavetype)
                : null;
            navTask.NKS_Theme__c = this.commonCodeMap.get('Tema' + kafkaOppgave.tema);
            navTask.NKS_Subtheme__c = this.commonCodeMap.containsKey(
                    'Behandlingstema' + kafkaOppgave.tema
                )
                ? this.commonCodeMap.get('Behandlingstema' + kafkaOppgave.tema)
                : null;
            navTask.CRM_DueDate__c = String.isNotBlank(kafkaOppgave.fristFerdigstillelse)
                ? Date.valueOf(kafkaOppgave.fristFerdigstillelse)
                : null;
            navTask.CRM_Priority__c = kafkaOppgave.prioritet;
            navTask.NKS_Status__c = kafkaOppgave.status;
            navTask.NKS_Date_Registered__c = String.isNotBlank(kafkaOppgave.opprettetTidspunkt)
                ? Date.valueOf(kafkaOppgave.opprettetTidspunkt)
                : null;
            navTask.NKS_Comment_History__c = kafkaOppgave.commentHistory;
            navTask.CRM_NoPersonInformation__c = true; //Need to be default set because of validation rule
        } else {
            //If actor is not existing in Salesforce, create an application log
            if (!actorExists) {
                this.logger.error(
                    'Error creating NAV task, actor not found: ' +
                    kafkaOppgave.getActorId() +
                    '\n Task reference: ' +
                    kafkaOppgave.id,
                    null,
                    CRM_ApplicationDomain.domain.NKS
                );
            }

            String errorMessage = !actorExists
                ? 'Actor not found: ' + kafkaOppgave.getActorId()
                : '';
            errorMessage += !mappedTheme ? ' - Theme not mapped: ' + kafkaOppgave.tema : '';
            for (KafkaMessage__c message : getRelatedMessages(String.valueOf(kafkaOppgave.id))) {
                setMessageError(errorMessage, message);
            }
            return null;
        }
        return navTask;
    }

    //##########################//
    //      ERROR HANDLING      //
    //##########################//

    /**
     * @description: Verifies the upsert results and updates the KafkaMessages with
     * Correct status and error messages.
     * @author Stian Ruud Schikora | 02-26-2021
     * @param upsList
     * @param taskList
     **/
    private void verifyUpsertResults(
        List<Database.UpsertResult> upsList,
        List<NavTask__c> taskList
    ) {
        for (Integer index = 0; index < upsList.size(); index++) {
            if (upsList[index].isSuccess()) {
                //Successful upsert
            } else {
                //Sets an error on every kafka message with the unique key
                for (
                    KafkaMessage__c message : getRelatedMessages(
                        String.valueOf(taskList[index].INT_External_Reference__c)
                    )
                ) {
                    setMessageError(upsList[index].getErrors(), message);
                }
            }
        }
    }

    /**
     * @description: Sets the message error
     * @author Stian Ruud Schikora | 02-26-2021
     * @param errList [List<Database.Error>]
     * @param message
     **/
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
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters
        message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
    }

    /**
     * @description: Sets the message error
     * @author Stian Ruud Schikora | 02-26-2021
     * @param String : errorMessage
     * @param message
     **/
    private void setMessageError(String errorMessage, KafkaMessage__c message) {
        message.CRM_ErrorMessage__c = errorMessage;
        message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
    }

    /**
     * @description: Returns a list of kafka messages with a matching CRM_Key__c
     * and the INT_EXternal_Reference__c field
     * @author Stian Ruud Schikora | 02-26-2021
     * @param String : reference
     * @return List<KafkaMessage__c>
     **/
    private List<KafkaMessage__c> getRelatedMessages(String reference) {
        return this.messageMap.get(reference);
    }
}
