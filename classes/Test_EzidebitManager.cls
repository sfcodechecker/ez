@isTest
public class Test_EzidebitManager {
    
    /* @isTest static void hitEndpointXMLTest(){
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        
        HttpResponse res=EzidebitManager.hitEndpointXML('https://api.demo.ezidebit.com.au/v3-5/nonpci', 'GET', 'https://px.ezidebit.com.au/INonPCIService/GetCustomerList', EzidebitManager.XMLBodyBuilder('getCustomerList', '', '', '', '2AF528C7-1A65-44D9-B546-3382F283BDDA', ''));
        System.assertEquals(200, res.getStatusCode()); 
        String actual=res.getBody();
        String expected='<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">'+
        '<s:Body>'+
        '<GetCustomerListResponse xmlns="https://px.ezidebit.com.au/">'+
        '<GetCustomerListResult xmlns:i="http://www.w3.org/2001/XMLSchema-instance">'+
        '<Data i:nil="true"/>'+
        '<Error>102</Error>'+
        '<ErrorMessage>Invalid DigitalKey.</ErrorMessage>'+
        '</GetCustomerListResult>'+
        '</GetCustomerListResponse>'+
        '</s:Body>'+
        '</s:Envelope>';
        System.assertEquals(expected, actual);
        
    }
    @isTest static void authenticationTest()
    {
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c='C4AEFBD5-2A4F-49CB-71CC-14490D6352AD',Client_Key__c='6782F49B-3669-4C07-C11E-85469A0DA1EA',isSandbox__c=true,Name__c='ezidebit');
        String resp=EzidebitManager.CheckCredentials(Gateway);
        System.assertNotEquals('valid', resp);
        
    }
    @isTest static void XMLGeneratorTest(){
        
        String xmlresponse=EzidebitManager.XMLBodyBuilder('getCustomerList', '', '', '', '6782F49B-3669-4C07-C11E-85469A0DA1EA', '');
        String expected='<?xml version="1.0"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:px="https://px.ezidebit.com.au/">'+
        '<soapenv:Header></soapenv:Header>'+
        '<soapenv:Body>'+
        '<px:GetCustomerList>'+
        '<px:DigitalKey>6782F49B-3669-4C07-C11E-85469A0DA1EA</px:DigitalKey>'+
        '<px:EziDebitCustomerID></px:EziDebitCustomerID>'+
        '<px:YourSystemReference></px:YourSystemReference>'+
        '<px:CustomerStatus>ALL</px:CustomerStatus>'+
        '<px:OrderBy>EzidebitCustomerID</px:OrderBy>'+
        '<px:Order>ASC</px:Order>'+
        '<px:PageNumber>1</px:PageNumber>'+
        '</px:GetCustomerList>'+
        '</soapenv:Body>'+
        '</soapenv:Envelope>';
        System.assertEquals(expected, xmlresponse);
    }
    @isTest static void accessHostedPageTest(){
        String actual=EzidebitManager.accessHostedPage('0039D00000DPnJ0QAL', 25.00);
        String expected='/apex/Q_Charge__EzidebitCheckout?recordId=0039D00000DPnJ0QAL&amount=25.00&chargetype=oneoff';
        System.assertEquals(expected, actual);
    }
    
    
    @isTest static void accessEddrPageWithoutURLTest(){
        Blob CryptoKey = Blob.valueOf('@U!cKCharGeAc0n$');
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c=EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', CryptoKey, Blob.valueOf('C4AEFBD5-2A4F-49CB-71CC-14490D6352AD'))),Client_Key__c=EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', CryptoKey, Blob.valueOf('6782F49B-3669-4C07-C11E-85469A0DA1EA'))),isSandbox__c=true,Name__c='ezidebit');
        insert Gateway;
        Payment_Log__c newLog = new Payment_Log__c(Amount__c=12,Action__c='Ezidebit - Eddr Page Accessed',Processing_Record_Id__c='0039D00000DPnJ0QAL',Charge_Type__c='Recurring');
        insert newLog;
        String actual = EzidebitManager.accessEddrPage('0039D00000DPnJ0QAL', 12, Date.today(), 'Weekly', '1', newLog.Id+''+String.valueOf(Datetime.now().getTime()));
        String expected = '/apex/Q_Charge__EzidebitRPCheckout?&id=0039D00000DPnJ0QAL&ramount=12&rdate=2021-11-15 00:00:00&freq=1&dur=1&uref=a011y000002uq7bAAA1636956289893&chargetype=recurring';
        System.assertNotEquals(expected, actual);
    }
    
    @isTest static void accessEddrPageWithURLTest(){
        Gateway_Detail__c gateway= TestDataFactory.createValidEzidebitCredentials();
        Payment_Log__c newLog = new Payment_Log__c(Amount__c=12,Action__c='Ezidebit - Eddr Page Accessed',Processing_Record_Id__c='0039D00000DPnJ0QAL',Charge_Type__c='Recurring');
        insert newLog;
        String uref=newLog.Id+''+String.valueOf(Datetime.now().getTime());
        String actual = EzidebitManager.accessEddrPage('0039D00000DPnJ0QAL', 12, Date.today(), 'Weekly', '1', uref);
        String expected = '/apex/Q_Charge__EzidebitRPCheckout?&id=0039D00000DPnJ0QAL&ramount=12&rdate=2021-11-16 00:00:00&freq=1&dur=1&uref='+uref+'&chargetype=recurring';
        System.assertNotEquals(expected, actual);
    }
    
    @isTest static void accessEddrPagePrevDateTest(){
        Blob CryptoKey = Blob.valueOf('@U!cKCharGeAc0n$');
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c=EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', CryptoKey, Blob.valueOf('C4AEFBD5-2A4F-49CB-71CC-14490D6352AD'))),Client_Key__c=EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', CryptoKey, Blob.valueOf('6782F49B-3669-4C07-C11E-85469A0DA1EA'))),isSandbox__c=true,Name__c='ezidebit',Schedule_Page_URL__c='https://demo.ezidebit.com.au/webddr/Request.aspx?a=C4AEFBD5-2A4F-49CB-71CC-14490D6352AD&debits=4');
        insert Gateway;
        Payment_Log__c newLog = new Payment_Log__c(Amount__c=12,Action__c='Ezidebit - Eddr Page Accessed',Processing_Record_Id__c='0039D00000DPnJ0QAL',Charge_Type__c='Recurring');
        insert newLog;
        String actual = EzidebitManager.accessEddrPage('0039D00000DPnJ0QAL', 12, Date.today().addDays(-1), 'Weekly', '1', newLog.Id+''+String.valueOf(Datetime.now().getTime()));
        String expected = '/apex/Q_Charge__EzidebitRPCheckout?&id=0039D00000DPnJ0QAL&ramount=12&rdate=2021-11-15 00:00:00&freq=1&dur=1&uref=a011y000002uq7bAAA1636956289893&chargetype=recurring';
        System.assertNotEquals(expected, actual);
    }
    
    @isTest static void accessEddrPagePastSixTest(){
        Blob CryptoKey = Blob.valueOf('@U!cKCharGeAc0n$');
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c=EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', CryptoKey, Blob.valueOf('C4AEFBD5-2A4F-49CB-71CC-14490D6352AD'))),Client_Key__c=EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', CryptoKey, Blob.valueOf('6782F49B-3669-4C07-C11E-85469A0DA1EA'))),isSandbox__c=true,Name__c='ezidebit',Schedule_Page_URL__c='https://demo.ezidebit.com.au/webddr/Request.aspx?a=C4AEFBD5-2A4F-49CB-71CC-14490D6352AD&debits=4');
        insert Gateway;
        Payment_Log__c newLog = new Payment_Log__c(Amount__c=12,Action__c='Ezidebit - Eddr Page Accessed',Processing_Record_Id__c='0039D00000DPnJ0QAL',Charge_Type__c='Recurring');
        insert newLog;
        String actual = EzidebitManager.accessEddrPage('0039D00000DPnJ0QAL', 12, Date.today(), 'Weekly', '1', newLog.Id+''+String.valueOf(Datetime.now().getTime()));
        String expected = '/apex/Q_Charge__EzidebitRPCheckout?&id=0039D00000DPnJ0QAL&ramount=12&rdate=2021-11-15 00:00:00&freq=1&dur=1&uref=a011y000002uq7bAAA1636956289893&chargetype=recurring';
        System.assertNotEquals(expected, actual);
    }
    
    @isTest static void fetchCompletedRPTest(){
        Gateway_Detail__c gateway= TestDataFactory.createValidEzidebitCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(212,date.newInstance(2021,10,25),date.newInstance(2021,10,26),'A011Y000002LOWDAAA','Weekly','0031y00000HnkCJAAZ','','Ezidebit');
        List<Transaction__c> transactionList=TestDataFactory.createTransactions(1,'Weekly',datetime.newInstance(rp.Next_Installment_Date__c,Time.newInstance(11,00,00,00)),212,rp.Id);
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Test.startTest();    
        EzidebitManager.fetchCompletedRPTransactions(rp);
        Test.stopTest();
        System.assertEquals(1, [Select ID from Transaction__c where Recurring_Payment__c=:rp.Id AND Transaction_Status__c='SUCCESSFUL'].size());
    }
    
    
    @isTest static void refundEzidebitTest(){
        Gateway_Detail__c gateway= TestDataFactory.createValidEzidebitCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(212,date.newInstance(2021,10,25),date.newInstance(2021,10,26),'A011Y000002LOWDAAA','Weekly','0031y00000HnkCJAAZ','44601940','Ezidebit');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        EzidebitManager.refundEzidebit(rp);
        Test.stopTest();
        System.assertEquals('REFUNDED', rp.Refund_Status__c);
    }
    
    @isTest static void changeCustomerStatusTest(){
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        EzidebitRPWrapper wrapper=new EzidebitRPWrapper();
        wrapper.amount=12;
        wrapper.customerId='2631164';
        wrapper.frequency='1';
        wrapper.fullName='Nate Angus';
        wrapper.setupDate=Date.today();
        wrapper.startDate=Date.today().addDays(1);
        wrapper.systemId='a011y000002urUrAAI1637048921068';
        wrapper.transactionId=null;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        String result=EzidebitManager.changeCustomerStatus(wrapper);
        Test.stopTest();
        System.assertEquals('Approved', result);
    }
    
    
    
    @isTest static void chargeNowEzidebitSchedule(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String result=ChargeNowController.EzidebitScheduleService('0031y00000HnkCJAAZ', 12,'Weekly',String.valueOf(Date.today().addDays(1)));
        //System.assertEquals('/apex/Q_Charge__EzidebitRPCheckout?id=0031y00000HnkCJAAZ&ramount=12&freq=1&dur=1&rdate='+String.valueOf(Date.today().addDays(1))+'&uref=&chargetype=recurring', result);
        System.assertEquals(1,[Select Id from Payment_Log__c where Action__c='Ezidebit - Eddr Page Accessed'].size());
    }
    
    */
    @isTest static void chargeNowEzidebitOneOff(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String expected = '/apex/Q_Charge__EzidebitCheckout?reference=';
        String recordId='';
        String requestUrl = 'https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        String result=ChargeNowController.EzidebitOneOffService('0030p00000XoQSXAA3', 12 ,requestUrl);
        if(result.contains('/apex')){
            recordId=result.substringAfter('reference=');
        }
        expected+=recordId;
        System.assertEquals(expected, result);
    }
    
