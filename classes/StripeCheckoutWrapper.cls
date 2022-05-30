public with sharing class StripeCheckoutWrapper {
        public String id; 
        public String object_Z; // in json: object
        public String billing_address_collection; 
        public String client_reference_id; 
        public String customer; 
        public String customer_email; 
        public String cancel_url;
        public String success_url; 
        public String submit_type; 
        public Boolean livemode; 
        public String locale; 
        public String mode; 
        public String payment_intent; 
        public String setup_intent; 
        public List<String> payment_method_types;
        public List<Line_items> Line_items;
        public Subscription subscription_z; 
        public String subscription; 
        
        public class Line_items {
            public Long amount; 
            public String currency_z;
            public String description; 
            public String name; 
            public Integer quantity; 
        }
        
        
        public class Subscription{
            public String plan;
            public String trial_period_days;
            public String trial_end;
        }
        
        public static StripeCheckoutWrapper DeserializeCheckOutResponse(String Checkout_body){
            return (StripeCheckoutWrapper)JSON.deserialize(Checkout_body, StripeCheckoutWrapper.class);
        }
        
        public static String createSessionPayLoad(StripeCheckoutWrapper checkOutRequest) {
            String customerPayLoad= '';
            customerPayLoad += checkOutRequest.id != null ? 'id='+EncodingUtil.urlEncode(checkOutRequest.id, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.object_Z != null ? '&object='+EncodingUtil.urlEncode(checkOutRequest.object_Z, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.billing_address_collection != null ? '&billing_address_collection='+EncodingUtil.urlEncode(checkOutRequest.billing_address_collection, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.client_reference_id != null ? '&client_reference_id='+EncodingUtil.urlEncode(checkOutRequest.client_reference_id, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.customer != null ? '&customer='+EncodingUtil.urlEncode(checkOutRequest.customer, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.customer_email != null ? '&customer_email='+EncodingUtil.urlEncode(checkOutRequest.customer_email, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.cancel_url != null ? '&cancel_url='+EncodingUtil.urlEncode(checkOutRequest.cancel_url, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.success_url != null ? '&success_url='+EncodingUtil.urlEncode(checkOutRequest.success_url, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.submit_type != null ? '&submit_type='+EncodingUtil.urlEncode(checkOutRequest.submit_type, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.livemode != null ? '&livemode='+checkOutRequest.livemode : '';
            customerPayLoad += checkOutRequest.locale != null ? '&locale='+EncodingUtil.urlEncode(checkOutRequest.locale, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.mode != null ? '&mode='+EncodingUtil.urlEncode(checkOutRequest.mode, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.payment_intent != null ? '&payment_intent='+EncodingUtil.urlEncode(checkOutRequest.payment_intent, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.payment_method_types[0] != null ? '&payment_method_types[]='+EncodingUtil.urlEncode(checkOutRequest.payment_method_types[0], 'UTF-8') : '';
            customerPayLoad += checkOutRequest.Line_items != null && checkOutRequest.Line_items[0].amount != null ? '&line_items[]amount='+EncodingUtil.urlEncode(String.valueof(checkOutRequest.Line_items[0].amount), 'UTF-8') : '';
            customerPayLoad += checkOutRequest.Line_items != null &&  checkOutRequest.Line_items[0].name != null ? '&line_items[]name='+EncodingUtil.urlEncode(checkOutRequest.Line_items[0].name, 'UTF-8') : '';
            customerPayLoad += checkOutRequest.Line_items != null &&  checkOutRequest.Line_items[0].currency_z != null ? '&line_items[]currency='+EncodingUtil.urlEncode(String.valueof(checkOutRequest.Line_items[0].currency_z), 'UTF-8') : '';
            customerPayLoad += checkOutRequest.Line_items != null &&  checkOutRequest.Line_items[0].quantity != null ? '&line_items[]quantity='+EncodingUtil.urlEncode(String.valueof(checkOutRequest.Line_items[0].quantity), 'UTF-8') : '';
            customerPayLoad += checkOutRequest.Line_items != null &&  checkOutRequest.Line_items[0].description != null ? '&line_items[]description='+EncodingUtil.urlEncode(checkOutRequest.Line_items[0].description, 'UTF-8') : '';
            
            return customerPayLoad;  
        }
        
        public static String createSessionPayLoadSubscription(StripeCheckoutWrapper checkOutRequest) {
            String subscriptionPayLoad= '';
            subscriptionPayLoad += checkOutRequest.customer != null ? '&customer='+EncodingUtil.urlEncode(checkOutRequest.customer, 'UTF-8') : '';
            subscriptionPayLoad += '&mode=subscription';
            subscriptionPayLoad += (checkOutRequest.subscription_z != null && checkOutRequest.subscription_z.plan != null) ? '&subscription_data[items][][plan]='+EncodingUtil.urlEncode(checkOutRequest.subscription_z.plan, 'UTF-8') : '';
            subscriptionPayLoad += (checkOutRequest.subscription_z != null && checkOutRequest.subscription_z.trial_period_days != null) ? '&subscription_data[trial_period_days]='+EncodingUtil.urlEncode(checkOutRequest.subscription_z.trial_period_days, 'UTF-8') : '';
            subscriptionPayLoad += checkOutRequest.success_url != null ? '&success_url='+EncodingUtil.urlEncode(checkOutRequest.success_url, 'UTF-8') : '';
            subscriptionPayLoad += checkOutRequest.cancel_url != null ? '&cancel_url='+EncodingUtil.urlEncode(checkOutRequest.cancel_url, 'UTF-8') : '';
            subscriptionPayLoad += checkOutRequest.payment_method_types[0] != null ? '&payment_method_types[]='+EncodingUtil.urlEncode(checkOutRequest.payment_method_types[0], 'UTF-8') : '';
            return subscriptionPayLoad;            
        }
}