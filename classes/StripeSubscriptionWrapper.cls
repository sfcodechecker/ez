public with sharing class StripeSubscriptionWrapper {
    
    public String id; 
    public Object application_fee_percent; 
    public String billing; 
    public Boolean prorate;
    public Integer billing_cycle_anchor; 
    public Integer cancel_at; 
    public Boolean cancel_at_period_end; 
    public Integer canceled_at; 
    public String collection_method; 
    public Integer created; 
    public Integer current_period_end; 
    public Integer current_period_start; 
    public String customer; 
    public Integer days_until_due; 
    public String default_payment_method; 
    public String default_source; 
    public Integer discount; 
    public Integer ended_at; 
    public Items items; 
    public String latest_invoice; 
    public Boolean livemode;  
    public String pending_setup_intent; 
    public Plan plan; 
    public Integer quantity; 
    public String schedule; 
    public Integer start; 
    public Integer start_date; 
    public String status; 
    public Integer tax_percent; 
    public Integer trial_end; 
    public Integer trial_start;  
    public String RelatedToId; // to hold related account or contact salesforce id.
    public String Installment_Period; // to hold frequeny displyed.
    public StripePaymentMethodwrapper default_pay_method; //default_payment_method wrapper stores card detail
    
    public class Data {
        public String id; 
        public Integer created; 
        public Plan plan; 
        public Integer quantity; 
        public String subscription; 
    }
    public class Items {
        public List<Data> data; 
        public Boolean has_more; 
        public Integer total_count; 
        public String url; 
        public String deleted;
    }
    
    public class Plan {
        public String id; 
        public Boolean active; 
        public String aggregate_usage; 
        public Integer amount; 
        public String amount_decimal; 
        public String billing_scheme; 
        public Integer created; 
        public String currency_z; 
        public String interval; 
        public Integer interval_count; 
        public Boolean livemode; 
        public String nickname; 
        public String product; 
        public String tiers; 
        public String tiers_mode; 
        public String transform_usage; 
        public Integer trial_period_days; 
        public String usage_type; 
    }
    
    public static StripeSubscriptionWrapper DeserializeSubscriptionResponse(String subscription_string){
        return (StripeSubscriptionWrapper)JSON.deserialize(subscription_string, StripeSubscriptionWrapper.class);
    }
}