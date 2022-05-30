public with sharing class GatewayRefundandRPManageBatch implements Database.Batchable<Recurring_Payment__c>, Database.AllowsCallouts, Database.Stateful{

    /******************* variables *******************/
    Integer successcount = 0;
    Integer totalcount = 0;
    Integer exceptionerrorcount = 0;
    public set<Id> refund_RP_Ids = new set<Id>();
    public set<Id> manage_transactions_RP_Ids = new set<Id>();
    public set<Id> create_transactions_RP_Ids = new set<Id>();
    public Transaction__c check_Latest_Transaction = new Transaction__c();

    public Iterable<Recurring_Payment__c> start(Database.BatchableContext bcx){
        return new RecurringPaymentIterable();
    }

    public void execute(Database.BatchableContext bcx, List<Recurring_Payment__c> scope){
        try{
            Recurring_Payment__c current_RP = [Select Id, Name, Amount__c, Date_Established__c, Duration__c, Gateway_Name__c, Gateway_Refund_Id__c, Gateway_Schedule_Id__c, Installment_Period__c, Next_Installment_Date__c, Refund_Amount__c, Refund_Date__c, Refund_Description__c, Refund_Status__c, Secured_Token__c, RelatedToId__c, Status__c From Recurring_payment__c where Id IN: scope WITH SECURITY_ENFORCED];
            
            if(current_RP.Gateway_Name__c == 'nab transact'){
                check_Latest_Transaction = [Select Id, Name, Transaction_Status__c From Transaction__c Where Recurring_Payment__c =: current_RP.Id WITH SECURITY_ENFORCED order by Name DESC LIMIT 1];
            }
            List<Recurring_Payment__c> recurring_payment_list = new List<Recurring_Payment__c>();
            for(Recurring_Payment__c currentRP : scope){
                totalcount++;
           
                recurring_payment_list.add(current_RP);
                String gateway_name = currentRP.Gateway_Name__c;
                if(current_RP.Refund_Status__c == 'Awaiting'){
                    refund_RP_Ids.add(currentRP.Id);
                    switch on gateway_name{
                        when 'ezidebit'{
                            EzidebitHelper.refundEzidebit(recurring_payment_list);
                        }
                        when 'nab transact'{
                            NABTransactHelper.refundValidationAmount(recurring_payment_list);
                        }
                        when 'payway'{
                            PaywayHelper.refund1Doller(recurring_payment_list);
                        }
                        when 'simplify'{
                            SimplifyHelper.refundSimplify(recurring_payment_list);
                        }
                    }
                    successcount++;
                }
                else if(currentRP.Duration__c == 'Ongoing' && currentRP.Status__c == 'open' && (check_Latest_Transaction.Transaction_Status__c == 'Scheduled' || check_Latest_Transaction.Transaction_Status__c == 'First Transaction Failure' || check_Latest_Transaction.Transaction_Status__c == 'Second Transaction Failure') && currentRP.Gateway_Name__c == 'nab transact'){
                    create_transactions_RP_Ids.add(currentRP.Id);
                            RecurringWrapper recurWrap = new RecurringWrapper();
                            recurWrap.sfProcessingId = currentRP.Id;
                            recurWrap.amount = currentRP.Amount__c;
                            recurWrap.instalPeriod = currentRP.Installment_Period__c;
                            recurWrap.startDate = currentRP.Next_Installment_Date__c;
                            recurWrap.tokenValue = currentRP.Secured_Token__c;

                            String returnValue = NABTransactHelper.updateTransactionBatchProcess(true, false, null, null, recurWrap);
                    successcount++;
                }
                else if(currentRP.Duration__c == 'Ongoing' && currentRP.Status__c == 'open'){
                    manage_transactions_RP_Ids.add(currentRP.Id);
                    switch on gateway_name{
                        when 'ezidebit'{
                            EzidebitHelper.fetchCompletedRPTransactions(recurring_payment_list);
                        }
                        when 'payway'{
                            PaywayHelper.fetchRecurringTransaction(recurring_payment_list);
                        }
                        when 'stripe'{
                            StripeHelper.fetchCompletedRPTransactions(recurring_payment_list, Date.today().addDays(-3)); 
                        }
                        when 'simplify' {
                            SimplifyHelper.fetchCompletedRPTransactions(recurring_payment_list);
                        }
                    }
                    successcount++;
                }
                recurring_payment_list.clear();
            }
        }
        catch(Exception ex){
            exceptionerrorcount++;
            EmailHandler.sendEmailTo('Exception occurred while batch run', 'Following exception has occurred while batch run: '+ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString(), null, false);
        }
    }

    public void finish(Database.BatchableContext bcx){
        List<Recurring_Payment__c> refund_RP = [Select Id, Name, Gateway_Name__c, Gateway_Refund_Id__c, Refund_Amount__c, Refund_Date__c, Refund_Description__c, Refund_Status__c From Recurring_payment__c Where Id IN: refund_RP_Ids WITH SECURITY_ENFORCED];

        List<Recurring_Payment__c> manage_transaction_RP = [Select Id, Name, Amount__c, Date_Established__c, Gateway_Name__c, Gateway_Schedule_Id__c, Installment_Period__c, Next_Installment_Date__c, RelatedToId__c, Status__c From Recurring_payment__c Where Id IN: manage_transactions_RP_Ids WITH SECURITY_ENFORCED];

        List<Recurring_Payment__c> create_transaction_RP = [Select Id, Name, Amount__c, Date_Established__c, Gateway_Name__c, Gateway_Schedule_Id__c, Installment_Period__c, Next_Installment_Date__c, RelatedToId__c, Status__c From Recurring_payment__c Where Id IN: create_transactions_RP_Ids WITH SECURITY_ENFORCED];

        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();

        String orgInstanceURL = system.Url.getSalesforceBaseUrl().toExternalForm();
        String processedDate = '';
        String subject = 'Recurring payments processing report for '+Datetime.now().Date().format();
        String body = '';
        //String body = '[FYI only] Number of Recurring payments attempted to be processed: '+totalcount;
        if(refund_RP.size() > 0){
            body+= '[FYI only] Number of Recurring payments attempted to process refund: '+refund_RP.size();
        }
        if(manage_transaction_RP.size() > 0){
            body+= '\n[FYI only] Number of Recurring payments attempted to fetch transactions from gateway: '+manage_transaction_RP.size();
        }
        if(create_transaction_RP.size() > 0){
            body+= '\n[FYI only] Number of Recurring payments transactions attempted from Salesforce: '+create_transaction_RP.size();
        }
        body+= '\n[Action required] Number of Recurring payments that encountered technical error while processing: '+exceptionerrorcount;
        body+= '\n\nPlease refund the amount from the corresponding gateways manually for failed refund transactions.';
        
        //Generate csv for refund RP.
        if(refund_RP.size() > 0){ 
            string refundcsvHeader = 'Recurring Payment Name, Gateway Name, Gateway Refund Id, Refund Amount, Refund Date, Refund Description(If any), Refund Status, Record Link\n';
            string refundmainContent = refundcsvHeader;
            for(Recurring_Payment__c refundRP : refund_RP){
                if(refundRP.Refund_Description__c != null && refundRP.Refund_Description__c.contains('\n')){
                    refundRP.Refund_Description__c = refundRP.Refund_Description__c.replace('\n','');
                }
                else if(refundRP.Refund_Description__c == null){
                    refundRP.Refund_Description__c = '';
                }
                processedDate =  (refundRP.Refund_Date__c != null)? refundRP.Refund_Date__c.Date().format() : '';
                String refundrecordstring = refundRP.Name+','+ refundRP.Gateway_Name__c+','+ refundRP.Gateway_Refund_Id__c+','+ refundRP.Refund_Amount__c+','+ processedDate+','+ refundRP.Refund_Description__c+','+ refundRP.Refund_Status__c+','+orgInstanceURL+'/'+refundRP.Id+'\n';
                refundmainContent+= refundrecordstring;
            }
            Messaging.EmailFileAttachment refundcsvAttcmnt = new Messaging.EmailFileAttachment();
            blob refundcsvBlob = Blob.valueOf (refundmainContent);
            string refundcsvname= 'Refund Report.csv';
            refundcsvAttcmnt.setFileName (refundcsvname);
            refundcsvAttcmnt.setBody (refundcsvBlob);
            fileAttachments.add(refundcsvAttcmnt);
        }

        //Generate csv for RP from gateways to Ezycharge.
        if(manage_transaction_RP.size() > 0){
            string RPcsvHeader = 'Recurring Payment Name, Gateway Name, Recurring Payment Amount, Installment period, Gateway Schedule Id, Recurring payment Status, Next Installment Date, Record Link\n';
            string RPmainContent = RPcsvHeader;
            for(Recurring_Payment__c manageRP : manage_transaction_RP){
                processedDate =  (manageRP.Next_Installment_Date__c != null)? manageRP.Next_Installment_Date__c.format() : '';
                String RPrecordstring =manageRP.Name+','+manageRP.Gateway_Name__c+','+manageRP.Amount__c+','+manageRP.Installment_Period__c+','+manageRP.Gateway_Schedule_Id__c+','+manageRP.Status__c+','+processedDate+','+orgInstanceURL+'/'+manageRP.Id+'\n';
                RPmainContent+= RPrecordstring;
            }
            Messaging.EmailFileAttachment RPcsvAttcmnt = new Messaging.EmailFileAttachment();
            blob RPcsvBlob = Blob.valueOf (RPmainContent);
            string RPcsvname= 'Recurring Payment Report for Gateway to EzyCharge.csv';
            RPcsvAttcmnt.setFileName (RPcsvname);
            RPcsvAttcmnt.setBody (RPcsvBlob);
            fileAttachments.add(RPcsvAttcmnt);
        }

        //Generate csv for RP from EzyCharge to gateways.
        if(create_transaction_RP.size() > 0){
            string RPT2csvHeader = 'Recurring Payment Name, Gateway Name, Recurring Payment Amount, Installment period, Gateway Schedule Id, Recurring payment Status, Next Installment Date, Record Link\n';
            string RPT2mainContent = RPT2csvHeader;
            for(Recurring_Payment__c manageRPT2 : create_transaction_RP){
                processedDate =  (manageRPT2.Next_Installment_Date__c != null)? manageRPT2.Next_Installment_Date__c.format() : '';
                String RPrecordstring =manageRPT2.Name+','+manageRPT2.Gateway_Name__c+','+manageRPT2.Amount__c+','+manageRPT2.Installment_Period__c+','+manageRPT2.Gateway_Schedule_Id__c+','+manageRPT2.Status__c+','+processedDate+','+orgInstanceURL+'/'+manageRPT2.Id+'\n';
                RPT2mainContent+= RPrecordstring;
            }
            Messaging.EmailFileAttachment RPT2csvAttcmnt = new Messaging.EmailFileAttachment();
            blob RPT2csvBlob = Blob.valueOf (RPT2mainContent);
            string RPT2csvname= 'Recurring Payment Report for EzyCharge to Gateway.csv';
            RPT2csvAttcmnt.setFileName (RPT2csvname);
            RPT2csvAttcmnt.setBody (RPT2csvBlob);
            fileAttachments.add(RPT2csvAttcmnt);
        }

        EmailHandler.sendReportEmail(subject, body, null, true, fileAttachments);
    }
}