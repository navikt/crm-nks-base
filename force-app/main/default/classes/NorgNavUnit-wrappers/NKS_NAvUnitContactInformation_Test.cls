@IsTest
private with sharing class NKS_NAvUnitContactInformation_Test {
    @IsTest
    static void aapningstiderFromJSON_Dag() {
        String jsonString = '{ "dag":"MANDAG", "dato":null, "fra":"08:00", "id":12345, "kommentar":null, "stengt":false, "til":"16:00"}';
        NKS_NAvUnitContactInformation.Aapningstider result;

        Test.startTest();
        result = (NKS_NAvUnitContactInformation.Aapningstider) JSON.deserialize(
            jsonString,
            NKS_NAvUnitContactInformation.Aapningstider.class
        );
        Test.stopTest();

        System.assertEquals('MANDAG', result.dag, 'Expected dag to be set');
        System.assertEquals(null, result.dato, 'Expected dato to be NULL');
        System.assertEquals('08:00', result.fra, 'Expected fra to be set');
        System.assertEquals('16:00', result.til, 'Expected til to be set');
        System.assertEquals(
            null,
            result.kommentar,
            'Expected kommentar to be NULL'
        );
        System.assertEquals(false, result.stengt, 'Expected stengt to be set');
        System.assertEquals(12345, result.id, 'Expected id to be set');
    }

    @IsTest
    static void aapningstiderFromJSON_Dato() {
        String jsonString = '{ "dag":null, "dato":"2017-09-12", "fra":"08:00", "id":12345, "kommentar":"TEST", "stengt":true, "til":"16:00"}';
        NKS_NAvUnitContactInformation.Aapningstider result;

        Test.startTest();
        result = (NKS_NAvUnitContactInformation.Aapningstider) JSON.deserialize(
            jsonString,
            NKS_NAvUnitContactInformation.Aapningstider.class
        );
        Test.stopTest();

        System.assertEquals(null, result.dag, 'Expected dag to be NULL');
        System.assertEquals(
            Date.newInstance(2017, 9, 12),
            result.dato,
            'Expected dato to be 2017-09-12'
        );
        System.assertEquals('08:00', result.fra, 'Expected fra to be set');
        System.assertEquals('16:00', result.til, 'Expected til to be set');
        System.assertEquals(
            'TEST',
            result.kommentar,
            'Expected kommentar to be set'
        );
        System.assertEquals(true, result.stengt, 'Expected stengt to be set');
        System.assertEquals(12345, result.id, 'Expected id to be set');
    }

    @IsTest
    static void adresse_TestConcatOnEmpty() {
        Test.startTest();
        NKS_NAvUnitContactInformation.Adresse adresse = new NKS_NAvUnitContactInformation.Adresse();
        System.assertEquals(
            '',
            adresse.concatenatedAddress,
            'Expected empty string'
        );
        Test.stopTest();
    }

    @IsTest
    static void adresse_TestConcatOnAddressOnly() {
        Test.startTest();
        NKS_NAvUnitContactInformation.Adresse adresse = new NKS_NAvUnitContactInformation.Adresse(
            'TEST',
            '3',
            'A',
            null,
            null
        );
        System.assertEquals(
            'TEST 3 A',
            adresse.concatenatedAddress,
            'Expected string without comma or postal code and city'
        );
        Test.stopTest();
    }

    @IsTest
    static void adresse_TestConcatOnCityOnly() {
        Test.startTest();
        NKS_NAvUnitContactInformation.Adresse adresse = new NKS_NAvUnitContactInformation.Adresse(
            null,
            null,
            null,
            'TEST',
            '0123'
        );
        System.assertEquals(
            '0123 TEST',
            adresse.concatenatedAddress,
            'Expected string without comma or street address'
        );
        Test.stopTest();
    }

    @IsTest
    static void adresse_TestConcatOnFullAddress() {
        Test.startTest();
        NKS_NAvUnitContactInformation.Adresse adresse = new NKS_NAvUnitContactInformation.Adresse(
            'TEST',
            '3',
            'A',
            'TEST',
            '0123'
        );
        System.assertEquals(
            'TEST 3 A, 0123 TEST',
            adresse.concatenatedAddress,
            'Expected string without comma or street address'
        );
        Test.stopTest();
    }
}
