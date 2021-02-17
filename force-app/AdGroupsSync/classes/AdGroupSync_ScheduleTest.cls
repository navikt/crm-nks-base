@IsTest 
private class AdGroupSync_ScheduleTest {
    
    @IsTest
	private static void testScheduleExecute() {
		Test.startTest();
		AdGroupSync_Schedule scheduleClass = new AdGroupSync_Schedule();
		String chron = '0 0 23 * * ?';
		System.schedule( 'Create logs', chron, scheduleClass );
		Test.stopTest();
		System.assert([SELECT count() FROM CronTrigger]>0, 'Expect job to be scheduled' );
		System.assertEquals(1,[SELECT count() FROM AsyncRequest__c], 'Expect one async request to be created');
	}
}
