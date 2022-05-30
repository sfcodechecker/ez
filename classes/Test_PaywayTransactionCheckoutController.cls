@deprecated
global class Test_PaywayTransactionCheckoutController 
{/*
    @isTest static void testPaywayTransaction()
    {
        Blob CryptoKey = Blob.valueOf('@U!cKCharGeAc0n$');        
        Contact testcon = new Contact(FirstName='Test', LastName='User',Email='vikashsrivastava547@gmail.com',Phone='988513215');
        insert testcon;
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c= 'T15629_PUB_wirkup5scwubn4q73u2rwv3at5hgdf2wt92d84m5g8nwvptpc66ea9jcqjyt',
                                                        Client_Key__c= 'T15629_PUB_wirkup5scwubn4q73u2rwv3at5hgdf2wt92d84m5g8nwvptpc66ea9jcqjyt',
                                                        optional_key_1__c = 'TEST',Name__c='payway');
        UTILGateway.encodeKeys(Gateway);
        insert Gateway;
        Test.StartTest();         
        PaywayTransactionRequestWrapper transactionrequest = new PaywayTransactionRequestWrapper();
        transactionrequest.principalAmount = '50';
        transactionrequest.singleUseTokenId = '7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        transactionrequest.customerNumber= 'sdshdds';
        transactionrequest.pcurrency= 'aud';
        transactionrequest.transactionType='payment';
        transactionrequest.merchantId='TEST';        
        string Payload = PaywayTransactionRequestWrapper.createTransactionPayLoad(transactionrequest);
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        HttpResponse res=PaywayManager.hitEndpoint('https://api.payway.com.au/rest/v1/transactions', 'POST', 'T15629_SEC_z4jevdx898enqp9uux4r7rbaqxj9xreir8w5bkiaxncj77z8gvhye6xut2wz',Payload);
        
        PageReference pageRef = Page.PaywayTransactionCheckout;
        pageRef.getParameters().put('ContactID', String.valueOf(testcon.Id));
        pageRef.getParameters().put('Amount', '50');
        pageRef.getParameters().put('singleUseTokenId', '7d432752-bf1a-4933-9fc8-257cf6e53fb1');
        pageRef.getParameters().put('transactionType', 'onetime');
        Test.setCurrentPage(pageRef);
        PaywayTransactionCheckoutController controller = new PaywayTransactionCheckoutController();
        controller.createTransaction();
        Test.StopTest();
        System.assertEquals('50', transactionrequest.principalAmount);
    }
    
    @isTest static void testOneOff(){
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = TestDataFactory.newContact();
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();   
        PaywayTransactionCheckoutController controller = new PaywayTransactionCheckoutController();
        controller.ContactID=String.valueOf(con.Id);
        controller.paymentAmount='15';
        controller.singleUseTokenId='7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.transactionType='onetime';
        controller.createTransaction();
        Test.stopTest();
        System.assertEquals('approved', controller.status); 
    }
    
    @isTest static void testRecurringSuccess(){
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = TestDataFactory.newContact();
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayTransactionCheckoutController controller = new PaywayTransactionCheckoutController();
        controller.ContactID=String.valueOf(con.Id);
        controller.paymentAmount='15';
        controller.singleUseTokenId='7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.paymentDate='2021-11-19';
        controller.paymentstartDate = Date.today().addDays(5);
        controller.frequency='weekly';
        controller.transactionType='Recurring';
        controller.createTransaction();
        Test.stopTest();
        System.assertEquals('Recurring', controller.transactionType);
    }
    
     @isTest static void testRecurringToday(){
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = TestDataFactory.newContact();
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayTransactionCheckoutController controller = new PaywayTransactionCheckoutController();
        controller.ContactID=String.valueOf(con.Id);
        controller.paymentAmount='15';
        controller.singleUseTokenId='7d432752-bf1a-4933-9fc8-257cf6e53fb1';
        controller.paymentDate='2021-11-19';
        controller.paymentstartDate = Date.today();
        controller.frequency='weekly';
        controller.transactionType='Recurring';
        controller.createTransaction();
        Test.stopTest();
        System.assertEquals('Recurring', controller.transactionType);
    }
    
    @isTest static void testRecurringNegative(){
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = TestDataFactory.newContact();
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayTransactionCheckoutController controller = new PaywayTransactionCheckoutController();
        controller.ContactID=String.valueOf(con.Id);
        controller.paymentAmount='15';
        controller.singleUseTokenId='ABCD';
        controller.paymentDate='2021-11-19';
        controller.paymentstartDate = Date.today().addDays(5);
        controller.frequency='wekly';
        controller.transactionType='Recurring';
        controller.createTransaction();
        Test.stopTest();
        System.assertEquals('Recurring', controller.transactionType);
    }
    
    @isTest static void testRecurringRetry(){
        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Contact con = TestDataFactory.newContact();
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        Test.startTest();
        PaywayTransactionCheckoutController controller = new PaywayTransactionCheckoutController();
        controller.ContactID=String.valueOf(con.Id);
        controller.paymentAmount='15';
        controller.paymentDate='2021-11-18';
        controller.frequency='weekly';
        controller.customerNumber='19';
        controller.transactionType='Recurring';
        controller.createTransaction();
        Test.stopTest();
        System.assertEquals('Recurring', controller.transactionType);
    }*/
}