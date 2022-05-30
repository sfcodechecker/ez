public with sharing class StripeCustomerWrapper {
    public String id; 
    public String object_Z; // in json: object
    public Integer account_balance; 
    public cus_Address address; 
    public Integer balance; 
    public Integer created; 
    public String currency_z; 
    public Boolean delinquent;
    public String email; 
    public String invoice_prefix; 
    public cus_Invoice_settings invoice_settings; 
    public Boolean livemode; 
    public String name; 
    public String phone; 
    public String tax_exempt; 
    public String description; 
    
    public class cus_Address {
        public String line1; 
        public String line2; 
        public String city; 
        public String state; 
        public String country; 
        public String postal_code; 
        
    }
    
    public class cus_Invoice_settings {
        public Object custom_fields; 
        public Object default_payment_method; 
        public Object footer; 

    }
    
    public static String createCustomerPayLoad(StripeCustomerWrapper customer) {
        String customerPayLoad= '';
        customerPayLoad += 'name='+EncodingUtil.urlEncode(customer.name, 'UTF-8');
        customerPayLoad += customer.email != null ? '&email='+EncodingUtil.urlEncode(customer.email, 'UTF-8') : '';
        customerPayLoad += customer.phone != null ? '&phone='+EncodingUtil.urlEncode(customer.phone, 'UTF-8') : '';
        customerPayLoad += customer.address != null && customer.address.line1 != null ? '&address[line1]='+EncodingUtil.urlEncode(customer.address.line1, 'UTF-8') : '';
        customerPayLoad += customer.address != null && customer.address.line2 != null ? '&address[line2]='+EncodingUtil.urlEncode(customer.address.line2, 'UTF-8') : '';
        customerPayLoad += customer.address != null && customer.address.city != null ? '&address[city]='+EncodingUtil.urlEncode(customer.address.city, 'UTF-8') : '';
        customerPayLoad += customer.address != null && customer.address.state != null ? '&address[state]='+EncodingUtil.urlEncode(customer.address.state, 'UTF-8') : '';
        customerPayLoad += customer.address != null && customer.address.country != null ? '&address[country]='+EncodingUtil.urlEncode(customer.address.country, 'UTF-8') : '';
        customerPayLoad += customer.address != null && customer.address.postal_code != null ? '&address[postal_code]='+EncodingUtil.urlEncode(customer.address.postal_code, 'UTF-8') : '';
        customerPayLoad += customer.description != null ? '&description='+EncodingUtil.urlEncode(customer.description, 'UTF-8') : '';
        
        return customerPayLoad;  
    }
    
    public static StripeCustomerWrapper DeserializeCustomerResponse(String customer_string){
        return (StripeCustomerWrapper)JSON.deserialize(customer_string, StripeCustomerWrapper.class);
    }
    
}