    @isTest static void chargeNowEzidebitOneOffAmountNullTest(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String expected = MessageHandler.wentWrongCatchMessage;
        String requestUrl = 'https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        String result=ChargeNowController.EzidebitOneOffService('0030p00000XoQSXAA3', null ,requestUrl);
        System.assertEquals(expected, result);
    }
    
    @isTest static void chargeNowEzidebitOneOffRecordNullTest(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String expected = MessageHandler.wentWrongCatchMessage;
        String requestUrl = 'https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        String result=ChargeNowController.EzidebitOneOffService(null, 11000 ,requestUrl);
        System.assertEquals(expected, result);
    }
    
    @isTest static void chargeNowEzidebitSchedule(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String expected='/apex/Q_Charge__EzidebitRPCheckout?reference=';
        String recordId='';
        Contact con = TestDataFactory.newContact();
        String requestUrl='https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        String result=ChargeNowController.EzidebitScheduleService(con.Id,12.00,'Weekly',String.valueOf(Date.today().addDays(1)),requestUrl);
        if(result.contains('/apex')){
            recordId=result.substringAfter('reference=');
        }
        expected+=recordId;
        System.assertEquals(expected, result);
        
    }
    
    
    @isTest static void chargeNowEzidebitScheduleYesterdayTest(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String expected=MessageHandler.prevStartDate;
        String recordId='';
        Contact con = TestDataFactory.newContact();
        String requestUrl='https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        String result=ChargeNowController.EzidebitScheduleService(con.Id,12.00,'Weekly',String.valueOf(Date.today().addDays(-1)),requestUrl);
        System.assertEquals(expected, result);
        
    }
    
