public with sharing class BpointAPIResponse {
	public cls_APIResponse APIResponse;
	public String AuthKey;
	public class cls_APIResponse {
		public Integer ResponseCode;	
		public String ResponseText;	
	}

	public static BpointAPIResponse parse(String json){
		return (BpointAPIResponse) System.JSON.deserialize(json, BpointAPIResponse.class);
	}
}