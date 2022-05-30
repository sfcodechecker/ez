@isTest
public with sharing class Test_StripeCancelCheckout {
    @isTest static void testControllerValid(){
        Pagereference ref=new Pagereference('https://customization-speed-7529-dev-ed.cs76.my.salesforce.com/apex/StripeCheckoutCancel?customer_id=cus_K6V92Tl7bsBk7z\u0026type=onetime\u0026record_id=0039D00000DPnJ0QAL\u0026requestedURL=https://customization-speed-7529-dev-ed.cs76.my.salesforce.com');
        Test.setCurrentPage(ref);
        Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentials();
        Payment_Log__c payLog=TestDataFactory.createPaymentLog();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        StripeCancelCheckoutController controller=new StripeCancelCheckoutController();
        controller.completeSuccess();
        Test.stopTest();
        System.assertEquals('Unable to update credit card details due to Stripe transaction was cancelled. Please close the window.', controller.responseMessage);
        System.assertEquals('https://customization-speed-7529-dev-ed.cs76.my.salesforce.com', controller.refreshPage);
    }
}