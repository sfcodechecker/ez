@isTest
public class Test_SimplifyManager {
    public static String status;            //values are pass or fail

    /*
    @isTest static void AuthenticateSimplifyTest(){
        
        /*Gateway_Detail__c gateway = new Gateway_Detail__c(Client_Id__c='sbpb_NTkzZTQwODEtZGQzNS00Y2I5LTk1ZGEtOTc4NmJjYzg4ODk1', Client_Key__c='inqbKA4k4UKmHdU/N3XhGOimBscGhKeRWf42R49Rucl5YFFQL0ODSXAOkNtXTToq', HostedPayments_PublicKey__c='sbpb_NDVlMDFiMjMtMTE4NC00ZmUxLTgyYjgtZWM0ZjM5NDI4ZDAy', HostedPayments_PrivateKey__c='fquJOD+dVwCsQPW+//w23BmUV+Xt1k2lujRpkss+T9N5YFFQL0ODSXAOkNtXTToq', Name__c='simplify');
        String res = SimplifyManager.AuthenticateSimplify(gateway);
        String expected = 'https://commbank.simplify.com/commerce/oauth/authorize?response_type=code&scope=full&client_id=sbpb_NTkzZTQwODEtZGQzNS00Y2I5LTk1ZGEtOTc4NmJjYzg4ODk1';
        system.assertEquals(expected, res);        
    }
    
    @isTest static void storeAuthCodeTest(){
        
        String res = SimplifyManager.storeAuthCode('gLzBexgEjy8nd9');
        system.assertEquals(1, [select Id, Name__c from Gateway_Detail__c where Name__c='simplify'].size());
    }
    
    @isTest static void checkCredentialsTest(){
        
        Gateway_Detail__c gateway = new Gateway_Detail__c(Authorisation_Code__c='84g9nb6jeGdx9r',  Name__c='simplify');
        UTILGateway.encodeKeys(gateway);
        insert gateway;
        String res = SimplifyManager.checkCredentials(gateway);
        system.assertEquals('valid', res);
    }
    
    @isTest static void accessHostedPageTest(){
        
        String res = SimplifyManager.accessHostedPage('0039D00000DPnJ0QAL', 123.00);
        String expected = '/apex/Q_Charge__SimplifyCheckout?recordId=0039D00000DPnJ0QAL&amount=12300';
        system.assertEquals(expected, res);
    }
    */
    
