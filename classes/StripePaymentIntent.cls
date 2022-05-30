public with sharing class StripePaymentIntent { 	
    public String id {get;set;} 
    public String object_Z {get;set;} // in json: object
    public Integer amount {get;set;} 
    public Integer amount_capturable {get;set;} 
    public Integer amount_received {get;set;} 
    public String application {get;set;} 
    public String application_fee_amount {get;set;} 
    public String canceled_at {get;set;} 
    public String cancellation_reason {get;set;} 
    public String capture_method {get;set;} 
    public Charges charges {get;set;} 
    public String client_secret {get;set;} 
    public String confirmation_method {get;set;} 
    public Integer created {get;set;} 
    public String currency_z {get;set;} 
    public String customer {get;set;} 
    public String description {get;set;} 
    public String invoice {get;set;} 
    public String last_payment_error {get;set;} 
    public Boolean livemode {get;set;} 
    public String next_action {get;set;} 
    public String on_behalf_of {get;set;} 
    public String payment_method {get;set;} 
    public List<String> payment_method_types {get;set;} 
    public String receipt_email {get;set;} 
    public String review {get;set;} 
    public String setup_future_usage {get;set;} 
    public String shipping {get;set;} 
    public String source {get;set;} 
    public String statement_descriptor {get;set;} 
    public String statement_descriptor_suffix {get;set;} 
    public String status {get;set;} 
    public String transfer_data {get;set;} 
    public String transfer_group {get;set;} 
    
    
    public class Charges {
        public String object_Z {get;set;} // in json: object
        public Boolean has_more {get;set;} 
        public Integer total_count {get;set;} 
        public String url {get;set;} 
        public list<data> data{get;set;}
    }
    
    public class data{
        public payment_method_details payment_method_details {get; set; }
    }
    
    public class payment_method_details{
        public card card{get;set;}
    }
    
    public class card{
        public Integer exp_year{get;set;}
        public String last4{get;set;}
        public String network{get;set;}
        public Integer exp_month{get;set;}
        public String country{get;set;}
    }
    public static StripePaymentIntent DeserializePaymentIntentResponse(String PaymentIntent_body){
        return (StripePaymentIntent)JSON.deserialize(PaymentIntent_body, StripePaymentIntent.class);
    }

}