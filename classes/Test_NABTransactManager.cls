@isTest
public class Test_NABTransactManager {

    @isTest static void testhitEndpointXML()
    { 
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        HttpResponse res = NABTransactManager.hitEndpointXML('https://demo.transact.nab.com.au/xmlapi/payment', 'GET', NABTransactManager.authenticationXMLWriter('XYZ0010', 'abcd1234'));
        String actual = res.getBody();
        String expected = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><NABTransactMessage><MessageInfo><messageID>20211611033826</messageID><messageTimestamp>20211611033826000000+000</messageTimestamp><apiVersion>xml-4.2</apiVersion></MessageInfo><RequestType>Echo</RequestType><Status><statusCode>000</statusCode><statusDescription>Normal</statusDescription></Status></NABTransactMessage>';
        system.assertEquals(true, actual.contains('Normal'));
    }
    
    @isTest static void teststoreCredentials(){
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse()); 
        String response=NABTransactManager.validateCredentials(Gateway, false);
        Test.stopTest();
        System.assertEquals('valid',response);
    }
    
    @isTest static void testCheckCredentials(){
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials(); 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        String response=NABTransactManager.PostCredentials(Gateway);
        Test.stopTest();
        System.assertEquals('valid',response);
    }

    @isTest static void testValidationAmont(){
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials();  
        TransactionWrapper transWrapper = new TransactionWrapper();
        transWrapper.tokenValue = '2441083982623330'; 
        transWrapper.transactionId = '123';
        transWrapper.amount = 100;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        NABTransactManager.validateCreditCard(transWrapper);
        Test.stopTest();
        system.assertEquals(1,[Select Id from Gateway_Detail__c Where Name__c = 'nab_transact'].size());
    }

    @isTest static void testCurrentTranasction(){
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials(); 
        TransactionWrapper transWrapper = new TransactionWrapper();
        transWrapper.tokenValue = '2441083982623330'; 
        transWrapper.transactionId = '123';
        transWrapper.amount = 500;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        NABTransactManager.chargeCurrentTransaction(transWrapper);
        Test.stopTest();
        system.assertEquals(1,[Select Id from Gateway_Detail__c Where Name__c = 'nab_transact'].size());
    }

    @isTest static void testrefundValidationAmount(){       
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials();
        List<Recurring_Payment__c> rpList = new List<Recurring_Payment__c>();
        RecurringWrapper recurringWrapper = new RecurringWrapper();
        recurringWrapper.transactionreference = 'a011y000002upJ4AAI';
        recurringWrapper.refundId = '237822';
        recurringWrapper.sfProcessingId = '0031y00000HnkCJAAZ';
        Recurring_Payment__c rp = TestDataFactory.createRecurringPayment(1.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Fortnightly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        rpList.add(rp);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        NABTransactHelper.refundValidationAmount(rpList);
        Test.stopTest();
        system.assertEquals('Refunded', rp.Refund_Status__c);
    }

    @isTest static void testupdateTransactionBatchProcess(){
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c RP = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        Transaction__c trans = TestDataFactory.createTransaction(RP.Id, 45.00, datetime.newInstance(RP.Next_Installment_Date__c,Time.newInstance(11,00,00,00)), 'Scheduled', 'nab transact');
        RecurringWrapper recurWrap = new RecurringWrapper();
        recurWrap.sfProcessingId = RP.Id;
        recurWrap.amount = 45.00;
        recurWrap.instalPeriod = 'Fortnightly';
        recurWrap.startDate = date.newInstance(2021,11,14);
        recurWrap.tokenValue = 'ncg60VZ8ydY9ZcYWBG1x04unHGllQonsPo92ZhrNVuI2yAfbKX6LGl3wyr10qhur';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        NABTransactHelper.updateTransactionBatchProcess(true, false, null, null, recurWrap);
        Test.stopTest();
        system.assertEquals(1, [Select Id, Name From Transaction__c Where Transaction_Status__c = 'Paid'].size());
    }

    @isTest static void testnabtransctCancelRPSuccess(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        List<Transaction__c>  transactionList = TestDataFactory.createTransactions(1,'Weekly',Date.today().addDays(3),212,recData.Id);
        String expected = recData.Name +' - '+'cancelled successfully.';

        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        Test.startTest();
        NABTransactManager.isConnected=true;
        String actual = CancelRecurringPaymentController.cancelNABTransactRP(new List<Recurring_Payment__c>{recData});
        Test.stopTest();
        System.assertEquals(true, actual.contains('success')); 
    }

    @isTest static void testgetRPRecords(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        List<Transaction__c>  transactionList = TestDataFactory.createTransactions(1,'Weekly',Date.today().addDays(3),212,recData.Id);

        Test.startTest();
        NABTransactManager.isConnected=true;
        CancelRecurringPaymentController.getRecurringRecord(String.valueOf(recData.Id));
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Recurring_Payment__c where Id =: recData.Id].size()); 
    }

    @isTest static void testcancelTransaction(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        Transaction__c trans = TestDataFactory.createTransaction(recData.Id, 45.00, datetime.newInstance(recData.Next_Installment_Date__c,Time.newInstance(11,00,00,00)), 'Failed', 'nab transact');

        Test.startTest();
        NABTransactManager.isConnected=true;
        CancelTransactionController.cancelCurrentTransaction(String.valueOf(trans.Id));
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Recurring_Payment__c where Id =: recData.Id].size()); 
    }

    @isTest static void testgetTransactionDetails(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        Transaction__c trans = TestDataFactory.createTransaction(recData.Id, 45.00, datetime.newInstance(recData.Next_Installment_Date__c,Time.newInstance(11,00,00,00)), 'Failed', 'nab transact');

        Test.startTest();
        NABTransactManager.isConnected=true;
        CancelTransactionController.getTransactionDetails(String.valueOf(trans.Id));
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Recurring_Payment__c where Id =: recData.Id].size()); 
    }

    @isTest static void testisGatewayConnected(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        Transaction__c trans = TestDataFactory.createTransaction(recData.Id, 45.00, datetime.newInstance(recData.Next_Installment_Date__c,Time.newInstance(11,00,00,00)), 'Failed', 'nab transact');

        Test.startTest();
        NABTransactManager.isConnected=true;
        CancelTransactionController.isGatewayConnected('nab_transact');
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Recurring_Payment__c where Id =: recData.Id].size()); 
    }

    @isTest static void testRetryTransaction(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        Transaction__c trans = TestDataFactory.createTransaction(recData.Id, 45.00, datetime.newInstance(recData.Next_Installment_Date__c,Time.newInstance(11,00,00,00)), 'Failed', 'nab transact');

        Test.startTest();
        NABTransactManager.isConnected=true;
        RetryTransactionController.retryCurrentTransaction(String.valueOf(trans.Id));
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Recurring_Payment__c where Id =: recData.Id].size()); 
    }

    @isTest static void testgetTransactionDetailsRetry(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        Transaction__c trans = TestDataFactory.createTransaction(recData.Id, 45.00, datetime.newInstance(recData.Next_Installment_Date__c,Time.newInstance(11,00,00,00)), 'Failed', 'nab transact');

        Test.startTest();
        NABTransactManager.isConnected=true;
        RetryTransactionController.getTransactionDetails(String.valueOf(trans.Id));
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Recurring_Payment__c where Id =: recData.Id].size()); 
    }

    @isTest static void testisGatewayConnectedRetry(){
        Gateway_Detail__c gateway = TestDataFactory.createValidNABCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'nab transact');
        Transaction__c trans = TestDataFactory.createTransaction(recData.Id, 45.00, datetime.newInstance(recData.Next_Installment_Date__c,Time.newInstance(11,00,00,00)), 'Failed', 'nab transact');

        Test.startTest();
        NABTransactManager.isConnected=true;
        RetryTransactionController.isGatewayConnected('nab_transact');
        Test.stopTest();
        System.assertEquals(1, [Select Id, Name from Recurring_Payment__c where Id =: recData.Id].size()); 
    }

    /*
    @isTest static void testvalidateCreditCard(){        
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        String expected = NABTransactManager.validateCreditCard('2441083982623330', 'a011y000002urPRAAY');
        Test.stopTest();
        expected = expected.trim();
        system.assertEquals('Normal&TransactionId=252737', expected);
    }


    @isTest static void testcreateHostedPage(){
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials();

        String actual = NABTransactManager.createHostedPage('0031y00000HnkCJAAZ', 23, 'abcdefghi', null, null, 'OneOff');
        String expected = '/apex/Q_Charge__NABTransactCheckout?recordId=0031y00000HnkCJAAZ&amount=2300&reference=abcdefghi&showAmount=23&value=valid&endPoint=https://demo.transact.nab.com.au/directpostv2/authorise&InstallPeriod=null&startDate=null&chargeType=OneOff';
        system.assertEquals(expected, actual);
    }

    @isTest static void testoneOffCheckOutComplete(){
        Test.startTest();
        NABTransactManager.oneOffCheckOutComplete('248727', 'Payment is charged successfully.', '0031y00000HnkCJAAZ', '23', 'https://demo.transact.nab.com.au/directpostv2/authorise', 'Approved');
        system.assertEquals(1, [select Id, Transaction_Id__c from Transaction__c where Transaction_Id__c = '248727'].size());
        Test.stopTest();
    }

    @isTest static void testcreateRecurringPayment(){
        Test.startTest();
        NABTransactManager.createRecurringPayment('0031y00000HnkCJAAZ', '2021-11-21', 'Fortnightly', '6545', 'abcdefghijkl', '248727', '2441083982623330');
        system.assertEquals(1, [select Id, Amount__c from Recurring_Payment__c where Amount__c = 6545.00].size());
        system.assertEquals(1, [select Id, Recurring_Payment__c from Transaction__c where Amount__c = 6545.00].size());
        Test.stopTest();
    }

    @isTest static void testupdateTransactionBatchProcess(){
        Recurring_Payment__c RP = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Fortnightly', '0031y00000HnkCJAAZ', '237822', 'NAB Transact');
        Transaction__c trans = TestDataFactory.createTransactionNAB(RP.Id, 45.00, datetime.newInstance(RP.Next_Installment_Date__c,Time.newInstance(11,00,00,00)));
        Test.startTest();
        Integer numberTransactions = NABTransactManager.updateTransactionBatchProcess(trans.Id, 'Normal').size();
        Test.stopTest();
        system.assertEquals(2, numberTransactions);
    }

    @isTest static void testupdateRecurringPayment(){
        Recurring_Payment__c RP = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'NAB Transact');
        Transaction__c trans = TestDataFactory.createTransactionNAB(RP.Id, 45.00, datetime.newInstance(RP.Next_Installment_Date__c,Time.newInstance(11,00,00,00)));
        Test.startTest();
        Recurring_Payment__c RPUpdate = NABTransactManager.updateRecurringPayment(RP.Id, trans.Id, true);
        Test.stopTest();
        system.assertEquals(1, [Select Id from Recurring_Payment__c where Id =: RP.Id].size());
    }

    @isTest static void testcreateNewTransaction(){
        Recurring_Payment__c RP = TestDataFactory.createRecurringPayment(45.00, date.newInstance(2021,11,13), date.newInstance(2021,11,14), 'a011y000002upJ4AAI', 'Yearly', '0031y00000HnkCJAAZ', '237822', 'NAB Transact');
        Transaction__c trans = TestDataFactory.createTransactionNAB(RP.Id, 45.00, datetime.newInstance(RP.Next_Installment_Date__c,Time.newInstance(11,00,00,00)));
        Test.startTest();
        Transaction__c transactions = NABTransactManager.createNewTransaction(RP.Id, trans.Id);
        Test.stopTest();
        system.assertEquals(1, [Select Id,Recurring_Payment__c from Transaction__c where Recurring_Payment__c =: RP.Id].size());
    }
    
    @isTest static void testCheckExistingCredentails(){
        Gateway_Detail__c gateway= TestDataFactory.createValidNABCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        NABTransactManager.CheckExistingCredentails();
        Test.stopTest();
        system.assertEquals(1, [select Id from Gateway_Detail__c where Name__c = 'nab_transact'].size());
    }
    */
}