    @isTest static void testValidateCredentialsSuccess(){
        Gateway_Detail__c gateway = new Gateway_Detail__c(HostedPayments_PublicKey__c='sbpb_Y2EyMzVjZjItNGJlOC00ZjU1LTgxNzEtNmUxZmYzZGIzZTJi',
        HostedPayments_PrivateKey__c='tYHzqxuY7NGwWmdFoOJSYGhApkv/O9yQipehFFTtwjR5YFFQL0ODSXAOkNtXTToq',
        Name__c=UTILGateway.SIMPLIFYWORD, Authorisation_Code__c='gLzBexgEjy8nd9'); 
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());  
        String expected = 'valid';
        String result=SimplifyManager.validateCredentials(Gateway, true);
        System.assertEquals(expected, result);
    }
    
    @isTest static void testchargeNowSimplifyOneOffSuccess(){
        Contact newCon = TestDataFactory.newContact();
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = '/apex/Q_Charge__SimplifyCheckout?reference=';
        String result = ChargeNowController.SimplifyOneOffService(newCon.Id, 12, requestUrl);
        if(result.contains('/apex')){
            expected+=result.substringAfter('reference=');
        }
        System.assertEquals(expected, result);
    }

    @isTest static void testChargeNowSimplifyIdNull(){
        Contact newCon = TestDataFactory.newContact();
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = MessageHandler.wentWrongCatchMessage;
        String result = ChargeNowController.SimplifyOneOffService(null, 12, requestUrl);
        System.assertEquals(expected, result);
    }

    @isTest static void testChargeNowSimplifyAmountNull(){
        Contact newCon = TestDataFactory.newContact();
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = MessageHandler.wentWrongCatchMessage;
        String result = ChargeNowController.SimplifyOneOffService(newCon.Id, null, requestUrl);
        System.assertEquals(expected, result);
    }
    
    @isTest static void testChargeNowSimplifyAmountLessThanDollar(){
        Contact newCon = TestDataFactory.newContact();
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = MessageHandler.amountBelowOneDoller;
        String result = ChargeNowController.SimplifyOneOffService(newCon.Id, 0.5, requestUrl);
        System.assertEquals(expected, result);
    }

    @isTest static void testChargeNowSimplifyAmountGreaterThanHalfMillion(){
        Contact newCon = TestDataFactory.newContact();
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = MessageHandler.amountMoreThanLimit;
        String result = ChargeNowController.SimplifyOneOffService(newCon.Id, 5000001, requestUrl);
        System.assertEquals(expected, result);
    }

    @isTest static void testProcessingOneTime(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        TransactionWrapper transWrapper= new TransactionWrapper();
        transWrapper.amount=12.00;
        transWrapper.sfProcessingId=newCon.Id;
        transWrapper.transactionType=UTILGateway.ONETIMEKEYWORD;
        transWrapper.requestUrl='';
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,12.00,newCon.Id,null,null,UTILGateway.ONETIMEKEYWORD,UTILGateway.SIMPLIFYWORD.capitalize() +''+MessageHandler.accessOnetimePage,'',JSON.serialize(transWrapper));
        Pagereference pageRef=Page.SimplifyCheckout;
        pageRef.getParameters().put('reference',log.Id);
        Test.setCurrentPage(pageRef);
        SimplifyCheckoutController controller=new SimplifyCheckoutController();
        controller.responseToken=TestDataFactory.simplifyOneTimeSuccessResponse();
        controller.completeCheckout();
        //Payment_Log__c plog = TestDataFactory.createPaymentLog(UTILGateway.EZIDEBITWORD,12.00,con.Id,null,null,UTILGateway.ONETIMEKEYWORD,UTILGateway.EZIDEBITWORD+' '+MessageHandler.storingResponse,'');
        Test.StartTest();      
        SimplifyManager.isConnected = true;  
        PageReference pageRefPostCheckout = Page.GatewayPostCheckout;
        pageRefPostCheckout.getParameters().put('reference', controller.redirectUrl.substringAfter('reference='));
        Test.setCurrentPage(pageRefPostCheckout);   //
        GatewayPostCheckoutController postCheckoutcontroller = new GatewayPostCheckoutController();
        postCheckoutcontroller.completePayment();
        Test.StopTest();
        System.assertEquals(true, postCheckoutcontroller.redirectUrl.startsWith('/apex/'));
    }

    @isTest static void testChargeNowSimplifyRecurringSuccess(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());  
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = '/apex/Q_Charge__SimplifyCheckout?reference=';
        Test.startTest();
        SimplifyManager.isConnected=true;
        String result = ChargeNowController.SimplifyScheduleService(newCon.Id, 12.00, 'Weekly', String.valueOf(Date.today()));
        if(result.contains('/apex')){
            expected+=result.substringAfter('reference=');
        }
        Test.stopTest();
        System.assertEquals(expected, result);
    }
    @isTest static void testChargeNowSimplifyRecurringAmountNull(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());  
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = MessageHandler.wentWrongCatchMessage;
        Test.startTest();
        SimplifyManager.isConnected=true;
        String result = ChargeNowController.SimplifyScheduleService(newCon.Id, null, 'Weekly', String.valueOf(Date.today()));
        Test.stopTest();
        System.assertEquals(expected, result);
    }

    @isTest static void testChargeNowSimplifyRecurringIdNull(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());  
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        Test.startTest();
        SimplifyManager.isConnected=true;
        String result = ChargeNowController.SimplifyScheduleService(null, 12.00, 'Weekly', String.valueOf(Date.today()));
        Test.stopTest();
        System.assertEquals(true, result.contains('Something went wrong'));
    }

    @isTest static void testChargeNowSimplifyRecurringAmountBelowLimit(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());  
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = MessageHandler.amountLessThan50Cent;
        Test.startTest();
        SimplifyManager.isConnected=true;
        String result = ChargeNowController.SimplifyScheduleService(newCon.Id, 0.2, 'Weekly', String.valueOf(Date.today()));
        Test.stopTest();
        System.assertEquals(expected, result);
    }

    @isTest static void testChargeNowSimplifyRecurringAmountAboveLimit(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());  
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = MessageHandler.amountMoreThanLimit;
        Test.startTest();
        SimplifyManager.isConnected=true;
        String result = ChargeNowController.SimplifyScheduleService(newCon.Id, 10001, 'Weekly', String.valueOf(Date.today()));
        Test.stopTest();
        System.assertEquals(expected, result);
    }

    @isTest static void testChargeNowSimplifyRecurringYesterday(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());  
        String requestUrl = Url.getSalesforceBaseUrl().toExternalForm()+'/'+newCon.Id;
        String expected = MessageHandler.prevStartDate;
        Test.startTest();
        SimplifyManager.isConnected=true;
        String result = ChargeNowController.SimplifyScheduleService(newCon.Id, 12, 'Weekly', String.valueOf(Date.today().addDays(-1)));
        Test.stopTest();
        System.assertEquals(expected, result);
    }


    @isTest static void testSimplifyRecurringPayment(){
        status='pass';
        Contact con = TestDataFactory.newContact();
        Gateway_Detail__c gateway=TestDataFactory.createValidSimplifyCredentials();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
        String requestUrl='https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.amount=12.00;
        reccWrapper.sfProcessingId=con.Id;
        reccWrapper.name=con.FirstName+' '+con.LastName;
        reccWrapper.instalPeriod='Weekly';
        reccWrapper.startDate=Date.today().addDays(1);
        reccWrapper.transactionType=UTILGateway.RECURRINGKEYWORD; 
        reccWrapper.trialPeriod=(reccWrapper.startDate > Date.today())?'DAYS':'NONE';
        reccWrapper.trialDays=(reccWrapper.startDate > Date.today())?SimplifyHelper.getTrialDays(reccWrapper):0;
        reccWrapper.planId='9kpjKqojk';
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,reccWrapper.amount,reccWrapper.sfProcessingId,reccWrapper.instalPeriod,reccWrapper.startDate,UTILGateway.RECURRINGKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessRecPayPage,'',JSON.serialize(reccWrapper));
        SimplifyManager.isConnected=true;
        Pagereference reference = Page.SimplifyCheckout;
        reference.getParameters().put('reference',log.Id);
        Test.setCurrentPage(reference);
        SimplifyCheckoutController controller = new SimplifyCheckoutController();
        controller.responseToken=TestDataFactory.simplifyRecurringToken();
        controller.completeCheckout();
        Test.startTest();
        SimplifyManager.isConnected=true;
        Pagereference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference',controller.redirectUrl.substringAfter('reference='));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController postCheckout = new GatewayPostCheckoutController();
        postCheckout.completePayment();
        Test.stopTest();
        System.assertEquals(true, postCheckout.redirectUrl.startsWith('/apex'));
    }


    @isTest static void testSimplifyRecurringPaymentFailed(){
        status='fail';
        Contact con = TestDataFactory.newContact();
        Gateway_Detail__c gateway=TestDataFactory.createValidSimplifyCredentials();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
        String requestUrl='https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.amount=15.00;
        reccWrapper.sfProcessingId=con.Id;
        reccWrapper.name=con.FirstName+' '+con.LastName;
        reccWrapper.instalPeriod='Weekly';
        reccWrapper.startDate=Date.today().addDays(1);
        reccWrapper.transactionType=UTILGateway.RECURRINGKEYWORD; 
        reccWrapper.trialPeriod=(reccWrapper.startDate > Date.today())?'DAYS':'NONE';
        reccWrapper.trialDays=(reccWrapper.startDate > Date.today())?SimplifyHelper.getTrialDays(reccWrapper):0;
        reccWrapper.planId='9kpjKqojk';
        Payment_Log__c log = TestDataFactory.createPaymentLog(UTILGateway.SIMPLIFYWORD,reccWrapper.amount,reccWrapper.sfProcessingId,reccWrapper.instalPeriod,reccWrapper.startDate,UTILGateway.RECURRINGKEYWORD,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.accessRecPayPage,'',JSON.serialize(reccWrapper));
        SimplifyManager.isConnected=true;
        Pagereference reference = Page.SimplifyCheckout;
        reference.getParameters().put('reference',log.Id);
        Test.setCurrentPage(reference);
        SimplifyCheckoutController controller = new SimplifyCheckoutController();
        controller.responseToken=TestDataFactory.simplifyRecurringToken();
        controller.completeCheckout();
        Test.startTest();
        SimplifyManager.isConnected=true;
        Pagereference pageRef = Page.GatewayPostCheckout;
        pageRef.getParameters().put('reference',controller.redirectUrl.substringAfter('reference='));
        Test.setCurrentPage(pageRef);
        GatewayPostCheckoutController postCheckout = new GatewayPostCheckoutController();
        postCheckout.completePayment();
        Test.stopTest();
        System.assertEquals(true, postCheckout.redirectUrl.startsWith('/apex'));
    }


    @isTest static void testUpdateCreditCardSuccess(){
        status='pass';
        String actual = MessageHandler.creditCardUpdatSuccesse+'Simplify.';
        Contact con = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        SimplifyManager.isConnected=true;
        String expected = '/apex/Q_Charge__SimplifyUpdateCard?reference=';
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(15,Date.today().addDays(-5),Date.today().addDays(6),'YAFZU6Y40JXHxPrG1PlMK9akmStF+9x0srzzPx+PCOs/vHyjFUzcSSfLVMa76aQ6','Weekly',String.valueOf(con.Id),'','simplify');
        String requestUrl=Url.getSalesforceBaseUrl().toExternalForm()+'/'+recData.Id;

        String result = UpdateCardDetailController.updateCardDetails(recData.Id, requestUrl);
        if(result.contains('/apex')){
            expected+=result.substringAfter('reference=');
        }
        System.assertEquals(expected,result);
        //Payment_Log__c log = TestDataFactory.createPaymentLog(UtilGateway.SIMPLIFYWORD,null,recData.Id,null,null,null,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.updateCardDetails,'','');
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
        Test.StartTest();        
        SimplifyManager.isConnected = true;
        PageReference pageRef = Page.SimplifyUpdateCard;
        pageRef.getParameters().put('reference',result.substringAfter('reference=') );
        Test.setCurrentPage(pageRef);
        UpdateCreditCardController controller = new UpdateCreditCardController();
        controller.responseToken = '22010a49-7638-4662-943d-abdc9158a840';
        controller.updateSimplifyCreditCard();
        Test.StopTest();
        System.assertEquals(actual, controller.result);
        
    }

    @isTest static void testUpdateCreditCardFail(){
        status='fail';
        String actual = MessageHandler.creditCardUpdatSuccesse+'Simplify.';
        Contact con = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        SimplifyManager.isConnected=true;
        String expected = '/apex/Q_Charge__SimplifyUpdateCard?reference=';
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(15,Date.today().addDays(-5),Date.today().addDays(6),'YAFZU6Y40JXHxPrG1PlMK9akmStF+9x0srzzPx+PCOs/vHyjFUzcSSfLVMa76aQ6','Weekly',String.valueOf(con.Id),'','simplify');
        String requestUrl=Url.getSalesforceBaseUrl().toExternalForm()+'/'+recData.Id;

        String result = UpdateCardDetailController.updateCardDetails(recData.Id, requestUrl);
        if(result.contains('/apex')){
            expected+=result.substringAfter('reference=');
        }
        System.assertEquals(expected,result);
        //Payment_Log__c log = TestDataFactory.createPaymentLog(UtilGateway.SIMPLIFYWORD,null,recData.Id,null,null,null,UTILGateway.SIMPLIFYWORD+' '+MessageHandler.updateCardDetails,'','');
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
        Test.StartTest();        
        SimplifyManager.isConnected = true;
        PageReference pageRef = Page.SimplifyUpdateCard;
        pageRef.getParameters().put('reference',result.substringAfter('reference=') );
        Test.setCurrentPage(pageRef);
        UpdateCreditCardController controller = new UpdateCreditCardController();
        controller.responseToken = '22010a49-7638-4662-943d-abdc9158a840';
        controller.updateSimplifyCreditCard();
        Test.StopTest();
        System.assertEquals(true, controller.result.contains('/apex'));
        
    }

    @isTest static void testUpdateRP(){
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'YAFZU6Y40JXHxPrG1PlMK9akmStF+9x0srzzPx+PCOs/vHyjFUzcSSfLVMa76aQ6','Weekly',newCon.Id,'','simplify');
        List<Transaction__c>  transactionList = TestDataFactory.createTransactions(1,'Weekly',Date.today().addDays(3),212,recData.Id);

        String expected = recData.Name +' - '+'updated successfully.';
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
        String installmentDate = String.valueOf(Date.today().addDays(6));
        Test.startTest();
        SimplifyManager.isConnected=true;
        String actual = UpdateRecurringPaymentController.simplifyUpdateRP(recData.Id, 50, 'Monthly', installmentDate, recData.Gateway_Schedule_Id__c);
        Test.stopTest();
        //System.assertEquals(expected, actual); 
        System.assertEquals(true, actual.contains('success')); 
    }


    @isTest static void testCancelRP(){
            Gateway_Detail__c gateway = TestDataFactory.createValidSimplifyCredentials();
            Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly','0031y00000HnkCJAAZ','','Payway');
            List<Transaction__c>  transactionList = TestDataFactory.createTransactions(1,'Weekly',Date.today().addDays(3),212,recData.Id);
            String expected = recData.Name +' - '+'cancelled successfully.';
    
            Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
            Test.startTest();
            SimplifyManager.isConnected=true;
            String actual = CancelRecurringPaymentController.cancelRPSimplify(new List<Recurring_Payment__c>{recData});
            Test.stopTest();
            System.assertEquals(true, actual.contains('success')); 
    }

    @isTest static void refundSimplifyTestSuccess(){
        status='pass';
        Gateway_Detail__c gateway= TestDataFactory.createValidSimplifyCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(212,Date.today(),Date.today().addDays(1),'YAFZU6Y40JXHxPrG1PlMK9akmStF+9x0srzzPx+PCOs/vHyjFUzcSSfLVMa76aQ6','Weekly','0031y00000HnkCJAAZ','XxR8oBgRL','simplify');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
        SimplifyHelper.refundSimplify(new List<Recurring_Payment__c> {rp});
        Test.stopTest();
        System.assertEquals('Refunded', rp.Refund_Status__c);
    }

    @isTest static void refundSimplifyTestFailed(){
        status='fail';
        Gateway_Detail__c gateway= TestDataFactory.createValidSimplifyCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(15,Date.today(),Date.today().addDays(1),'A011Y000002LOWDAAA','Weekly','0031y00000HnkCJAAZ','XxR8oBgRL','simplify');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
        SimplifyHelper.refundSimplify(new List<Recurring_Payment__c> {rp});
        Test.stopTest();
        System.assertEquals('Failed', rp.Refund_Status__c);
    }


    @isTest static void fetchCompletedRPTransactions(){
        status='pass';
        Contact newCon = TestDataFactory.newContact();
        Gateway_Detail__c gateway= TestDataFactory.createValidSimplifyCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(15,Date.today().addDays(-2),Date.today().addDays(-1),'YAFZU6Y40JXHxPrG1PlMK9akmStF+9x0srzzPx+PCOs/vHyjFUzcSSfLVMa76aQ6','Weekly',newCon.Id,'','simplify');
        List<Transaction__c> transactionList=TestDataFactory.createTransactions(1,'Weekly',datetime.newInstance(rp.Next_Installment_Date__c,Time.newInstance(11,00,00,00)),212,rp.Id);
        Test.setMock(HttpCalloutMock.class, new SimplifyMockHttpResponseGenerator());
        Test.startTest();  
        SimplifyManager.isConnected=true;  
        SimplifyHelper.fetchCompletedRPTransactions(new List<Recurring_Payment__c>{rp});
        Test.stopTest();
        System.assertEquals(1, [Select ID from Transaction__c where Recurring_Payment__c=:rp.Id AND Transaction_Status__c='Paid'].size());
    }
}