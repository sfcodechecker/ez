public with sharing class PaywayAuthResponseWrapper 
{
	public String message;
	public String merchantId;
	public String merchantName;
	public List<Links> links;
	
	public class Links {
		public String rel;
		public String href;
	}

	public static PaywayAuthResponseWrapper parse(String json) {
		return (PaywayAuthResponseWrapper) System.JSON.deserialize(json, PaywayAuthResponseWrapper.class);
	}
}