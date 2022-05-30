@isTest
public class Test_UpdateRecurringPaymentController {

    
    @isTest static void testgetRecurringDetails(){
       
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly','0031y00000HnkCJAAZ','','Payway');
        Test.startTest();
        Recurring_Payment__c rp = UpdateRecurringPaymentController.getRecurringDetails(String.valueOf(recData.Id));
        Test.stopTest();
        System.assertEquals('Weekly', rp.Installment_Period__c);
    }

    
    @isTest static void testinstalmentPeriodList(){
        Test.startTest();
        List<UpdateRecurringPaymentController.ComboClass> cmblist = UpdateRecurringPaymentController.instalmentPeriodList('payway');
        Test.stopTest();
        System.assertEquals('Weekly', cmblist[0].value);

    }
    
    @isTest static void testpaywayUpdateRP(){

        Gateway_Detail__c gateway = TestDataFactory.createValidPaywayCredentials();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly','0031y00000HnkCJAAZ','','Payway');
        Test.setMock(HttpCalloutMock.class, new PaywayMockHttpResponseGenerator());
        String installmentDate = String.valueOf(Date.today().addDays(6));
        Test.startTest();
        String actual = UpdateRecurringPaymentController.paywayUpdateRP(String.valueOf(recData.id), 50, 'Monthly', installmentDate);
        Test.stopTest();
        System.assertEquals(true, actual.contains('updated successfully'));     }

    @isTest static void testezidebitUpdateRPSuccess(){

        Gateway_Detail__c gateway = TestDataFactory.createValidCredentialsWithNoURL();
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(3),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly','0031y00000HnkCJAAZ','','Payway');
        String expected = recData.Name +' - '+'updated successfully.';
        Test.setMock(HttpCalloutMock.class, new EzidebitMockHttpResponseGenerator());
        String installmentDate = String.valueOf(Date.today().addDays(2));
        Test.startTest();
        EzidebitManager.isConnected=true;
        String actual = UpdateRecurringPaymentController.ezidebitUpdateRP(String.valueOf(recData.id), 50, 'Monthly', installmentDate,'8121412312');
        Test.stopTest();
        //System.assertEquals(expected, actual); 
        System.assertEquals(true, actual.contains('success')); 
    }

    @isTest static void testezidebitUpdateRPSuccessFailed(){

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

    @isTest static void testNABTransactUpdateRPSuccess(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidNABCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='nab_transactpayment@gmail.com');
        insert con;
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(6),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.Id),'','nab transact');
        Transaction__c transData = TestDataFactory.createTransaction(String.valueOf(recData.id), 212, Date.today().addDays(6), 'Scheduled','nab transact');
        String installmentDate = String.valueOf(Date.today());
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse()); 
        NABTransactManager.isConnected = true;
        String actual = UpdateRecurringPaymentController.NABTransactUpdateRP(String.valueOf(recData.id), 50, 'Monthly', installmentDate);
        Test.stopTest();
        System.assertEquals(true, actual.contains('updated successfully')); 
    }

    @isTest static void testNABTransactUpdateRPSuccessFutureDate(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidNABCredentials();
        Contact con = new Contact(FirstName='Nate',LastName='Angus',Email='nab_transactpayment@gmail.com');
        insert con;
        Recurring_Payment__c recData = TestDataFactory.createRecurringPayment(212,Date.today().addDays(-5),Date.today().addDays(6),'0lSf8eQDSx8BVMox1MSn970YSebq31ELRT3yUb+n4vU=','Weekly',String.valueOf(con.Id),'','nab transact');
        Transaction__c transData = TestDataFactory.createTransaction(String.valueOf(recData.id), 212, Date.today().addDays(6), 'Scheduled','nab transact');
        String installmentDate = String.valueOf(Date.today().addDays(6));
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse()); 
        NABTransactManager.isConnected = true;
        String actual = UpdateRecurringPaymentController.NABTransactUpdateRP(String.valueOf(recData.id), 50, 'Monthly', installmentDate);
        Test.stopTest();
        System.assertEquals(true, actual.contains('updated successfully')); 
    }

}