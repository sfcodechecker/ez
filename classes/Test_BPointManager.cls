@isTest
public with sharing class Test_BPointManager {
    @TestSetup
    static void makeData(){
        Gateway_Detail__c bpoint_credentials = new Gateway_Detail__c();
        bpoint_credentials.Q_Charge__Name__c = 'bpoint';
        bpoint_credentials.Client_Id__c = 'atlas123';
        bpoint_credentials.Optional_Key_1__c = 'atlas0010';
        bpoint_credentials.Client_Key__c = 'abcd1234';
        UtilGateway.encodeKeys(bpoint_credentials);
        insert bpoint_credentials;
        Account acc = new Account();
        acc.Name = 'Bpoint Test Account';
        insert acc;
        Contact con = new Contact();
        con.FirstName = 'Bpoint Fname';
        con.LastName = 'Bpoint Lname';
        con.AccountId = acc.Id;
        insert con; 
    }
    
    testmethod private static  void performOnetimePayment() {
        Contact con = [Select Id From Contact Limit 1];
        List<Object> result = ChargeNowController.bpointOneOffService(con.Id, 100, 'single');
        System.assertEquals('success', result[0]);
        Pagereference pageRef_1 = new Pagereference((String)result[1]);
        String reference_id  = pageRef_1.getParameters().get('reference');
        Test.setCurrentPage(pageRef_1);
        BPointCheckoutPageController co_controller = new BPointCheckoutPageController();
        Pagereference pageRef_2 = new Pagereference('/apex/GatewayPostCheckout?reference='+reference_id+'&amount=100');
        Test.setCurrentPage(pageRef_2);
        GatewayPostCheckoutController pc_controller = new GatewayPostCheckoutController();
        pc_controller.completePayment();
    }

    testmethod private static  void performRecurringPayment() {
        Contact con = [Select Id From Contact Limit 1];
        List<Object> result = ChargeNowController.BpointScheduleService(con.Id, 100, 'weekly', String.valueOf(System.Today()));
        System.assertEquals('success', result[0]);
        Pagereference pageRef_1 = new Pagereference((String)result[1]);
        String reference_id  = pageRef_1.getParameters().get('reference');
        Test.setCurrentPage(pageRef_1);
        BPointCheckoutPageController co_controller = new BPointCheckoutPageController();
        Pagereference pageRef_2 = new Pagereference('/apex/GatewayPostCheckout?reference='+reference_id+'&amount=100');
        Test.setCurrentPage(pageRef_2);
        GatewayPostCheckoutController pc_controller = new GatewayPostCheckoutController();
        pc_controller.completePayment();
    }

    testmethod private static void performCalloutTests(){
        Test.setMock(HttpCalloutMock.class, new BPointMockResponseGenerator());
        //Gateway_Detail__c gateway = [Select Id,Client_Id__c,Optional_Key_1__c,Client_Key__c from Gateway_Detail__c];
        Gateway_Detail__c gateway = UtilGateway.decodeKeys(UtilGateway.BPOINTWORD);
        Test.startTest();
        HttpResponse resp_1 = BPointManager.hitEndpoint('https://www.bpoint.com.au/webapi/v3/txns/search', 'get', gateway, null);
        System.assertEquals(resp_1.getStatusCode(),200);
        HttpResponse resp_2 = BPointManager.hitEndpoint('https://www.bpoint.com.au/webapi/v3/txns/processtxnauthkey', 'get', gateway, null);
        System.assertEquals(resp_2.getStatusCode(),200);
        Test.stopTest();
    }

    @IsTest
    static void getTransactionsTest(){
        Test.setMock(HttpCalloutMock.class, new BPointMockResponseGenerator());
       	//Gateway_Detail__c gateway = [Select Id,Client_Id__c,Optional_Key_1__c,Client_Key__c from Gateway_Detail__c];
        Gateway_Detail__c gateway = UtilGateway.decodeKeys(UtilGateway.BPOINTWORD);
        Test.startTest();
        String responseBody = BPointManager.getTransactions('test');
        System.assert(responseBody!=null);
        Test.stopTest();
    }

    testmethod static void performRetryTest(){
        TransactionWrapper wrapper = new TransactionWrapper();
        ReceiptWrapper receipt = new ReceiptWrapper();
        BpointAuthKeyRequestWrapper bpointwraper = new BpointAuthKeyRequestWrapper();
        wrapper.jsonRequest = BpointAuthKeyRequestWrapper.serializeAuthKeyRequestWrapper(bpointwraper);
        BpointAuthKeyRequestWrapper.parse(wrapper.jsonRequest);
        wrapper.amount = 100;
        wrapper = BpointHelper.retryOneTime(wrapper,receipt);
        System.assert(wrapper!=null);
    }
}