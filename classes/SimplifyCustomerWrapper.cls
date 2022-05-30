public with sharing class SimplifyCustomerWrapper {
    public String id;
    public String email;
    public String name;
    public String reference;
    public String token;
    public List<Card> cards;

    public class Card{
       public String name;
       public String last4;
       public String expMonth;
       public String expYear;
    }

    public static String createCustomerPayload(Map<String,String> customerMap){
        String payload=JSON.serialize(customerMap);
        return payload;
    }
}