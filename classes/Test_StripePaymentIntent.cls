@isTest
public with sharing class Test_StripePaymentIntent {
    
    @isTest static void testClass(){
        StripePaymentIntent intent=new StripePaymentIntent();
        intent.amount=700;
        intent.amount_capturable=700;
        intent.application=null;
        intent.application_fee_amount=null;
        intent.canceled_at=null;
        intent.cancellation_reason=null;
        intent.capture_method='automatic';
        intent.client_secret='';
        intent.currency_z='aud';
        intent.customer='cus_K6m3fmEXAn7tY9';
        intent.description=null;
        intent.client_secret='pi_3JSYUxGPA9pqSzzU0plwivKr_secret_MqoO1lfHz9mo59QJ6Hr7ULGD6';
        intent.confirmation_method='automatic';
        intent.livemode=false;
        intent.payment_method_types=new List<String>{'card'};
            intent.invoice=null;
        intent.last_payment_error=null;
        intent.status='succeeded';
        intent.transfer_data=null;
        intent.transfer_group=null;
        intent.review=null;
        intent.shipping=null;
        intent.statement_descriptor=null;
        intent.statement_descriptor_suffix=null;
        intent.receipt_email='';
        intent.amount_received=0;
        StripePaymentIntent.Charges charges=new StripePaymentIntent.Charges();
        intent.charges=charges;
        intent.charges.object_Z='list';
        intent.charges.url='';
        intent.charges.has_more=false;
        intent.charges.total_count=null;
        intent.object_Z='payment-intent';
        intent.on_behalf_of='';
        intent.payment_method='pm_1JSYVMGPA9pqSzzUuLtPuHHc';
        intent.last_payment_error=null;
        StripePaymentIntent.data data=new StripePaymentIntent.data();
        StripePaymentIntent.payment_method_details paydetails=new StripePaymentIntent.payment_method_details();
        StripePaymentIntent.card card=new StripePaymentIntent.card();
        card.country='IN';
        card.exp_month=02;
        card.exp_year=23;
        card.last4='4444';
        paydetails.card=card;
        data.payment_method_details=paydetails;
        intent.charges.data=new List<StripePaymentIntent.data>{data};
            Gateway_Detail__c Gateway=TestDataFactory.createValidStripeCredentials();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeMockHttpResponseGenerator());
        StripePaymentIntent payIntent;
        String res = StripeManager.CheckExistingCredentails();
        HttpResponse response = StripeManager.hitEndpoint(StripeManager.StripePaymentIntents+'/'+intent.payment_method,'GET', StripeManager.StripeGateWay.Client_Key__c, null);                  
        payIntent = (StripePaymentIntent)JSON.deserialize(response.getBody(), StripePaymentIntent.class); 
        Test.stopTest();
        System.assertEquals(700,payIntent.amount);
    }
}