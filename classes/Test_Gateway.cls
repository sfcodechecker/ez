@isTest
public class Test_Gateway {
    public testmethod static void TestSpecificGatewayDetails(){
        Gateway_Detail__c Gateway;
        TestDataFactory.createValidEzidebitCredentials(); 
        TestDataFactory.createValidPaywayCredentials(); 
        TestDataFactory.createValidSimplifyCredentials(); 
        TestDataFactory.createValidBPointCredentials(); 
        TestDataFactory.createValidStripeCredentials(); 
        TestDataFactory.createValidNABCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        //GatewaySetup.SpecificGatewayDetails(UTILGateway.BPOINTWORD);
        GatewaySetup.SpecificGatewayDetails(UTILGateway.PAYWAYWORD);
        GatewaySetup.SpecificGatewayDetails(UTILGateway.EZIDEBITWORD);       
        Gateway = GatewaySetup.SpecificGatewayDetails(UTILGateway.STRIPEWORD);
        Test.stopTest();
        System.assertEquals(UTILGateway.STRIPEWORD, Gateway.Q_Charge__Name__c);
    }
    
    public testmethod static void TestUpdateGatewayDetails(){
        Gateway_Detail__c gtWay = new Gateway_Detail__c();
        gtWay.Client_Id__c = '123456';
        gtWay.Optional_Key_1__c = '123456';
        gtWay.Client_Key__c = '123456';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        GatewaySetup.UpdateGatewayDetails(gtWay,UTILGateway.BPOINTWORD);
        GatewaySetup.UpdateGatewayDetails(gtWay,UTILGateway.PAYWAYWORD);
        GatewaySetup.UpdateGatewayDetails(gtWay,UTILGateway.EZIDEBITWORD);
        GatewaySetup.UpdateGatewayDetails(gtWay,UTILGateway.SIMPLIFYWORD);        
        GatewaySetup.UpdateGatewayDetails(gtWay,UTILGateway.STRIPEWORD);
        GatewaySetup.sendExceptionEmail('Test');
        Test.stopTest();
        System.assertEquals(UTILGateway.STRIPEWORD, gtWay.Q_Charge__Name__c);
    } 
    public testmethod static void TestEmailException(){
        try{
            StripeManager.CheckExistingCredentails();
        }catch(Exception ex){
            Emailhandler.sendExceptionEmail('Email', ex, true);
            Emailhandler.sendExceptionEmailtoAdmin('Email', ex, false);
        }
        System.assertEquals(MessageHandler.apiKeyMissing, StripeManager.detachedReason);
    }

    public testmethod static void TestsetDefaultGateway(){
        Gateway_Detail__c gateway=TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Boolean actual= GatewaySetup.setDefaultGateway('stripe');
        Test.stopTest();
        System.assertEquals(true, actual);
    }   
}