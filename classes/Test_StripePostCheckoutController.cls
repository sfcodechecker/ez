@isTest
public class Test_StripePostCheckoutController {
    
    @isTest static void testControllerOneTimeValid(){
        Pagereference ref=new Pagereference('/apex/StripeCheckoutSuccess?record_id=0039D00000DPnJ0QAL&requestedURL==https%3A%2F%2Fcustomization-speed-7529-dev-ed.cs76.my.salesforce.com&customer_id=cus_K6V92Tl7bsBk7z&type=onetime&status=accept&reference=stripe');
        Test.setCurrentPage(ref);
        Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentials();
        Payment_Log__c payLog=TestDataFactory.createPaymentLogStripe( 2000 ,null,  null,  UTILGateway.ONETIMEKEYWORD, TestDataFactory.createContact().Id);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        GatewayPostCheckoutController controller=new GatewayPostCheckoutController();
        controller.completePayment();
        Test.stopTest();
        System.assertEquals(true, controller.redirectUrl.startsWith('/apex/')); 
    }

    @isTest static void testControllerInvalid(){

        Pagereference ref=new Pagereference('/apex/StripeCheckoutSuccess?record_id=0039D00000DPnJ0QAL&requestedURL==https%3A%2F%2Fcustomization-speed-7529-dev-ed.cs76.my.salesforce.com&customer_id=cus_K6V92Tl7bsBk7z&type=onetime&status=accept&reference=stripe');
        Test.setCurrentPage(ref);
        Payment_Log__c payLog=TestDataFactory.createPaymentLogStripe( 2000 ,null,  null,  UTILGateway.ONETIMEKEYWORD, TestDataFactory.createContact().Id);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        GatewayPostCheckoutController controller=new GatewayPostCheckoutController();
        controller.completePayment();
        Test.stopTest();
        System.assertEquals(true, controller.errorMessage != null);
    }
     
    @isTest static void testControllerRecurringValid(){
        Pagereference ref=new Pagereference('/apex/StripeCheckoutSuccess?record_id=0039D00000DPnJ0QAL&requestedURL=https%3A%2F%2Fcustomization-speed-7529-dev-ed.cs76.my.salesforce.com&customer_id=cus_K6V92Tl7bsBk7z&type=recurring&reference=stripe&status=accept');
        Test.setCurrentPage(ref);
        Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentials();
        Payment_Log__c payLog=TestDataFactory.createPaymentLogStripe( 2000 ,'weekly',  Date.today(),  UTILGateway.RECURRINGKEYWORD, TestDataFactory.createContact().Id);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        GatewayPostCheckoutController controller=new GatewayPostCheckoutController();        
        controller.completePayment();
        Test.stopTest();
        System.assertEquals(true, controller.redirectUrl.startsWith('/apex/'));         
    }
}