@isTest
public class Test_StripeManager {
    @isTest static void checkCredentialsTest(){
        Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        String res=StripeManager.validateCredentials(Gateway,false);
        Test.stopTest();
        System.assertEquals('valid',res);
        
    }
    @isTest static void postCredentialsTest(){
        Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        String res=StripeManager.PostCredentails(Gateway);
        Test.stopTest();
        System.assertEquals(true,res.startsWith('valid'));
    }
    /*
    @isTest static void postCredentialsCreateProductTest(){
        Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentialsNoOptionalKey();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        String res=StripeManager.PostCredentails(Gateway);
        Test.stopTest();
        System.assertEquals('valid:prod_K6BMGGNI21u8ds',res);
    }
    */
    @isTest static void createStripeCustomerTest(){
        
        Contact con=TestDataFactory.createContact();
        Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentials();
        StripeCustomerWrapper customer=new StripeCustomerWrapper();
        customer.name=con.FirstName+' '+con.LastName;
        customer.email=con.Email;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        String response=StripeManager.createStripeCustomer(customer);
        Test.stopTest();
        System.assertEquals('valid:cus_KU2jKpAeeuFBd1', response);
    }
    
    @isTest static void StripeCheckOutInitiatorTest(){
        Contact con=new Contact(FirstName='Stripe',LastName='Test',Email='stripetest@gmail.com');
        Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());        
        ChargeNowController.StripeOneOffService(con.id, 1200, 'salesforce.com');
        String response=StripeManager.StripeCheckoutInitiator('cus_K6V92Tl7bsBk7z','https://customization-speed-7529-dev-ed.cs76.my.salesforce.com/apex/StripeCheckoutSuccess?customer_id=cus_K6V92Tl7bsBk7z\u0026type=onetime\u0026record_id=0039D00000DPnJ0QAL\u0026requestedURL=https://customization-speed-7529-dev-ed.cs76.my.salesforce.com','https://customization-speed-7529-dev-ed.cs76.my.salesforce.com/apex/StripeCheckoutCancel?customer_id=cus_K6V92Tl7bsBk7z\u0026type=onetime\u0026record_id=0039D00000DPnJ0QAL\u0026requestedURL=https://customization-speed-7529-dev-ed.cs76.my.salesforce.com',25,'');
        Test.stopTest();
        System.assertEquals('valid:cs_test_a1DnDm0GRz68Fl5FlOvFDieBEvUJ3fMT8uXqVVmT2euWyui6ElqpHeALRz', response);
    }

    /***********************************Stripe test method for update card details***************************************************/
    @isTest static void TestStripeUpdateCardDetailsRequest(){
        
        Contact con = new Contact(lastname='Kate',email='test@ex.com');
        insert con; 
        Recurring_Payment__c reccur = TestDataFactory.createRecurringPayment( 1200, Date.today().addDays(-5),Date.today().addDays(2), '125XXXXXXX', 'half yearly', con.id, '', UTILGateway.STRIPEWORD);
        String result = '';
        Gateway_Detail__c gateway = TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());        
        result = UpdateCardDetailController.updateCardDetails( reccur.id, 'salesforce.com');
        Test.stopTest();
        System.assertEquals(true, result.startsWith('/apex/')); 

    }


    @isTest static void TestStripeUpdateCardDetails(){

        Contact con = new Contact(lastname='Kate',email='test@ex.com');
        insert con; 
        Recurring_Payment__c reccur = TestDataFactory.createRecurringPayment( 2000, Date.today().addDays(-5),Date.today().addDays(2), '125XXXXXXX', 'half yearly', con.id, '', UTILGateway.STRIPEWORD);

        Payment_Log__c payLog=TestDataFactory.createPaymentLogStripe( 2000 ,null,  null,  UTILGateway.ONETIMEKEYWORD, reccur.Id);
        payLog.Serialized_Record__c = '{"attributes":{"type":"Q_Charge__Recurring_Payment__c","url":"/services/data/v54.0/sobjects/Q_Charge__Recurring_Payment__c/'+reccur.Id+'"},"Id":"'+reccur.Id+'","Name":"'+reccur.Name+'","Q_Charge__Amount__c":2.96,"Q_Charge__Status__c":"Open","Q_Charge__Gateway_Schedule_Id__c":"sub_1KazIIFilGkYW1vHqeZxvscx","Q_Charge__RelatedToId__c":"'+reccur.Id+'"}';
        payLog.Transaction_Id__c ='sub_1KazIIFilGkYW1vHqeZxvscx';
        payLog.Requesting_Url__c = Url.getSalesforceBaseUrl().toExternalForm()+'/'+reccur.Id;
        payLog.Payment_Parameter_1__c = 'cs_test_c1NEquWIHL7OioSStRkdhBaF5G7Iy3GkMJAxmA1fWBhnVFXxd2NShzeYOD';

        update payLog;

        Gateway_Detail__c Gateway = TestDataFactory.createValidStripeCredentials();
        Test.startTest(); 
		Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        PageReference ProcessCard = Page.StripeUpdateCard; 
        Test.setCurrentPage(ProcessCard); 
        ProcessCard.getParameters().put('reference', 'stripe');
        ProcessCard.getParameters().put('record_id',reccur.Id);
        ProcessCard.getParameters().put('type', 'setup');
        UpdateCreditCardController controller = new UpdateCreditCardController();
        controller.updateStripeCard();
        String result = controller.result;
        Test.stopTest();
        System.assertEquals('Card details successfully updated in Stripe.', result);                      
    }

    /******************************Stripe test Methods for Update Recurring payment*********************************/
    @isTest static void TestStripeUpdateRP(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidStripeCredentials();
        Recurring_Payment__c rpTOUpdate = TestDataFactory.createRecurringPayment( 2000, Date.today().addDays(-5),Date.today().addDays(2), '125XXXXXXX', 'half yearly', TestDataFactory.createContact().id, '', UTILGateway.STRIPEWORD);
        
        Transaction__c transactiorec1 = TestDataFactory.createTransactionPaywayPaid( String.valueOf(rpTOUpdate.Id),  15, Datetime.now());
        Transaction__c transactiorec2 = TestDataFactory.createTransactionPaywayScheduled( String.valueOf(rpTOUpdate.Id),  15, Datetime.now());

        Test.startTest(); 
		Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        String result = UpdateRecurringPaymentController.StripeUpdateRP(rpTOUpdate);
        Test.stopTest();
        System.assertEquals(true, result.contains('updated successfully')); 
    }

    /******************************Stripe test Methods for Cancel Recurring payment*********************************/
    @isTest static void TestcancelStripeRP(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidStripeCredentials();
        List<Recurring_Payment__c> rpList = new List<Recurring_Payment__c>(); 
        rpList.add(TestDataFactory.createRecurringPayment( 2000, Date.today().addDays(-5),Date.today().addDays(2), '125XXXXXXX', 'half yearly', TestDataFactory.createContact().id, '', UTILGateway.STRIPEWORD));
        Transaction__c transactiorec1 = TestDataFactory.createTransactionPaywayPaid( String.valueOf(rpList[0].Id),  15, Datetime.now());
        Transaction__c transactiorec2 = TestDataFactory.createTransactionPaywayScheduled( String.valueOf(rpList[0].Id),  15, Datetime.now());
        
        Test.startTest(); 
		Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        String result = CancelRecurringPaymentController.cancelStripeRP(rpList);
        Test.stopTest();
        System.assertEquals(true, result.contains('cancelled successfully')); 
    }
}