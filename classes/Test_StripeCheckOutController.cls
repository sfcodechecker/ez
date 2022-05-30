@isTest
public with sharing class Test_StripeCheckOutController {
    @isTest static void testController(){
        Pagereference ref=new Pagereference('https://customization-speed-7529-dev-ed--c.visualforce.com/apex/StripeCheckOut?session_id=cs_test_a191FquI67z4a6ybVXUGc8ZLslqfofQnTHHC82oVf9mEHqLcJuFDBsbN8S');
        Test.setCurrentPage(ref);
        Test.startTest();
        StripeCheckoutController controller=new StripeCheckoutController();
        Test.stopTest();
        System.assertEquals('cs_test_a191FquI67z4a6ybVXUGc8ZLslqfofQnTHHC82oVf9mEHqLcJuFDBsbN8S', controller.session_id);
    }
    @isTest static void testControllerwithNoSessionId(){
        Pagereference ref=new Pagereference('/apex/StripeCheckOut?session_id=');
        Test.setCurrentPage(ref);
        Gateway_Detail__c gateway = TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator()); 
        StripeCheckoutController controller=new StripeCheckoutController();
        Test.stopTest();
        System.assertEquals('pk_test_51J1PxVSHrxjdfuOJNlLXneFV6zLRVBFjTngVyRE6WX4gwfHanYPwSAjs2p0uEB6K80NWnnwhADu4iZ8WBXgCzaTh00KxzWuHWZ', controller.publisher_key);
    }
    
    //Test method for oneoff session in charge now 
    @isTest static void testOneOffSession(){
        Contact con = new Contact(lastname='Kate',email='test@ex.com');
        insert con; 
        Gateway_Detail__c gateway=TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());        
        TransactionWrapper tranwpr = new TransactionWrapper();
        String actualValue = ChargeNowController.StripeOneOffService( con.Id, 56 ,String.valueof(URL.getSalesforceBaseUrl()));
        Test.stopTest();
        System.assertEquals(true, actualValue.startsWith('valid'));
    }

    //Test method for Schedule session in charge now
    @isTest static void testScheduleSession(){
        Contact con = new Contact(lastname='Kate',email='test@ex.com');
        insert con; 
        Gateway_Detail__c gateway=TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());        
        RecurringWrapper recurrWrap = new RecurringWrapper();
        String actualValue = ChargeNowController.StripeScheduleService( con.Id, 56, 'monthly' , String.valueof(Date.today()) ,String.valueof(URL.getSalesforceBaseUrl()));
        Test.stopTest();
        System.assertEquals(true, actualValue.startsWith('valid'));
    }
}