@isTest
public  class Test_StripeCheckOutWrapper {
    @isTest static void createSessionPayLoadSubscriptionTest(){
        Contact con=TestDataFactory.createContact();
        Test.startTest();
        StripeCheckoutWrapper wrap=new StripeCheckoutWrapper();
        wrap.customer=con.FirstName+' '+con.LastName;
        wrap.customer_email=con.Email;
        wrap.payment_method_types=new List<String>{'card'};
        String respSubscription=StripeCheckoutWrapper.createSessionPayLoadSubscription(wrap);
        String respPay=StripeCheckoutWrapper.createSessionPayLoad(wrap);
        Test.stopTest();
        String expectedSubscription='&customer=Stripe+Test&mode=subscription&payment_method_types[]=card';
        String expectedPay='&customer=Stripe+Test&customer_email=stripetest%40gmail.com&payment_method_types[]=card';

        System.assertEquals(expectedSubscription,respSubscription);
        System.assertEquals(expectedPay,respPay);

        
        
        
        

    }
}