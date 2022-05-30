@isTest
public class Test_EzidebitCheckoutController {
    @isTest static void testController()
    {
        String requestUrl = '';
        Contact newCon = TestDataFactory.newContact();
        Pagereference pageRef=Page.EzidebitCheckout;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,12.00,newCon.Id,null,null,UTILGateway.ONETIMEKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessOnetimePage,requestUrl,null);
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Gateway_Detail__c Gateway=TestDataFactory.createValidEzidebitCredentials();
        EzidebitManager.detachedReason=null;
        String endPoint='https://api.demo.ezidebit.com.au/V3-5/public-rest';
        EzidebitCheckoutController controller=new EzidebitCheckoutController();
        System.assertEquals('C4AEFBD5-2A4F-49CB-71CC-14490D6352AD',controller.publicKey);
        
    }

    @isTest static void testControllerCreatePaymentLog()
    {
        String requestUrl = '';
        String expected='';
        Contact newCon = TestDataFactory.newContact();
        Pagereference pageRef=Page.EzidebitCheckout;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,12.00,newCon.Id,null,null,UTILGateway.ONETIMEKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessOnetimePage,requestUrl,null);
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Gateway_Detail__c Gateway=TestDataFactory.createValidEzidebitCredentials();
        EzidebitManager.detachedReason=null;
        String endPoint='https://api.demo.ezidebit.com.au/V3-5/public-rest';
        EzidebitCheckoutController controller=new EzidebitCheckoutController();
        controller.jsonData=TestDataFactory.ezidebitOneTimeSuccessResponse();
        controller.createPaymentLog();
        if(controller.callbackUrl.contains('/apex')){
            expected=EzidebitHelper.getPostCheckoutUrl(controller.callbackUrl.substringAfter('reference='));
        }
        System.assertEquals(expected,controller.callbackUrl);
        
    }

    @isTest static void testController2()
    {
        String requestUrl = '';
        String expected = MessageHandler.apiKeyMissing;
        Contact newCon = TestDataFactory.newContact();
        Pagereference pageRef=Page.EzidebitCheckout;
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,12.00,newCon.Id,null,null,UTILGateway.ONETIMEKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessOnetimePage,requestUrl,null);
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Gateway_Detail__c Gateway=TestDataFactory.createValidEzidebitCredentials();
        String endPoint='https://api.demo.ezidebit.com.au/V3-5/public-rest';
        EzidebitCheckoutController controller=new EzidebitCheckoutController();
        System.assertEquals(expected,controller.errorMessage);
        
    }

    @isTest static void testRecurring(){
        String requestUrl = '';
        Contact newCon = TestDataFactory.newContact();
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,12.00,newCon.Id,'Weekly',Date.today().addDays(1),UTILGateway.RECURRINGKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessRecPayPage,requestUrl,null);
        Pagereference pageRef = Page.EzidebitRPCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        Test.startTest();
        EzidebitManager.detachedReason=null;
        EzidebitCheckoutController controller= new EzidebitCheckoutController();
        Test.stopTest();
        System.assertEquals('12.00', controller.amount);
    }
    @isTest static void testRecurringAmountLessThanOne(){
        String requestUrl = '';
        String expected = MessageHandler.amountBelowOneDoller;
        Contact newCon = TestDataFactory.newContact();
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,0.5,newCon.Id,'Weekly',Date.today().addDays(1),UTILGateway.RECURRINGKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessRecPayPage,requestUrl,null);
        Pagereference pageRef=Page.EzidebitRPCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        EzidebitManager.detachedReason=null;
        EzidebitCheckoutController controller= new EzidebitCheckoutController();
        System.assertEquals(expected, controller.errorMessage);
    }

    @isTest static void testRecurringAmountGreaterThanLimit(){
        String requestUrl = '';
        String expected = MessageHandler.amountMoreThanLimit;
        Contact newCon = TestDataFactory.newContact();
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,11000.00,newCon.Id,'Weekly',Date.today().addDays(1),UTILGateway.RECURRINGKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessRecPayPage,requestUrl,null);
        Pagereference pageRef=Page.EzidebitRPCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        Test.startTest();
        EzidebitManager.detachedReason=null;
        EzidebitCheckoutController controller= new EzidebitCheckoutController();
        Test.stopTest();
        System.assertEquals(expected, controller.errorMessage);
    }

    @isTest static void testRecurringWithNoCredentials(){
        String requestUrl = '';
        String expected = MessageHandler.apiKeyMissing;
        Contact newCon = TestDataFactory.newContact();
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,11000.00,newCon.Id,'Weekly',Date.today().addDays(1),UTILGateway.RECURRINGKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessRecPayPage,requestUrl,null);
        Pagereference pageRef=Page.EzidebitRPCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Test.startTest();

        EzidebitCheckoutController controller= new EzidebitCheckoutController();
        Test.stopTest();
        System.assertEquals(expected, controller.errorMessage);
    }
    
    @isTest static void testRecurringYesterday(){
        String requestUrl = '';
        String expected = MessageHandler.prevStartDate;
        Contact newCon = TestDataFactory.newContact();
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,5.00,newCon.Id,'Weekly',Date.today().addDays(-1),UTILGateway.RECURRINGKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessRecPayPage,requestUrl,null);
        Pagereference pageRef=Page.EzidebitRPCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        Test.startTest();
        EzidebitManager.detachedReason=null;
        EzidebitCheckoutController controller= new EzidebitCheckoutController();
        Test.stopTest();
        System.assertEquals(expected,controller.errorMessage);
    }

    @isTest static void testRecurringPastSix(){
        String requestUrl = '';
        String expected = '';
        String actual = '';
        Contact newCon = TestDataFactory.newContact();
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,5.00,newCon.Id,'Weekly',Date.today(),UTILGateway.RECURRINGKEYWORD,UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessRecPayPage,requestUrl,null);
        Pagereference pageRef=Page.EzidebitRPCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        Test.startTest();
        EzidebitManager.detachedReason=null;
        EzidebitCheckoutController controller= new EzidebitCheckoutController();
        Test.stopTest();
        Datetime currentDT=Datetime.now();
        String convertedDT=currentDT.format('yyyy-MM-dd HH:mm:ss a', 'Australia/Brisbane');
        convertedDT=convertedDT.substringAfter(' ');
        List<String> splitConvertedDT=convertedDT.split(':');
        Integer currentTime=Integer.valueOf(splitConvertedDT.get(0));
        Integer currentTimeMinutes=Integer.valueOf(splitConvertedDT.get(1));
        if(currentTime>=15){
            expected=MessageHandler.ezidebitprocessingTimeProduction;
            actual = controller.errorMessage;
        }
        System.assertEquals(expected, actual);
        
        
    }
}