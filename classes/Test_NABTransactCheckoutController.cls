@isTest
public class Test_NABTransactCheckoutController {
    
    @isTest static void testApprovePayment(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidNABCredentials();
        Contact con = TestDataFactory.createContact(); 
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        String checkUrl = ChargeNowController.NABTransactOneOffService(con.Id, 6.00); 
        
        // Open the checkout page accept the card details
        PageReference checkout = Page.NABTransactCheckout; 
        Test.setCurrentPage(checkout); 
        checkout.getParameters().put('reference', checkUrl.substringAfter('reference='));
        NABTransactCheckoutController nabcontroller = new NABTransactCheckoutController();
        String processingUrl = nabcontroller.resultURL;         
        
        // Process the card details only spinner no user interaction.
        PageReference ProcessCard = Page.GatewayPostCheckout; 
        Test.setCurrentPage(ProcessCard);  
        ProcessCard.getParameters().put('txnid', '123');
        ProcessCard.getParameters().put('restext', 'Approved');
        ProcessCard.getParameters().put('reference', processingUrl.substringAfter('reference='));
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();  
        controller.completePayment();
        String receiptUrl = controller.redirectUrl;
        
        // Shows the receipt of the transaction.
        PageReference receipt = Page.GatewayReceiptPage; 
        Test.setCurrentPage(receipt);                         
        receipt.getParameters().put('reference', receiptUrl.substringAfter('reference='));
        GatewayReceiptPageController receiptController = new GatewayReceiptPageController();  
        receiptController.retryTransaction(); 
        Test.stopTest(); 

        System.assertEquals('Payment is charged successfully.', receiptController.paymentResponse);                      
    }


    @isTest static void testRejectedPayment(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidNABCredentials();
        Contact con = TestDataFactory.createContact(); 
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        String checkUrl = ChargeNowController.NABTransactOneOffService(con.Id, 6.00); 
        
        // Open the checkout page accept the card details
        PageReference checkout = Page.NABTransactCheckout; 
        Test.setCurrentPage(checkout); 
        checkout.getParameters().put('reference', checkUrl.substringAfter('reference='));
        NABTransactCheckoutController nabcontroller = new NABTransactCheckoutController();
        String processingUrl = nabcontroller.resultURL;         
        
        // Process the card details only spinner no user interaction.
        PageReference ProcessCard = Page.GatewayPostCheckout; 
        Test.setCurrentPage(ProcessCard);  
        ProcessCard.getParameters().put('txnid', '123');
        ProcessCard.getParameters().put('restext', 'Invalid card number');
        ProcessCard.getParameters().put('reference', processingUrl.substringAfter('reference='));
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();  
        controller.completePayment();
        String receiptUrl = controller.redirectUrl;
        
        // Shows the receipt of the transaction.
        PageReference receipt = Page.GatewayReceiptPage; 
        Test.setCurrentPage(receipt);                         
        receipt.getParameters().put('reference', receiptUrl.substringAfter('reference='));
        GatewayReceiptPageController receiptController = new GatewayReceiptPageController();  
        receiptController.retryTransaction(); 
        Test.stopTest();              

        System.assertEquals('Payment is not charged due to Invalid card number.', receiptController.paymentResponse); 
        
    }

    @isTest static void testApprovePaymentRP(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidNABCredentials();
        Contact con = TestDataFactory.createContact(); 
        String installmentDate = String.valueOf(Date.today().addDays(6));
        
        String checkUrl = ChargeNowController.NABTransactScheduleService(String.valueOf(con.Id), 6.00, 'Weekly',installmentDate); 
        
        // Open the checkout page accept the card details
        PageReference checkout = Page.NABTransactCheckout; 
        Test.setCurrentPage(checkout); 
        checkout.getParameters().put('reference', checkUrl.substringAfter('reference='));
        NABTransactCheckoutController nabcontroller = new NABTransactCheckoutController();
        String processingUrl = nabcontroller.resultURL;         
        
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        // Process the card details only spinner no user interaction.
        PageReference ProcessCard = Page.GatewayPostCheckout; 
        Test.setCurrentPage(ProcessCard);  
        ProcessCard.getParameters().put('refid', '123');
        ProcessCard.getParameters().put('token', '2441083982623330');
        ProcessCard.getParameters().put('strestext', 'Successful');
        ProcessCard.getParameters().put('pan', '424242...242');
        ProcessCard.getParameters().put('expirydate', '52022');
        ProcessCard.getParameters().put('nameOnCard', 'Test demo');
        ProcessCard.getParameters().put('reference', processingUrl.substringAfter('reference='));
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();  
        controller.completePayment();
        String receiptUrl = controller.redirectUrl;
        
        // Shows the receipt of the transaction.
        PageReference receipt = Page.GatewayReceiptPage; 
        Test.setCurrentPage(receipt);                         
        receipt.getParameters().put('reference', receiptUrl.substringAfter('reference='));
        GatewayReceiptPageController receiptController = new GatewayReceiptPageController();  
        receiptController.retryTransaction(); 
        Test.stopTest(); 

        System.assertEquals('Recurring Payment is setup successfully.', receiptController.paymentResponse);                      
    }

