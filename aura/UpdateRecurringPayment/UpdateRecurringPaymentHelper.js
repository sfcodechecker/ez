({
    FrequencyHandler : function(component, event) {        
        var action = component.get("c.instalmentPeriodList");
        action.setParams({"gatewayName" : component.get("v.GatewayName")}); 
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();   
                component.set('v.FrequencyList',result);
                component.set('v.showSpinner', false);
            }else{
                helper.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action);
    },
    
    StripeUpdateRP : function(component, event) {   
        var recPayDetail = component.get("v.RecurringDtails"); 
        var amount = component.get("v.RecurringDtails.Q_Charge__Amount__c");
        var amountStr = amount.toString();
        var selectedInstallmentDate = new Date(component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c"));
        var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));
        
        if(amountStr.includes('.') && amountStr.split('.')[1].length >=3 ){
            var msg = component.get('v.AmountTwoDecimalPlacesUpdateRP');
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": msg });
            toastEvent.fire(); 
            component.set('v.showSpinner', false); 
            return;
        }
        if(amount <= 0.50 || amount > 999999.99 ){
            var msg = ((amount <= 0.50) ? component.get('v.StripeAmountLessThanHalfDollarUpdateRP') : component.get('v.StripeAmountLessThanMillionUpdateRP'));
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": msg });
            toastEvent.fire(); 
            component.set('v.showSpinner', false);
            return;
        }
        if(selectedInstallmentDate < MinimumInstallmentDate){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.PrevDateUpdateRP') });
            toastEvent.fire(); 
            component.set('v.showSpinner',false);  
            return;
        }

        var action = component.get("c.StripeUpdateRP");
        action.setParams({'recPayment' : recPayDetail}); 
        action.setCallback(this,function(response) {
            var state = response.getState();
            component.set('v.showSpinner', false);
            if(state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result.includes('successfully')){ 
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"Success","duration": 20000,"message": result});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                    return;
                } else{        
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": result});
                    toastEvent.fire();
                    return;
                }
            } else{
                this.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action); 
    },

    PaywayUpdateRP : function(component, event) {
        var recordId = component.get("v.recordId");   
        var amount = component.get("v.RecurringDtails.Q_Charge__Amount__c");
        var InstallmentPeriod = component.get("v.RecurringDtails.Q_Charge__Installment_Period__c");
        var StartDate = component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c");
     
        if(amount < 0.01 || amount >10000){
            var errormessage = (amount < 0.01) ? component.get('v.PayWayAmountLessThanOneUpdateRP') : component.get('v.PayWayAmountLessThanTenThousandUpdateRP');
            component.set('v.showSpinner', false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": errormessage});
            toastEvent.fire();
            component.set('v.showSpinner',false);  
            return;
        }
        var action = component.get("c.paywayUpdateRP");
        action.setParams({'recordId' : recordId, 'amount' : amount, 'installPeriod' : InstallmentPeriod, 'startDate' : StartDate }); 
        action.setCallback(this,function(response)
        {
            var state = response.getState();
            component.set('v.showSpinner', false);
            if(state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result.includes('successfully')){ 
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"Success","duration": 20000,"message": result});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                    return;
                } else{        
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": result});
                    toastEvent.fire();
                    return;
                }
            } else{
                this.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action); 
    },

    EzidebitUpdateRP : function(component,event){
        var amount = component.get("v.RecurringDtails.Q_Charge__Amount__c");
        var amountStr = amount.toString();
        var selectedInstallmentDate = new Date(component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c"));
        var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));
        if(amountStr.includes('.') && amountStr.split('.')[1].length >=3 ){
            var msg = component.get('v.AmountTwoDecimalPlacesUpdateRP');
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": msg });
            toastEvent.fire(); 
            component.set('v.showSpinner', false); 
            return;
        }
        if(component.get("v.RecurringDtails.Q_Charge__Amount__c") < 1){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.EzidebitAmountLessThanOneUpdateRP')});
            toastEvent.fire(); 
            component.set('v.showSpinner',false); 
            return;
        }else if(component.get("v.RecurringDtails.Q_Charge__Amount__c") > 10000){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.EzidebitAmountLessThanTenThousandUpdateRP')});
            toastEvent.fire();
            component.set('v.showSpinner',false); 
            return;
        }else if(selectedInstallmentDate < MinimumInstallmentDate){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.PrevDateUpdateRP')});
            toastEvent.fire();
            component.set('v.showSpinner',false); 
            return;
        }
        var action = component.get('c.ezidebitUpdateRP');
        action.setParams({"recordId":component.get('v.recordId'),"amount":component.get("v.RecurringDtails.Q_Charge__Amount__c"),
        "installPeriod":component.get("v.RecurringDtails.Q_Charge__Installment_Period__c"),"startDate":component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c"),
        "scheduleId":component.get("v.RecurringDtails.Q_Charge__Gateway_Schedule_Id__c")});
        action.setCallback(this,function(response){
            var state = response.getState();
            component.set('v.showSpinner', false);
            if(state==='SUCCESS'){
                var result=response.getReturnValue();
                console.log(result);
                if(result.includes('success')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"Success","duration": 20000,"message": component.get('v.RecurringDtails.Name')+' is '+result});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }else if(result.includes('Error')){
                    var msg=result.split(':');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","duration": 20000,"message": msg[1]});
                    toastEvent.fire();
                }else if(result.includes('failed')){
                    var msg=result.split(':');
                    var finalMessage = msg[1];
                    if(result.includes('PM')){
                        finalMessage += ':'+msg[2];
                    }
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","duration": 20000,"message": finalMessage});
                    toastEvent.fire();
                } else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","duration": 20000,"message": result});
                    toastEvent.fire();
                }
            }else{
                this.ParseError(component,event,response);
            }
        });
        $A.enqueueAction(action);
        
    },

    NABTransactUpdateRP : function(component,event){
        var amount = component.get("v.RecurringDtails.Q_Charge__Amount__c");
        var amountStr = amount.toString();
        //component.set("v.SelectedInstalmentDate", component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c"));
        var selectedInstallmentDate = new Date(component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c"));
        var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));

        if(amountStr.includes('.') && amountStr.split('.')[1].length >=3 ){
            var msg = component.get('v.AmountTwoDecimalPlacesUpdateRP');
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": msg });
            toastEvent.fire(); 
            component.set('v.showSpinner', false); 
            return;
        }
        if(component.get("v.RecurringDtails.Q_Charge__Amount__c") <= 0){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.NABAmountLessThanOneDollarUpdateRP')});
            toastEvent.fire(); 
            component.set('v.showSpinner',false); 
            return;
        }else if(component.get("v.RecurringDtails.Q_Charge__Amount__c") > 99999999.99){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.NABAmountLessThanTenBillionUpdateRP')});
            toastEvent.fire();
            component.set('v.showSpinner',false); 
            return;
        }else if(selectedInstallmentDate < MinimumInstallmentDate){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.PrevDateUpdateRP')});
            toastEvent.fire();
            component.set('v.showSpinner',false); 
            return;
        }
        var action = component.get('c.NABTransactUpdateRP');
        action.setParams({"recordId":component.get('v.recordId'),
        "amount":component.get("v.RecurringDtails.Q_Charge__Amount__c"),
        "installPeriod":component.get("v.RecurringDtails.Q_Charge__Installment_Period__c"),
        "startDate":component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c")});
        action.setCallback(this,function(response){
            var state = response.getState();
            component.set('v.showSpinner', false);
            if(state==='SUCCESS'){
                var result=response.getReturnValue();
                if(result.includes('successfully')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"Success","duration": 20000,"message": result});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","duration": 20000,"message": result});
                    toastEvent.fire();
                }
            }else{
                this.ParseError(component,event,response);
            }
        });
        $A.enqueueAction(action);
        
    },
    
    SimplifyUpdateRP:function(component,event){
         var amount = component.get("v.RecurringDtails.Q_Charge__Amount__c");
        var amountStr = amount.toString();
        var selectedInstallmentDate = new Date(component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c"));
        var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));
        console.log(selectedInstallmentDate+' '+MinimumInstallmentDate);
        var lastDayOfYear=new Date(new Date().getFullYear(),12,31);
        if(amountStr.includes('.') && amountStr.split('.')[1].length >=3 ){
            var msg = component.get('v.AmountTwoDecimalPlacesUpdateRP');
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": msg });
            toastEvent.fire(); 
            component.set('v.showSpinner', false); 
            return;
        }
        if(component.get("v.RecurringDtails.Q_Charge__Amount__c") < 0.5){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.SimplifyAmountLessThanHalfDollarUpdateRP')});
            toastEvent.fire(); 
            component.set('v.showSpinner',false); 
            return;
        }else if(component.get("v.RecurringDtails.Q_Charge__Amount__c") > 10000){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.SimplifyAmountLessThanHundredThousandUpdateRP')});
            toastEvent.fire();
            component.set('v.showSpinner',false); 
            return;
        }else if(selectedInstallmentDate < MinimumInstallmentDate){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.PrevDateUpdateRP')});
            toastEvent.fire(); 
            component.set('v.showSpinner',false); 
            return;
        }/*else if(selectedInstallmentDate > lastDayOfYear){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": 'Simplify does not support next year date. Please specify date of this year. '});
            toastEvent.fire(); 
            component.set('v.showSpinner',false); 
            return;
        }*/
        var action = component.get('c.simplifyUpdateRP');
        action.setParams({"recordId":component.get('v.recordId'),"amount":component.get("v.RecurringDtails.Q_Charge__Amount__c"),
        "installPeriod":component.get("v.RecurringDtails.Q_Charge__Installment_Period__c"),"startDate":component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c"),
        "scheduleId":component.get("v.RecurringDtails.Q_Charge__Gateway_Schedule_Id__c")});
        action.setCallback(this,function(response){
            var state = response.getState();
            component.set('v.showSpinner', false);
            if(state==='SUCCESS'){
                var result=response.getReturnValue();
                if(result.includes('success')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"Success","duration": 20000,"message": component.get('v.RecurringDtails.Name')+' is '+result});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }else if(result.includes('failed')){
                    var msg=result.split(':');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","duration": 20000,"message": msg[1]});
                    toastEvent.fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"error","duration": 20000,"message": result});
                    toastEvent.fire();
                }
            }else{
                this.ParseError(component,event,response);
            }
        });
        $A.enqueueAction(action);
    },
    
    ParseError: function(component, event, response){
        var errorMsg = '';
        var state = response.getState();
        if(state == 'ERROR'){            
            let errors = response.getError();
            let errorData = JSON.parse(errors[0].message);
            errorMsg = errorData.exception_Message_StackTrace;
            console.error(errorData.exception_Message_StackTrace);
            //General error toast message
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "duration": 10000,
                "message": errorData.messagetoUser
            });
            toastEvent.fire();
        } else{            
            let errors = response.getError();
            let message = 'Unknown error. '; // Default error message
            // Retrieve the error message sent by the server
            var i;
            if (errors && Array.isArray(errors) && errors.length > 0) {
                for (i = 0; i < errors.length; i++) { 
                    message = message +'Error'+ i + ':' + errors[i].message;
                }
            }
            // Display the message
            console.error(message); errorMsg = message;            
            //General error toast message
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "duration": 10000,
                "message": component.get('v.SomethingWentWrong')
            });
            toastEvent.fire();            
        }
        var sendError = component.get("c.sendExceptionEmail");
        sendError.setParams({"emailBody": errorMsg });
        $A.enqueueAction(sendError);
    }
})