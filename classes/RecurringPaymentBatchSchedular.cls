global with sharing class RecurringPaymentBatchSchedular implements Schedulable{

    global void execute(SchedulableContext scx){
        //calling batch which handles refund and manage RP transactions.
        GatewayRefundandRPManageBatch gatewaybatch = new GatewayRefundandRPManageBatch();
        Database.executeBatch(gatewaybatch, 1);
    }
}