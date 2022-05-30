public with sharing class SimplifyPlanWrapper {
    public String id;
    public String amount;
    public String currencySimplify;
    public String frequency;
    public String frequencyPeriod;
    public String name;
    public String trialPeriod;
    public String trialPeriodQuantity;


    public static String createPlanPayload(Map<String,String> planMap){
        String payload=JSON.serialize(planMap);
        return payload;
    }

    public static SimplifyPlanWrapper parse(String response){
        return (SimplifyPlanWrapper)JSON.deserialize(response, SimplifyPlanWrapper.class);
    }
}