@isTest
public class Test_SimplifyCheckOutController {

    @isTest static void ControllertestOneTime(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,12,newCon.Id,'Weekly',Date.today(),UTILGateway.ONETIMEKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessOnetimePage,'',null);
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        Test.stopTest();
        System.assertEquals(12,controller.ref_log.Amount__c);
    }

    @isTest static void ControllertestOneTimeAmountBelowLimit(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        String expected = MessageHandler.amountBelowOneDoller;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,0.5,newCon.Id,'Weekly',Date.today(),UTILGateway.ONETIMEKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessOnetimePage,'',null);
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        Test.stopTest();
        System.assertEquals(expected,controller.errorMessage);
    }

    @isTest static void ControllertestOneTimeAmountAboveLimit(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        String expected = MessageHandler.amountMoreThanLimit;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,500001,newCon.Id,'Weekly',Date.today(),UTILGateway.ONETIMEKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessOnetimePage,'',null);
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        Test.stopTest();
        System.assertEquals(expected,controller.errorMessage);
    }

    @isTest static void ControllertestRecurring(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,12,newCon.Id,'Weekly',Date.today(),UTILGateway.RECURRINGKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessRecPayPage,'',null);
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        Test.stopTest();
        System.assertEquals(12,controller.ref_log.Amount__c);
    }

    @isTest static void ControllertestRecurringAmountBelowLimit(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        String expected = MessageHandler.amountLessThan50Cent;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,0.4,newCon.Id,'Weekly',Date.today(),UTILGateway.RECURRINGKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessRecPayPage,'',null);
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        Test.stopTest();
        System.assertEquals(expected,controller.errorMessage);
    }

    @isTest static void ControllertestRecurringAmountAboveLimit(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        String expected = MessageHandler.amountMoreThanLimit;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,10001,newCon.Id,'Weekly',Date.today(),UTILGateway.RECURRINGKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessRecPayPage,'',null);
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        Test.stopTest();
        System.assertEquals(expected,controller.errorMessage);
    }

    @isTest static void ControllertestRecurringAmountYesterday(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        String expected = MessageHandler.prevStartDate;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,10,newCon.Id,'Weekly',Date.today().addDays(-1),UTILGateway.RECURRINGKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessRecPayPage,'',null);
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        Test.stopTest();
        System.assertEquals(expected,controller.errorMessage);
    }

    @isTest static void ControllertestNoCredentials(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        String expected = MessageHandler.apiKeyMissing;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,12,newCon.Id,'Weekly',Date.today(),UTILGateway.RECURRINGKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessRecPayPage,'',null);
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        Test.stopTest();
        System.assertEquals(expected,controller.errorMessage);
    }


    @isTest static void testCompleteCheckoutOneOff(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        TransactionWrapper transWrapper= new TransactionWrapper();
        transWrapper.amount=12.00;
        transWrapper.sfProcessingId=newCon.Id;
        transWrapper.transactionType=UTILGateway.ONETIMEKEYWORD;
        transWrapper.requestUrl='';
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,12,newCon.Id,'Weekly',Date.today(),UTILGateway.ONETIMEKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessOnetimePage,'',JSON.serialize(transWrapper));
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        controller.responseToken = TestDataFactory.simplifyOneTimeSuccessResponse();
        controller.completeCheckout();
        Test.stopTest();
        System.assertEquals(true,controller.redirectUrl.contains('/apex'));
    }
    

    @isTest static void testCompleteCheckoutRecurring(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.sfProcessingId=newCon.Id;
        reccWrapper.amount=12;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,12,newCon.Id,'Weekly',Date.today(),UTILGateway.RECURRINGKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessRecPayPage,'',JSON.serialize(reccWrapper));
        Pagereference pageRef = Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        SimplifyManager.isConnected=true;
        SimplifyCheckOutController controller = new SimplifyCheckOutController();
        controller.responseToken = TestDataFactory.simplifyRecurringToken();
        controller.completeCheckout();
        Test.stopTest();
        System.assertEquals(true,controller.redirectUrl.contains('/apex'));
    }

}