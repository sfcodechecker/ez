public class PaywayRecurringResponseWrapper 
{
    
    public class CustomFields {
    }
    
    public String relatedtoId;
    public String httpResponseStatus;
    public Integer httpResponseStatusCode;
    public String paymentStatus;
    public date paymentStartDate;
    public string errorMessage;
    public string transactionreference;
    
    public String customerNumber;
    public PaymentSetup paymentSetup;
    public Contact contact;
    public CustomFields customFields;
    public Schedule schedule;
    public List<Links> links;
    
    //response deserialsed when recurring updated
    public String frequency;
    public String nextPaymentDate;
    public String nextPrincipalAmount;
    public String nextSurchargeAmount;
    public String nextPaymentAmount;
    public String regularPrincipalAmount;
    public String regularSurchargeAmount;
    public String regularPaymentAmount;
    
    //response deserialised when card details updated
    public String paymentMethod;
    public Boolean stopped;
    public CreditCard creditCard;
    public Merchant merchant;
    
    public class Merchant {
        public String merchantId;
        public String merchantName;
        public List<Links> links;
    }
    
    public class Address {
        public String street1;
        public String street2;
        public String cityName;
        public String state;
        public String postalCode;
    }
    
    public class Schedule {
        public String frequency;
        public String nextPaymentDate;
        public String nextPrincipalAmount;
        public String nextSurchargeAmount;
        public String nextPaymentAmount;
        public String regularPrincipalAmount;
        public String regularSurchargeAmount;
        public String regularPaymentAmount;
    }
    
    public class Links {
        public String rel;
        public String href;
    }
    
    public class PaymentSetup {
        public String paymentMethod;
        public Boolean stopped;
        public CreditCard creditCard;
        public Merchant merchant;
    }
    
    public class CreditCard {
        public String cardNumber;
        public String expiryDateMonth;
        public String expiryDateYear;
        public String cardScheme;
        public String cardType;
        public String cardholderName;
        public Double surchargePercentage;
    }
    
    public class Contact {
        public String customerName;
        public String emailAddress;
        public Boolean sendEmailReceipts;
        public String phoneNumber;
        public Address address;
    }
    
    public List<Data> data;
    public class Data 
    {
        public String fieldName;
        public String message;
        public String fieldValue;
    }
}