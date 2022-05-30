@isTest
public class Test_RecurringPaymentBatchSchedular {

    @isTest static void testBatchSchedular(){
        String cronExpr = '0 0 11 18 11 ?';
        Test.startTest();
        String jobId = system.schedule('NABRP', cronExpr, new RecurringPaymentBatchSchedular());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(cronExpr, ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    }
}