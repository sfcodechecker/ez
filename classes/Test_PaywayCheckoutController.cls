@isTest
global class Test_PaywayCheckoutController 
{
    @isTest static void testTransLogForOneOff()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Payment_Log__c paymentLog = new Payment_Log__c(
        Processing_Record_Id__c = con.id, Amount__c=20.50,Action__c='Payway - OneTime page accessed', Request_Type__c='POST', Charge_Type__c = 'OneTime', Transaction_Status__c = 'Void');
        insert paymentLog;
        
        Test.StartTest();      
        PaywayManager.isConnected = true;  
        PageReference pageRef = Page.PaywayCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        PaywayCheckoutController controller = new PaywayCheckoutController();
        controller.singleUseTokenId = '7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.createTransaction();
        Test.StopTest();
        System.assertEquals(true, controller.recieptLogID != null);
    }


    @isTest static void testTransLogForRec()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Payment_Log__c paymentLog = new Payment_Log__c(Processing_Record_Id__c = con.id, Amount__c=20.50,Action__c='Payway - OneTime page accessed', Request_Type__c='POST', Charge_Type__c = 'Recurring', Payment_Parameter_1__c='',
        Transaction_Status__c = 'Void',Frequency__c = 'Weekly', Recurring_Start_Date__c = Date.today());
        insert paymentLog;
        Test.StartTest();        
        PaywayManager.isConnected = true;
        PageReference pageRef = Page.PaywayCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        PaywayCheckoutController controller = new PaywayCheckoutController();
        controller.singleUseTokenId = '7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.createTransaction();
        Test.StopTest();
        System.assertEquals(true, controller.recieptLogID != null);
    }
    
    @isTest static void testTransLogForRecRetry()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Payment_Log__c paymentLog = new Payment_Log__c(
        Processing_Record_Id__c = con.id, Amount__c=20.50,Action__c='Payway - OneTime page accessed', Request_Type__c='POST', Payment_Parameter_1__c = 'h0jyYk9ofG42DCKHTr939ELAp0ccluYQRRs9hgNNyZI=',
        Charge_Type__c = 'Recurring', Transaction_Status__c = 'Void',Frequency__c = 'Weekly', Recurring_Start_Date__c = Date.today());
        insert paymentLog;
        Test.StartTest();     
        PaywayManager.isConnected = true;   
        PageReference pageRef = Page.PaywayCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        PaywayCheckoutController controller = new PaywayCheckoutController();
        controller.createTransaction();
        controller.singleUseTokenId = '7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        Test.StopTest();
        System.assertEquals(true, controller.recieptLogID != null);
    }

    @isTest static void testAmountNull()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Payment_Log__c paymentLog = new Payment_Log__c(
        Processing_Record_Id__c = con.id,Action__c='Payway - OneTime page accessed', Request_Type__c='POST', Charge_Type__c = 'OneTime', Transaction_Status__c = 'Void');
        insert paymentLog;
        Test.StartTest();      
        PaywayManager.isConnected = true;  
        PageReference pageRef = Page.PaywayCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        PaywayCheckoutController controller = new PaywayCheckoutController();
        controller.singleUseTokenId = '7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.createTransaction();
        Test.StopTest();
        System.assertEquals(null, controller.paymentAmount);
    }

    @isTest static void testAmountLimitExceed()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Payment_Log__c paymentLog = new Payment_Log__c(
        Processing_Record_Id__c = con.id, Amount__c=15112.51,Action__c='Payway - OneTime page accessed', Request_Type__c='POST', Payment_Parameter_1__c = 'h0jyYk9ofG42DCKHTr939ELAp0ccluYQRRs9hgNNyZI='
        , Transaction_Status__c = 'Void',Frequency__c = 'Weekly', Recurring_Start_Date__c = Date.today());
        insert paymentLog;
        Test.StartTest();      
        PaywayManager.isConnected = true;  
        PageReference pageRef = Page.PaywayCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        PaywayCheckoutController controller = new PaywayCheckoutController();
        controller.singleUseTokenId = '7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.createTransaction();
        Test.StopTest();
        System.assertEquals(true, PaywayCheckoutController.renderMessage != null);
    }

    @isTest static void testBlankFrequency()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Payment_Log__c paymentLog = new Payment_Log__c(
        Processing_Record_Id__c = con.id, Amount__c=20.50,Action__c='Payway - OneTime page accessed', Request_Type__c='POST', Payment_Parameter_1__c = 'h0jyYk9ofG42DCKHTr939ELAp0ccluYQRRs9hgNNyZI=',
        Charge_Type__c = 'Recurring', Transaction_Status__c = 'Void', Recurring_Start_Date__c = Date.today());
        insert paymentLog;
        Test.StartTest();      
        PaywayManager.isConnected = true;  
        PageReference pageRef = Page.PaywayCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        PaywayCheckoutController controller = new PaywayCheckoutController();
        controller.singleUseTokenId = '7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.createTransaction();
        Test.StopTest();
        System.assertEquals(true, PaywayCheckoutController.renderMessage != null);
    }

}