    @isTest static void testApprovePaymentRPToday(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidNABCredentials();
        Contact con = TestDataFactory.createContact(); 
        String installmentDate = String.valueOf(Date.today());
        
        String checkUrl = ChargeNowController.NABTransactScheduleService(String.valueOf(con.Id), 6.00, 'Yearly',installmentDate); 
        
        // Open the checkout page accept the card details
        PageReference checkout = Page.NABTransactCheckout; 
        Test.setCurrentPage(checkout); 
        checkout.getParameters().put('reference', checkUrl.substringAfter('reference='));
        NABTransactCheckoutController nabcontroller = new NABTransactCheckoutController();
        String processingUrl = nabcontroller.resultURL;         
        
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        // Process the card details only spinner no user interaction.
        PageReference ProcessCard = Page.GatewayPostCheckout; 
        Test.setCurrentPage(ProcessCard);  
        ProcessCard.getParameters().put('refid', '123');
        ProcessCard.getParameters().put('token', '2441083982623330');
        ProcessCard.getParameters().put('strestext', 'Successful');
        ProcessCard.getParameters().put('pan', '424242...242');
        ProcessCard.getParameters().put('expirydate', '52022');
        ProcessCard.getParameters().put('nameOnCard', 'Test demo');
        ProcessCard.getParameters().put('reference', processingUrl.substringAfter('reference='));
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();  
        controller.completePayment();
        String receiptUrl = controller.redirectUrl;
        
        // Shows the receipt of the transaction.
        PageReference receipt = Page.GatewayReceiptPage; 
        Test.setCurrentPage(receipt);                         
        receipt.getParameters().put('reference', receiptUrl.substringAfter('reference='));
        GatewayReceiptPageController receiptController = new GatewayReceiptPageController();  
        receiptController.retryTransaction(); 
        Test.stopTest(); 

        System.assertEquals('Recurring Payment is setup successfully.', receiptController.paymentResponse);                      
    }

    @isTest static void testRejectedSchedule(){
        Gateway_Detail__c Gateway = TestDataFactory.createValidNABCredentials();
        Contact con = TestDataFactory.createContact(); 
        
        String checkUrl = ChargeNowController.NABTransactScheduleService(con.Id, 5.00, 'Quarterly', String.valueOf(Date.today()) ); 
        
        // Open the checkout page accept the card details
        PageReference checkout = Page.NABTransactCheckout; 
        Test.setCurrentPage(checkout); 
        checkout.getParameters().put('reference', checkUrl.substringAfter('reference='));
        NABTransactCheckoutController nabcontroller = new NABTransactCheckoutController();
        String processingUrl = nabcontroller.resultURL;         
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NABTransactMockHttpResponse());
        
        // Process the card details only spinner no user interaction.
        PageReference ProcessCard = Page.GatewayPostCheckout; 
        Test.setCurrentPage(ProcessCard);  
        ProcessCard.getParameters().put('refid', '751220');
        ProcessCard.getParameters().put('token', 'Transaction-a010p000003LfH4AAK');
        ProcessCard.getParameters().put('strestext', 'Invalid card number.');
        ProcessCard.getParameters().put('pan', '456403...007');
        ProcessCard.getParameters().put('expirydate', '02/2030');
        ProcessCard.getParameters().put('nameOnCard', 'ABC');
        ProcessCard.getParameters().put('reference', processingUrl.substringAfter('reference='));
        GatewayPostCheckoutController controller = new GatewayPostCheckoutController();  
        controller.completePayment();
        String receiptUrl = controller.redirectUrl;
        
        // Shows the receipt of the transaction.
        PageReference receipt = Page.GatewayReceiptPage; 
        Test.setCurrentPage(receipt);                         
        receipt.getParameters().put('reference', receiptUrl.substringAfter('reference='));
        GatewayReceiptPageController receiptController = new GatewayReceiptPageController();  
        receiptController.retryTransaction(); 
        
        System.assertEquals('Recurring Payment is not setup due to Invalid card number.', receiptController.paymentResponse);
        Test.stopTest();              
    }

}