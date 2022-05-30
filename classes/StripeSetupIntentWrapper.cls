public with sharing class StripeSetupIntentWrapper {
    public String id;
    public String payment_method;
    public String status;
    public String cancellation_reason;    
    
    public static StripeSetupIntentWrapper parse(String setup_intent_body){
        return (StripeSetupIntentWrapper)JSON.deserialize(setup_intent_body, StripeSetupIntentWrapper.class);
    }
}