@isTest
public with sharing class Test_GeneralMethodsFromCommonClasses {
    
    @isTest static void testActivePaymentList(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Gateway_Detail__c gateway1 = TestDataFactory.createValidPaywayCredentials();
        Gateway_Detail__c gateway2 = TestDataFactory.createValidEzidebitCredentials();
        Gateway_Detail__c gateway3 = TestDataFactory.createValidStripeCredentials();
        Gateway_Detail__c gateway4 = TestDataFactory.createValidSimplifyCredentials();
        Test.startTest();
        NABTransactManager.isConnected=true;
        PaywayManager.isConnected=true;
        EzidebitManager.isConnected=true;
        StripeManager.isConnected=true;
        SimplifyManager.isConnected=true;
        ChargeNowController.ActivePaymentList();
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Gateway_Detail__c where Name__c = 'nab_transact'].size()); 
    }

    @isTest static void testInstalmentPeriodList(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Test.startTest();
        NABTransactManager.isConnected=true;
        ChargeNowController.InstalmentPeriodList('nab_transact');
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Gateway_Detail__c where Name__c = 'nab_transact'].size()); 
    }

    @isTest static void testisGatewayConnected(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Test.startTest();
        NABTransactManager.isConnected=true;
        CancelRecurringPaymentController.isGatewayConnected('ABC');
        Test.stopTest();
        System.assertEquals(0, [Select Id, Name from Gateway_Detail__c where Name__c = 'ABC'].size()); 
    }
}