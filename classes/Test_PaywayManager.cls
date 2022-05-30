@isTest 
global with sharing class Test_PaywayManager {
    
    @isTest static void testCheckCredentailswithvalidKey(){
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        
        gateway = UTILGateway.decodeKeys(UTILGateway.PAYWAYWORD);
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        PaywayAuthResponseWrapper testPaywayAuth;

        Test.startTest();
        testPaywayAuth = new PaywayAuthResponseWrapper();
        String response = PaywayManager.validateCredentials(gateway,true);
        Test.StopTest();
        System.assertEquals('valid', response);
    }
    
    
    @isTest static void testrefund1Doller(){

        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        List<Recurring_Payment__c> rpList = new List<Recurring_Payment__c>();
        rpList.add(TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(5),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.id),'','Payway'));
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayHelper.refund1Doller(rpList);
        Test.stopTest();
        Recurring_Payment__c updatedrecData = [Select id, Refund_Status__c from Recurring_Payment__c where id =: rpList[0].Id];
        System.assertEquals('Refunded',updatedrecData.Refund_Status__c);
    }

    //422 Refund coverage
    @isTest static void testrefund1Doller422(){
        
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        List<Recurring_Payment__c> rpList = new List<Recurring_Payment__c>();
        rpList.add(TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(5),'422','Weekly',String.valueOf(con.id),'422','Payway'));
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayHelper.refund1Doller(rpList);
        Test.stopTest();
        Recurring_Payment__c updatedrecData = [Select id, Refund_Status__c from Recurring_Payment__c where id =: rpList[0].Id];
        System.assertEquals('Failed',updatedrecData.Refund_Status__c);
    }


    @isTest static void testfetchRecurringTransaction(){

        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        List<Recurring_Payment__c> rpList = new List<Recurring_Payment__c>();
        rpList.add(TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(5),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.id),'','Payway'));
        Transaction__c transactiorec1 = TestDataFactory.createTransactionPaywayPaid( String.valueOf(rpList[0].Id),  15, Datetime.now());
        Transaction__c transactiorec2 = TestDataFactory.createTransactionPaywayScheduled( String.valueOf(rpList[0].Id),  15, Datetime.now());
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayHelper.fetchRecurringTransaction(rpList);
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
        System.assertEquals(5,callouts);
    }

    //Payway 422 fetchRecurringTransaction coverage
    @isTest static void testfetchRecurringTransaction422(){

        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        List<Recurring_Payment__c> rpList = new List<Recurring_Payment__c>();
        rpList.add(TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(5),'Grj08UqKHBNjOGEw+gKOFcbdee4dW4VH6pr19J1xHug=','Weekly',String.valueOf(con.id),'','Payway'));
        Transaction__c transactiorec1 = TestDataFactory.createTransactionPaywayPaid( String.valueOf(rpList[0].Id),  15, Datetime.now());
        Transaction__c transactiorec2 = TestDataFactory.createTransactionPaywayScheduled( String.valueOf(rpList[0].Id),  15, Datetime.now());
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayHelper.fetchRecurringTransaction(rpList);
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
        System.assertEquals(5,callouts);
    }

    @isTest static void testcancelRecurringPayment(){

        
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        
        List<Recurring_Payment__c> rpList = new List<Recurring_Payment__c>();
        rpList.add(TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(5),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.id),'','Payway'));
        String expected = rpList[0].Name+' '+'cancelled successfully in Payway.';
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        String actual = PaywayHelper.cancelRecurringPayment(rpList);
        Test.stopTest();
        system.assertEquals(expected, actual);
    }

    @isTest static void testsendCancelFailureEmail(){
        Test.startTest();
        PaywayHelper.sendCancelFailureEmail( '19231' ,  'Recurring Cancel Fialed');
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        system.assertEquals(0, invocations);
    }

    @isTest static void testgetPaymentStatusMessage(){
        String actual = '400 Bad request. The request could not be understood by the server due to malformed syntax.';
        Test.startTest();
        String expected = PaywayHelper.getPaymentStatusMessage('400');
        Test.stopTest();
        system.assertEquals(actual, expected);
    }

    @isTest static void paywayOneTime()
    {
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();      
        PaywayManager.isConnected = true;
        String actual = ChargeNowController.paywayOneOffService(con.Id, 212.00);
        Test.StopTest();
        System.assertEquals(true, actual.startsWith('/apex/'));
    }


    @isTest static void testrequestUpdateCardDetails(){

        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(5),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.id),'','Payway');
        String requestURL = 'https://momentum-velocity-6590-dev-ed.lightning.force.com/lightning/r/Q_Charge__Recurring_Payment__c/a021y000007TuCjAAK/view';
        Test.startTest();
        String expected = PaywayHelper.requestUpdateCardDetails(String.valueOf(recData.ID),String.valueOf(recData.Gateway_Schedule_Id__c),requestURL);
        Test.stopTest();
        system.assertEquals(true,  expected != '');
    }

    //valid request for Url
    @isTest static void testRequestUrl()
    {
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.amount = 5.0;
        reccWrapper.sfProcessingId = '1216154465';
        reccWrapper.instalPeriod = 'Weekly';
        reccWrapper.startDate = Date.today().addDays(1);
        reccWrapper.transactionType = 'Recurring';
        String actual = PaywayHelper.requestPaymentURL(reccWrapper);
        System.assertEquals(true, actual.startsWith('/apex/'));
    }

    //blank frequency for Url request
    @isTest static void testRequestUrlexceedAmount()
    {
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.amount = 54125.0;
        reccWrapper.sfProcessingId = '1216154465';
        reccWrapper.instalPeriod = 'monthly';
        reccWrapper.startDate = Date.today().addDays(1);
        reccWrapper.transactionType = 'Recurring';
        String actual = PaywayHelper.requestPaymentURL(reccWrapper);
        System.assertEquals(false, actual.startsWith('/apex/'));
    }

    //exceed start date for Url request
    @isTest static void testRequestUrlExceedDate()
    {
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.amount = 5.0;
        reccWrapper.sfProcessingId = '1216154465';
        reccWrapper.instalPeriod = 'monthly';
        reccWrapper.startDate = Date.today().addYears(3);
        reccWrapper.transactionType = 'Recurring';
        String actual = PaywayHelper.requestPaymentURL(reccWrapper);
        System.assertEquals(false, actual.startsWith('/apex/'));
    }

    @isTest static void testezidebitCancelRPSuccess(){
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        List<Recurring_Payment__c> rpList = new List<Recurring_Payment__c>();
        rpList.add(TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(5),'Grj08UqKHBNjOGEw+gKOFcbdee4dW4VH6pr19J1xHug=','Weekly',String.valueOf(con.id),'','Payway'));
        Transaction__c transactiorec1 = TestDataFactory.createTransactionPaywayPaid( String.valueOf(rpList[0].Id),  15, Datetime.now());
        Transaction__c transactiorec2 = TestDataFactory.createTransactionPaywayScheduled( String.valueOf(rpList[0].Id),  15, Datetime.now());

        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayManager.isConnected=true;
        String actual = CancelRecurringPaymentController.cancelPaywayRP(rpList);
        Test.stopTest();
        System.assertEquals(true, actual.contains('success')); 
    }
}