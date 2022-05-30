@isTest
public with sharing class Test_UpdateCreditCardController {
    
    @isTest static void testUpdatePaywayCard(){

        String actual = MessageHandler.creditCardUpdatSuccesse+'Payway.';
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(6),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.Id),'','Payway');
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Payment_Log__c paymentLog = new Payment_Log__c(Processing_Record_Id__c = recData.Id, Action__c='Payway - Update Credit Card Detail Request',
        Transaction_Id__c = recData.Gateway_Schedule_Id__c ,Requesting_Url__c = 'https://momentum-velocity-6590-dev-ed.lightning.force.com/lightning/r/Q_Charge__Recurring_Payment__c/a021y000007TuCjAAK/view', Gateway_Name__c = 'payway');
        insert paymentLog;
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();        
        PaywayManager.isConnected = true;
        PageReference pageRef = Page.PaywayUpdateCard;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        UpdateCreditCardController controller = new UpdateCreditCardController();
        controller.singleUseTokenId = '7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.updatePaywayCard();
        Test.StopTest();
        System.assertEquals(actual, controller.result);
    }

    //Negative 422 for update recurring payments
    @isTest static void testUpdatePaywayCard422(){

        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(6),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.Id),'','Payway');
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Payment_Log__c paymentLog = new Payment_Log__c(Processing_Record_Id__c = recData.Id, Action__c='Payway - Update Credit Card Detail Request',Transaction_Id__c = recData.Gateway_Schedule_Id__c ,Requesting_Url__c = 'https://momentum-velocity-6590-dev-ed.lightning.force.com/lightning/r/Q_Charge__Recurring_Payment__c/a021y000007TuCjAAK/view', Gateway_Name__c = 'payway');
        insert paymentLog;
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();        
        PaywayManager.isConnected = true;
        PageReference pageRef = Page.PaywayUpdateCard;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        UpdateCreditCardController controller = new UpdateCreditCardController();
        controller.singleUseTokenId = 'Grj08UqKHBNjOGEw+gKOFcbdee4dW4VH6pr19J1xHug=';
        controller.updatePaywayCard();
        Test.StopTest();
        System.assertEquals(true, controller.result.startsWith('/apex/'));
    }

    @isTest static void testUpdateRecurringPaymentNegative(){
        
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='ezidebitpayment@gmail.com');
        insert con;
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(6),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.Id),'','ezidebit');
        Gateway_Detail__c gateway = TestDataFactory.createValidEzidebitCredentials();
        Payment_Log__c paymentLog = new Payment_Log__c(Processing_Record_Id__c = recData.Id, Action__c='Ezidebit - Update Credit Card Detail Request',
        Transaction_Id__c = recData.Gateway_Schedule_Id__c ,Requesting_Url__c = 'https://momentum-velocity-6590-dev-ed.lightning.force.com/lightning/r/Q_Charge__Recurring_Payment__c/a021y000007TuCjAAK/view', Gateway_Name__c = 'ezidebit');
        insert paymentLog;
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Test.StartTest();        
        EzidebitManager.isConnected = true;
        PageReference pageRef = Page.EzidebitUpdateCard;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        UpdateCreditCardController controller = new UpdateCreditCardController();
        controller.returnMsg = 'Failed';
        controller.UpdateRecurringPayment();
        Test.StopTest();
        System.assertEquals(true, controller.result.startsWith('/apex/'));
    }

    @isTest static void testUpdateRecurringPaymentPositive(){
        String expected = MessageHandler.creditCardUpdatSuccesse+'Ezidebit.';
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='ezidebitpayment@gmail.com');
        insert con;
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(6),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.Id),'','ezidebit');
        Gateway_Detail__c gateway = TestDataFactory.createValidEzidebitCredentials();
        Payment_Log__c paymentLog = new Payment_Log__c(Processing_Record_Id__c = recData.Id, Action__c='Ezidebit - Update Credit Card Detail Request',
        Transaction_Id__c = recData.Gateway_Schedule_Id__c ,Requesting_Url__c = 'https://momentum-velocity-6590-dev-ed.lightning.force.com/lightning/r/Q_Charge__Recurring_Payment__c/a021y000007TuCjAAK/view', Gateway_Name__c = 'ezidebit');
        insert paymentLog;
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Test.StartTest();        
        EzidebitManager.isConnected = true;
        PageReference pageRef = Page.EzidebitUpdateCard;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        UpdateCreditCardController controller = new UpdateCreditCardController();
        controller.returnMsg = 'Success';
        controller.UpdateRecurringPayment();
        Test.StopTest();
        System.assertEquals(expected, controller.result);
        //System.assertEquals(expected, controller.result);
    }

    @isTest static void testNABCoverage(){
        
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='nab_transactpayment@gmail.com');
        insert con;
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(6),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.Id),'','nab_transact');
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Payment_Log__c paymentLog = new Payment_Log__c(Processing_Record_Id__c = recData.Id, Action__c='Nab_transact - Update Credit Card Detail Request',
        Transaction_Id__c = recData.Gateway_Schedule_Id__c ,Requesting_Url__c = 'https://momentum-velocity-6590-dev-ed.lightning.force.com/lightning/r/Q_Charge__Recurring_Payment__c/a021y000007TuCjAAK/view', Gateway_Name__c = 'nab_transact');
        insert paymentLog;
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Test.StartTest();        
        NABTransactManager.isConnected = true;
        PageReference pageRef = Page.EzidebitUpdateCard;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.Id));
        Test.setCurrentPage(pageRef);
        UpdateCreditCardController controller = new UpdateCreditCardController();
        controller.returnMsg = String.valueOf(paymentLog.id);
        Test.StopTest();
        System.assertEquals('nab_transact', controller.gatewayName);
    }
}