public with sharing class StripePlanWrapper {     
    public String interval_count;
    public String interval;
    public Boolean livemode;
    public Integer created;
    public String nickname;
    public String billing_scheme;
    public String product;
    public Decimal amount_decimal;
    public String tiers;
    public Decimal amount;
    public String tiers_mode;
    public String aggregate_usage;
    public String transform_usage;
    public Boolean active;
    public String trial_period_days;
    public String usage_type;
    public String id;
    public String Currency_z;
    
    public static StripePlanWrapper DeserializePlanResponse(String plan_string){
        return (StripePlanWrapper)JSON.deserialize(plan_string, StripePlanWrapper.class);
    }
    
    public static String createPlanPayLoad(StripePlanWrapper plan_wrapper){
        String plan_payload = ''; 
        plan_payload += 'amount_decimal='+EncodingUtil.urlEncode(String.valueOf(plan_wrapper.amount_decimal), 'UTF-8');
        plan_payload += plan_wrapper.interval != null ? '&interval='+EncodingUtil.urlEncode(plan_wrapper.interval, 'UTF-8') : '';
        plan_payload += plan_wrapper.interval_count != null ? '&interval_count='+EncodingUtil.urlEncode(plan_wrapper.interval_count, 'UTF-8') : '';
        plan_payload += plan_wrapper.product != null ? '&product='+EncodingUtil.urlEncode(plan_wrapper.product, 'UTF-8') : '';
        plan_payload += plan_wrapper.Currency_z != null ? '&currency='+EncodingUtil.urlEncode(plan_wrapper.Currency_z, 'UTF-8') : '';
        plan_payload += plan_wrapper.nickname != null ? '&nickname='+EncodingUtil.urlEncode(plan_wrapper.nickname, 'UTF-8') : '';
        return plan_payload;
    }
}