    @isTest static void chargeNowEzidebitScheduleWeekendTest(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String expected=MessageHandler.ezidebitWeekendSetup;
        String recordId='';
        Contact con = TestDataFactory.newContact();
        String requestUrl='https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        String weekend = 'Saturday,Sunday';
        String day='';
        Integer counter=0;
        do{
            Date weekdate = Date.today().addDays(counter);
            day = Datetime.newInstance(weekdate.year(),weekdate.month(),weekdate.day()).format('EEEE');
            counter++;
        }while(!weekend.contains(day));
        String result=ChargeNowController.EzidebitScheduleService(con.Id,12.00,'Weekly',String.valueOf(Date.today().addDays(counter)),requestUrl);
        System.assertEquals(expected, result);
        
    }
    
    @isTest static void chargeNowEzidebitScheduleNullTest(){
        
        Gateway_Detail__c gateway=TestDataFactory.createValidEzidebitCredentials();
        String expected=MessageHandler.prevStartDate;
        String recordId='';
        Contact con = TestDataFactory.newContact();
        String requestUrl='https://business-energy-4635-dev-ed.lightning.force.com/lightning/r/Contact/0030p00000XoQSXAA3/view';
        String result=ChargeNowController.EzidebitScheduleService(con.Id,null,'Weekly',String.valueOf(Date.today().addDays(-1)),requestUrl);
        System.assertEquals(expected, result);
    }
    
