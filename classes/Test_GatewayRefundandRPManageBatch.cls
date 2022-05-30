@isTest
public with sharing class Test_GatewayRefundandRPManageBatch {

    @isTest static void testRefundGatewayRefundandRPManageBatch(){
        Date todaysdate = Date.today();
        Recurring_Payment__c RPdata = TestDataFactory.createRecurringPayment(45.00, todaysdate-1, todaysdate, '0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=', 'Weekly', '0031y00000HnkCJAAZ', '', 'Payway');

        test.startTest();
        GatewayRefundandRPManageBatch RPbatch = new GatewayRefundandRPManageBatch();
        Database.executeBatch(RPbatch);
        test.stopTest();
        system.assertEquals(1, [select Id from Recurring_Payment__c where Id =: RPdata.Id].size());
    }

    @isTest static void testManageRPGatewayRefundandRPManageBatch(){
        Date todaysdate = Date.today();
        Recurring_Payment__c RPdata = TestDataFactory.RefundcreateRecurringPayment(45.00, todaysdate-1, todaysdate, '0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=', 'Weekly', '0031y00000HnkCJAAZ', '', 'Payway');

        test.startTest();
        GatewayRefundandRPManageBatch RPbatch = new GatewayRefundandRPManageBatch();
        Database.executeBatch(RPbatch);
        test.stopTest();
        system.assertEquals(1, [select Id from Recurring_Payment__c where Id =: RPdata.Id].size());
    }
}