public with sharing class BpointAuthKeyRequestWrapper{
	public cls_HppParameters HppParameters;
	public cls_ProcessTxnData ProcessTxnData;
	public String RedirectionUrl;
	public cls_WebHookUrl WebHookUrl;
	public cls_IframeParameters IframeParameters;
	public cls_StatementDescriptor StatementDescriptor;
	public String TestMode;
	public class cls_HppParameters {
		public boolean TokeniseTxnCheckBoxDefaultValue;
		public boolean HideBillerCode;
		public boolean Hidecrn1;
		public boolean Hidecrn2;
		public boolean Hidecrn3;
		public String ReturnBarLabel;
		public String ReturnBarUrl;
	}
	public class cls_ProcessTxnData {
		public String Action;
		public String Amount;
		//public String Currency;	
		public cls_Customer Customer;
		public String MerchantReference;
		public cls_Order Order;
		public String Crn1;
		public String Crn2;
		public String Crn3;
		public String BillerCode;
		public Integer TokenisationMode;
		public boolean TestMode;
		public String SubType;
		public String Type;	
		public cls_FraudScreeningRequest FraudScreeningRequest;
		public cls_EmailAddress EmailAddress;
		public boolean AmexExpressCheckout;
		public cls_DVTokenData DVTokenData;
	}
	public class cls_Customer {
		public cls_Address Address;
		public cls_ContactDetails ContactDetails;
		public String CustomerNumber;
		public cls_PersonalDetails PersonalDetails;
	}
	public class cls_Address {
		public String AddressLine1;	
		public String AddressLine2;	
		public String AddressLine3;	
		public String City;	
		public String CountryCode;	
		public String PostCode;	
		public String State;	
	}
	public class cls_ContactDetails {
		public String EmailAddress;	
		public String FaxNumber;	
		public String HomePhoneNumber;	
		public String MobilePhoneNumber;	
		public String WorkPhoneNumber;	
	}
	public class cls_PersonalDetails {
		public String DateOfBirth;	
		public String FirstName;	
		public String LastName;	
		public String MiddleName;	
		public String Salutation;	
	}
	public class cls_Order {
		public cls_BillingAddress BillingAddress;
		public cls_OrderItems[] OrderItems;
		public cls_ShippingAddress ShippingAddress;
		public boolean BypassThreeDS;
	}
	public class cls_BillingAddress {
		public cls_Address Address;
		public cls_ContactDetails ContactDetails;
		public cls_PersonalDetails PersonalDetails;
	}
	public class cls_OrderItems {
		public String Comments;	
		public String Description;	
		public String GiftMessage;	
		public String PartNumber;	
		public String ProductCode;	
		public Integer Quantity;	
		public String SKU;	
		public String ShippingMethod;
		public String ShippingNumber;
		public Integer UnitPrice;
	}
	public class cls_ShippingAddress {
		public cls_Address Address;
		public cls_ContactDetails ContactDetails;
		public cls_PersonalDetails PersonalDetails;
	}
	public class cls_FraudScreeningRequest {
		public String PerformFraudScreening;
		public String FraudScreeningDeviceFingerprint;
		public String CustomerIPAddress;
		public String TxnSourceWebsiteURL;
		public cls_CustomFields[] CustomFields;
	}
	public class cls_CustomFields {
		public String CustomField;
	}
	public class cls_EmailAddress {
	}
	public class cls_DVTokenData {
		public String DVToken;
		public String ExpiryDate;
		public boolean UpdateDVTokenExpiryDate;
	}
	public class cls_WebHookUrl {
	}
	public class cls_IframeParameters {
		public String CSS;
		public boolean ShowSubmitButton;
	}
	public class cls_StatementDescriptor {
		public String AddressLine1;
		public String AddressLine2;
		public String City;
		public String CompanyName;
		public String CountryCode;
		public String Postcode;
		public String State;
		public String MerchantName;
		public String PhoneNumber;
	}
	public static BpointAuthKeyRequestWrapper parse(String json){
		return (BpointAuthKeyRequestWrapper) System.JSON.deserialize(json, BpointAuthKeyRequestWrapper.class);
	}
	public static String serializeAuthKeyRequestWrapper(BpointAuthKeyRequestWrapper request){
		return JSON.serialize(request);
	}
}