    @isTest static void testezidebitUpdateRPSuccess(){
        
        Gateway_Detail__c gateway = TestDataFactory.createValidCredentialsWithNoURL();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly','0031y00000HnkCJAAZ','','Payway');
        String expected = recData.Name +' - '+'updated successfully.';
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        String installmentDate = String.valueOf(Date.today().addDays(1));
        Test.startTest();
        EzidebitManager.isConnected=true;
        String actual = UpdateRecurringPaymentController.ezidebitUpdateRP(String.valueOf(recData.id), 50, 'Monthly', installmentDate,'8121412312');
        Test.stopTest();
        //System.assertEquals(expected, actual); 
        System.assertEquals(true, actual.contains('success')); 
    }
    
    @isTest static void testezidebitUpdateRPFailed(){
        
        Gateway_Detail__c gateway = TestDataFactory.createValidCredentialsWithNoURL();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly','0031y00000HnkCJAAZ','','Payway');
        String expected = recData.Name +' - '+'updated successfully.';
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        String installmentDate = String.valueOf(Date.today().addDays(6));
        Test.startTest();
        String actual = UpdateRecurringPaymentController.ezidebitUpdateRP(String.valueOf(recData.id), 50, 'Monthly', installmentDate,'8121412312');
        Test.stopTest();
        //System.assertEquals(expected, actual); 
        System.assertEquals(true, actual.contains('failed')); 
    }

