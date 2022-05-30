@isTest
public class Test_GatewayPostCheckoutController {
    
    @isTest static void paywayOneTime()
    {
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Payment_Log__c plog = TestDataFactory.createValidOneTimeLog(String.valueOf(con.Id), gateway.Optional_Key_1__c, '7d432752-bf1a-4933-9fc8-257cf6e53fb1' );
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();      
        PaywayManager.isConnected = true;  
        PageReference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference', String.valueOf(plog.Id));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();
        controller.completePayment();
        Test.StopTest();
        System.assertEquals(true, controller.redirectUrl.startsWith('/apex/'));
    }

    //OneTime Pending
   
    //Negative 422 test for OneTime
    @isTest static void paywayOneTime422()
    {
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Payment_Log__c plog = TestDataFactory.createValidOneTimeLog(String.valueOf(con.Id), gateway.Optional_Key_1__c, '422' );
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();      
        PaywayManager.isConnected = true;  
        PageReference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference', String.valueOf(plog.Id));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();
        controller.completePayment();
        Test.StopTest();
        System.assertEquals(true, controller.redirectUrl.startsWith('/apex/'));
    }
    
    
    @isTest static void paywayRecPay()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Payment_Log__c paymentLog = TestDataFactory.createRePayLog(String.valueOf(con.Id), gateway.Optional_Key_1__c, '7d432752-bf1a-4933-9fc8-257cf6e53fb1' );
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();        
        PaywayManager.isConnected = true;
        PageReference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.id));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();
        controller.completePayment();
        Test.StopTest();
        System.assertEquals(true, controller.redirectUrl.startsWith('/apex/'));
    }
    
    //Negative 422 test for RP 
    @isTest static void paywayRecPay422()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Payment_Log__c paymentLog = TestDataFactory.createRePayLog(String.valueOf(con.Id), gateway.Optional_Key_1__c, '422' );
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();        
        PaywayManager.isConnected = true;
        PageReference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.id));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();
        controller.completePayment();
        Test.StopTest();
        System.assertEquals(true, controller.redirectUrl.startsWith('/apex/'));
    }
    
    @isTest static void paywayRecPayRetry()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;        
        Payment_Log__c paymentLog = TestDataFactory.createRetryRPLog(String.valueOf(con.Id), gateway.Optional_Key_1__c, 'Weekly',Date.today(),'7d432752-bf1a-4933-9fc8-257cf6e53fb1');
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();        
        PaywayManager.isConnected = true;
        PageReference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.id));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();
        controller.completePayment();
        Test.StopTest();
        System.assertEquals(true, controller.redirectUrl.startsWith('/apex/'));
    }
    
    //Negative 422 test for RP retry
    @isTest static void paywayRecPayRetry422()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;        
        Payment_Log__c paymentLog = TestDataFactory.createRetryRPLog(String.valueOf(con.Id), gateway.Optional_Key_1__c, '422', Date.today(), '422');
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();        
        PaywayManager.isConnected = true;
        PageReference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.id));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();
        controller.completePayment();
        Test.StopTest();
        System.assertEquals(true, controller.gatewayName == 'payway');
    }
    
    // Test method for future recurring.
    @isTest static void paywayRecPayFuture()
    {
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='paywaypayment@gmail.com');
        insert con;
        Payment_Log__c paymentLog = TestDataFactory.createRetryRPLog(String.valueOf(con.Id), gateway.Optional_Key_1__c, '7d432752-bf1a-4933-9fc8-257cf6e53fb1', Date.today().addDays(3), '7d432752-bf1a-4933-9fc8-257cf6e53fb1');
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.StartTest();        
        PaywayManager.isConnected = true;
        PageReference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference', String.valueOf(paymentLog.id));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();
        controller.completePayment();
        Test.StopTest();
        System.assertEquals(true, controller.redirectUrl.startsWith('/apex/'));
    }
    
    @isTest static void testEzidebitOneTime(){
        
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidEzidebitCredentials();
        Pagereference pageRef=Page.EzidebitCheckout;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,12.00,newCon.Id,null,null,UTILGateway.ONETIMEKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessOnetimePage,'',null);
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        EzidebitManager.detachedReason=null;
        String endPoint='https://api.demo.ezidebit.com.au/V3-5/public-rest';
        EzidebitCheckoutController controller=new EzidebitCheckoutController();
        controller.jsonData=TestDataFactory.ezidebitOneTimeSuccessResponse();
        controller.createPaymentLog();
        //Payment_Log__c plog = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,12.00,con.Id,null,null,UTILGateway.ONETIMEKEYWORD,UTILGateway.EZIDEBITWORD+' '+MessageHandler.storingResponse,'');
        Test.StartTest();      
        EzidebitManager.isConnected = true;  
        PageReference pageRefPostCheckout = Page.GatewayPostCheckout;
        pageRefPostCheckout.getParameters().put('reference', controller.callbackUrl.substringAfter('reference='));
        Test.setCurrentPage(pageRefPostCheckout);
        GatewayPostCheckoutController postCheckoutcontroller = new GatewayPostCheckoutController();
        postCheckoutcontroller.completePayment();
        Test.StopTest();
        System.assertEquals(true, postCheckoutcontroller.redirectUrl.startsWith('/apex/'));
    }

    @isTest static void testEzidebitOneTimeRetry(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidEzidebitCredentials();
        Pagereference pageRef=Page.EzidebitCheckout;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,12.00,newCon.Id,null,null,UTILGateway.ONETIMEKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessOnetimePage,'',null);
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        EzidebitManager.detachedReason=null;
        String endPoint='https://api.demo.ezidebit.com.au/V3-5/public-rest';
        EzidebitCheckoutController controller=new EzidebitCheckoutController();
        controller.jsonData=TestDataFactory.ezidebitOneTimeDeclinedResponse();
        controller.createPaymentLog();
        Test.StartTest();      
        EzidebitManager.isConnected = true;  
        PageReference pageRefPostCheckout = Page.GatewayPostCheckout;
        pageRefPostCheckout.getParameters().put('reference', controller.callbackUrl.substringAfter('reference='));
        Test.setCurrentPage(pageRefPostCheckout);
        GatewayPostCheckoutController postCheckoutcontroller = new GatewayPostCheckoutController();
        postCheckoutcontroller.completePayment();
        Test.StopTest();
        System.assertEquals(true, postCheckoutcontroller.redirectUrl.startsWith('/apex/'));
    }

    @isTest static void testEzidebitRecurringPayment(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String recordId='';
        Contact con = TestDataFactory.newContact();
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        String requestUrl='https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.amount=12.00;
        reccWrapper.sfProcessingId=con.Id;
        reccWrapper.name=con.FirstName+' '+con.LastName;
        reccWrapper.instalPeriod='Weekly';
        reccWrapper.startDate=Date.today().addDays(1);
        reccWrapper.transactionType=UTILGateway.RECURRINGKEYWORD; 
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,reccWrapper.amount,reccWrapper.sfProcessingId,reccWrapper.instalPeriod,reccWrapper.startDate,UTILGateway.RECURRINGKEYWORD,UTILGateway.EZIDEBITWORD+' '+MessageHandler.accessRecPayPage,'',JSON.serialize(reccWrapper));
        Pagereference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference',+log.Id+'1646646236178');
        Test.setCurrentPage(pageRef);
        Test.startTest();
        EzidebitManager.isConnected=true;
        GatewayPostCheckoutController postCheckout = new GatewayPostCheckoutController();
        postCheckout.completePayment();
        Test.stopTest();
        System.assertEquals(true, postCheckout.redirectUrl.startsWith('/apex'));
    }

    @isTest static void testEzidebitRecurringPaymentRetry(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String recordId='';
        Contact con = TestDataFactory.newContact();
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        String requestUrl='https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.amount=15.56;
        reccWrapper.sfProcessingId=con.Id;
        reccWrapper.name=con.FirstName+' '+con.LastName;
        reccWrapper.instalPeriod='Weekly';
        reccWrapper.startDate=Date.today().addDays(1);
        reccWrapper.transactionType=UTILGateway.RECURRINGKEYWORD; 
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,reccWrapper.amount,reccWrapper.sfProcessingId,reccWrapper.instalPeriod,reccWrapper.startDate,UTILGateway.RECURRINGKEYWORD,UTILGateway.EZIDEBITWORD+' '+MessageHandler.accessRecPayPage,'',JSON.serialize(reccWrapper));
        Pagereference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference',+log.Id+'1646646236178');
        Test.setCurrentPage(pageRef);
        Test.startTest();
        EzidebitManager.isConnected=true;
        GatewayPostCheckoutController postCheckout = new GatewayPostCheckoutController();
        postCheckout.completePayment();
        Test.stopTest();
        System.assertEquals(true, postCheckout.redirectUrl.startsWith('/apex'));
    }
}