public with sharing class NKS_HenvendelseUtil {
    private static Map<String, Common_Code__c> commonCodeMap;

    public static Map<String, NKS_HenvendelseType> henvendelseEnumTypeMap {
        get {
            Map<String, NKS_HenvendelseType> enumMap = new Map<String, NKS_HenvendelseType>();
            for (NKS_HenvendelseType henvendelsesType : NKS_HenvendelseType.values()) {
                enumMap.put(henvendelsesType.name(), henvendelsesType);
            }

            return enumMap;
        }
    }

    public static String getTemaLabel(String tema) {
        if (commonCodeMap == null) {
            loadCommonCodeMap();
        }

        Common_Code__c commonCode = commonCodeMap.get(tema);

        return commonCode == null ? 'Ukjent tema: ' + tema : commonCode.Name;
    }

    public static Common_Code__c getTemagruppe(String tema) {
        if (commonCodeMap == null) {
            loadCommonCodeMap();
        }

        return commonCodeMap.get(tema);
    }

    private static void loadCommonCodeMap() {
        commonCodeMap = new Map<String, Common_Code__c>();
        for (Common_Code__c commonCode : [
            SELECT Id, Name, CRM_Code__c
            FROM Common_Code__c
            WHERE CRM_Active__c = TRUE
        ]) {
            commonCodeMap.put(commonCode.CRM_Code__c, commonCode);
        }
    }

    public static NKS_HenvendelseType getHenvendelseEnumFromString(String typeName) {
        return henvendelseEnumTypeMap.get(typeName);
    }

    public static Boolean isMessageFromUser(String messageType) {
        return hasEnum(
            new List<NKS_HenvendelseType>{
                NKS_HenvendelseType.SPORSMAL_SKRIFTLIG,
                NKS_HenvendelseType.SVAR_SBL_INNGAAENDE
            },
            messageType
        );
    }

    public static Boolean isMessageFromNav(String messageType) {
        return hasEnum(
            new List<NKS_HenvendelseType>{
                NKS_HenvendelseType.SVAR_SKRIFTLIG,
                NKS_HenvendelseType.SVAR_OPPMOTE,
                NKS_HenvendelseType.SVAR_TELEFON,
                NKS_HenvendelseType.SAMTALEREFERAT_TELEFON,
                NKS_HenvendelseType.SAMTALEREFERAT_OPPMOTE,
                NKS_HenvendelseType.SPORSMAL_MODIA_UTGAAENDE,
                NKS_HenvendelseType.DOKUMENT_VARSEL,
                NKS_HenvendelseType.OPPGAVE_VARSEL,
                NKS_HenvendelseType.DELVIS_SVAR_SKRIFTLIG,
                NKS_HenvendelseType.INFOMELDING_MODIA_UTGAAENDE
            },
            messageType
        );
    }

    public static Boolean isNotificationMessage(String messageType) {
        return hasEnum(
            new List<NKS_HenvendelseType>{ NKS_HenvendelseType.OPPGAVE_VARSEL, NKS_HenvendelseType.DOKUMENT_VARSEL },
            messageType
        );
    }

    public static Boolean isQuestionMessage(String messageType) {
        return hasEnum(
            new List<NKS_HenvendelseType>{
                NKS_HenvendelseType.SPORSMAL_MODIA_UTGAAENDE,
                NKS_HenvendelseType.SPORSMAL_SKRIFTLIG
            },
            messageType
        );
    }

    public static Boolean isConversationNotes(String messageType) {
        return hasEnum(
            new List<NKS_HenvendelseType>{
                NKS_HenvendelseType.SAMTALEREFERAT_OPPMOTE,
                NKS_HenvendelseType.SAMTALEREFERAT_TELEFON
            },
            messageType
        );
    }

    public static Boolean isPartialyAnswared(String messageType) {
        return hasEnum(new List<NKS_HenvendelseType>{ NKS_HenvendelseType.DELVIS_SVAR_SKRIFTLIG }, messageType);
    }

    public static String getMessageTitle(NKS_Henvendelse message) {
        if (
            hasEnum(
                new List<NKS_HenvendelseType>{
                    NKS_HenvendelseType.DOKUMENT_VARSEL,
                    NKS_HenvendelseType.OPPGAVE_VARSEL
                },
                message.henvendelseType
            )
        ) {
            return getMessageTypeText(getHenvendelseEnumFromString(message.henvendelseType));
        }

        if (String.isBlank(message.gjeldendeTemagruppe)) {
            return getMessageTypeText(getHenvendelseEnumFromString(message.henvendelseType));
        }

        return getMessageTypeText(getHenvendelseEnumFromString(message.henvendelseType)) +
            ' - ' +
            getTemagruppe(message.gjeldendeTemagruppe).Name;
    }

    public static DateTime stringToDateTime(String dateString) {
        if (String.isBlank(dateString)) {
            return null;
        }

        try {
            return Datetime.parse(dateString);
        } catch (Exception e) {
        }

        return null;
    }

    private static Boolean hasEnum(List<NKS_HenvendelseType> toCompareTo, String messageType) {
        return hasEnum(toCompareTo, getHenvendelseEnumFromString(messageType));
    }

    private static Boolean hasEnum(List<NKS_HenvendelseType> toCompareTo, NKS_HenvendelseType messageType) {
        Set<NKS_HenvendelseType> toCompareToSet = new Set<NKS_HenvendelseType>(toCompareTo);

        return toCompareToSet.contains(messageType);
    }

    private static String getMessageTypeText(NKS_HenvendelseType henvendelseType) {
        switch on henvendelseType {
            when SVAR_TELEFON {
                return 'Svar telefon';
            }
            when SPORSMAL_SKRIFTLIG {
                return 'Spørsmål fra bruker';
            }
            when SAMTALEREFERAT_OPPMOTE {
                return 'Samtalereferat oppmøte';
            }
            when DELVIS_SVAR_SKRIFTLIG {
                return 'Delsvar';
            }
            when DOKUMENT_VARSEL {
                return 'Dokument-varsel';
            }
            when OPPGAVE_VARSEL {
                return 'Oppgave-varsel';
            }
            when SAMTALEREFERAT_TELEFON {
                return 'Samtalereferat telefon';
            }
            when SPORSMAL_MODIA_UTGAAENDE {
                return 'Spørsmål fra NAV';
            }
            when SVAR_OPPMOTE {
                return 'Svar oppmøte';
            }
            when SVAR_SBL_INNGAAENDE {
                return 'Svar fra bruker';
            }
            when SVAR_SKRIFTLIG {
                return 'Svar skriftlig';
            }
            when INFOMELDING_MODIA_UTGAAENDE {
                return 'Infomelding';
            }
            when else {
                return 'Ukjent meldingstype: ' + henvendelseType.name();
            }
        }
    }
}