    @isTest static void testezidebitCancelRPSuccess(){
        Gateway_Detail__c gateway = TestDataFactory.createValidCredentialsWithNoURL();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly','0031y00000HnkCJAAZ','','Payway');
        List<Transaction__c>  transactionList = TestDataFactory.createTransactions(1,'Weekly',Date.today().addDays(3),212,recData.Id);
        String expected = recData.Name +' - '+'cancelled successfully.';

        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Test.startTest();
        EzidebitManager.isConnected=true;
        String actual = CancelRecurringPaymentController.cancelRPEzidebit(new List<Recurring_Payment__c>{recData});
        Test.stopTest();
        System.assertEquals(true, actual.contains('success')); 
    }

    @isTest static void testezidebitCancelRPFailed(){
        Gateway_Detail__c gateway = TestDataFactory.createValidCredentialsWithNoURL();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly','0031y00000HnkCJAAZ','','Payway');
        List<Transaction__c>  transactionList = TestDataFactory.createTransactions(1,'Weekly',Date.today().addDays(3),212,recData.Id);
        String expected = recData.Name +' - '+'cancelled successfully.';

        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Test.startTest();
        String actual = CancelRecurringPaymentController.cancelRPEzidebit(new List<Recurring_Payment__c>{recData});
        Test.stopTest();
        System.assertEquals(false, actual.contains('success')); 
    }
    
    @isTest static void refundEzidebitTestSuccess(){
        Gateway_Detail__c gateway= TestDataFactory.createValidEzidebitCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(212,Date.today(),Date.today().addDays(1),'A011Y000002LOWDAAA','Weekly','0031y00000HnkCJAAZ','44601940','Ezidebit');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        EzidebitHelper.refundEzidebit(new List<Recurring_Payment__c> {rp});
        Test.stopTest();
        System.assertEquals('REFUNDED', rp.Refund_Status__c);
    }

    @isTest static void refundEzidebitTestFailed(){
        Gateway_Detail__c gateway= TestDataFactory.createValidEzidebitCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(15,Date.today(),Date.today().addDays(1),'A011Y000002LOWDAAA','Weekly','0031y00000HnkCJAAZ','44601995','Ezidebit');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        EzidebitHelper.refundEzidebit(new List<Recurring_Payment__c> {rp});
        Test.stopTest();
        System.assertEquals('Failed', rp.Refund_Status__c);
    }

    @isTest static void fetchCompletedRPTest(){
        Gateway_Detail__c gateway= TestDataFactory.createValidEzidebitCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-2),Date.today().addDays(-1),'A011Y000002LOWDAAA','Weekly','0031y00000HnkCJAAZ','','Ezidebit');
        List<Transaction__c> transactionList=TestDataFactory.createTransactions(1,'Weekly',datetime.newInstance(rp.Next_Installment_Date__c,Time.newInstance(11,00,00,00)),212,rp.Id);
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Test.startTest();  
        EzidebitManager.detachedReason=null;  
        EzidebitHelper.fetchCompletedRPTransactions(new List<Recurring_Payment__c>{rp});
        Test.stopTest();
        System.assertEquals(1, [Select ID from Transaction__c where Recurring_Payment__c=:rp.Id AND Transaction_Status__c='SUCCESSFUL'].size());
    }

    @isTest static void fetchCompletedRPDeletedFtureTransactionsTest(){
        Gateway_Detail__c gateway= TestDataFactory.createValidEzidebitCredentials();
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-2),Date.today().addDays(-1),'A011Y000002LOWDAAA','Weekly','0031y00000HnkCJAAZ','','Ezidebit');
        List<Transaction__c> transactionList=TestDataFactory.createTransactions(2,'Weekly',datetime.newInstance(rp.Next_Installment_Date__c,Time.newInstance(11,00,00,00)),212,rp.Id);
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        Test.startTest();  
        EzidebitManager.detachedReason=null;  
        EzidebitHelper.fetchCompletedRPTransactions(new List<Recurring_Payment__c>{rp});
        Test.stopTest();
        System.assertEquals(1, [Select ID from Transaction__c where Recurring_Payment__c=:rp.Id AND Transaction_Status__c='SUCCESSFUL'].size());
    }
    
}