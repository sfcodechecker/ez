({
    doInit: function(component, event, helper){
        component.set('v.showSpinner', true);
        window.addEventListener("message", function(event1) {
            if(event1.data == "Refresh_Detail_Page_by_Stripe" && 
               (event1.origin.search(".visualforce.com") > 0 || event1.origin.search(".force.com") > 0 
                || event1.origin.search(".salesforce.com") > 0 || event1.origin.search(".salesforceliveagent.com") > 0 
                || event1.origin.search(".lightning.com") > 0 || event1.origin.search(".salesforce-communities.com") > 0
                || event1.origin.search(".documentforce.com") > 0 || event1.origin.search(".forceusercontent.com") > 0 
                || event1.origin.search(".forcesslreports.com") > 0 || event1.origin.search(".salesforce-hub.com") > 0))
            {  
                $A.get('e.force:refreshView').fire(); 
            }
        });
        var dt = new Date();
        var today = dt.getFullYear()+'-'+(dt.getMonth()+1)+'-'+dt.getDate();
        var action = component.get("c.getRecurringDetails");
        action.setParams({
            recurringId:component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") 
            {
                if(response.getReturnValue().Q_Charge__Gateway_Name__c != null){
                    var checkIsConnected = component.get("c.isGatewayConnected");
                    checkIsConnected.setParams({"gatewayName":response.getReturnValue().Q_Charge__Gateway_Name__c});
                    checkIsConnected.setCallback(this,function(responsegatewaycheck){
                        var state = responsegatewaycheck.getState();
                        var result = responsegatewaycheck.getReturnValue();
                        if(state === "SUCCESS"){
                            if(result == false){
                                component.set('v.showModel',false);
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({"type":"warning","message": component.get('v.UpdateRPOnDisconnectedGateway')});
                                toastEvent.fire();
                                $A.enqueueAction(component.get('c.closeModel'));
                                return;
                            }else if(response.getReturnValue().Q_Charge__Gateway_Name__c == 'nab transact'){
                                var checkFailedTransaction = component.get("c.checkFailedTransaction");
                                checkFailedTransaction.setParams({
                                    recurringId:response.getReturnValue().Id
                                });
                                checkFailedTransaction.setCallback(this, function(response){
                                    var state = response.getState();
                                    if(state == "SUCCESS"){
                                        var isFailed = response.getReturnValue();
                                        if(isFailed == true){
                                            component.set('v.showSpinner', true);
                                            component.set('v.showModel', false);
                                            var toastEvent = $A.get("e.force:showToast");
                                            toastEvent.setParams({"type":"warning","duration": 20000,"message": "It seems there are failed transctions for the current Recurring Payment, Please refer those issues and try again."});
                                            toastEvent.fire();
                                            $A.enqueueAction(component.get('c.closeModel'));
                                            return;
                                        }
                                        else{
                                            component.set('v.showSpinner', false);
                                            component.set('v.showModel', true)
                                        }
                                    }
                                });
                                $A.enqueueAction(checkFailedTransaction);
                            }
                                else{
                                    component.set('v.showSpinner', false);
                                    component.set('v.showModel', true)
                                }
                        }
                    });
                    $A.enqueueAction(checkIsConnected);
                }
                component.set("v.GatewayName",response.getReturnValue().Q_Charge__Gateway_Name__c);
                component.set("v.RecurringDtails",response.getReturnValue());
                var getContact = component.get("c.getContactInfo");
                getContact.setParams({
                    relatedId:response.getReturnValue().Q_Charge__RelatedToId__c
                });
                getContact.setCallback(this, function(response){
                    var state = response.getState();
                    if(state == "SUCCESS"){
                        if(response.getReturnValue()==undefined){
                            component.set('v.showSpinner', true);
                            component.set('v.showModel', false);
                            component.set("v.contactInfo", response.getReturnValue().Name);
                            return;
                        }
                        
                    }
                });
                $A.enqueueAction(getContact);
                
                if(response.getReturnValue().Q_Charge__Status__c != 'Open'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get('v.UpdateRPFailedRPClosed')});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    return;
                }
                
                component.set("v.MinimumInstalmentDate", today);
            }else{
                helper.ParseError(component, event, response);
            }
            helper.FrequencyHandler(component, event);             
        });
        $A.enqueueAction(action);
    },
    
    handleFrequencyChange : function(component, event) { 
        component.set("v.SelectedFrequency",event.getParam("value"));   
    },
    
    closeModel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire(); 
    },
    
    updateRP : function(component, event, helper) 
    {        
        var selectedFrequency = component.get("v.RecurringDtails.Q_Charge__Installment_Period__c"); 
        var amount = component.get("v.RecurringDtails.Q_Charge__Amount__c");
        var selectedInstallmentDate = component.get("v.RecurringDtails.Q_Charge__Next_Installment_Date__c");
        //var minimumInstallmentDate = component.get('v.MinimumInstalmentDate');
        var selectedGateway = component.get("v.GatewayName");
        
        if(selectedGateway == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.NoGateway')});
            toastEvent.fire();
            component.set('v.showSpinner', false);
            return;
        }
        else if(selectedGateway != undefined && selectedFrequency == undefined && selectedInstallmentDate == undefined && amount == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.RequiredFields')});
            toastEvent.fire();
            component.set('v.showSpinner', false);
            return;
        }
            else if(selectedFrequency == undefined && selectedInstallmentDate == undefined && amount == undefined){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": component.get('v.AmtDateFrequency_NotSpecified')});
                toastEvent.fire();
                component.set('v.showSpinner', false);
                return;
            }
                else if(selectedInstallmentDate == undefined && amount == undefined){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get('v.AmtDate_NotSpecified')});
                    toastEvent.fire();
                    component.set('v.showSpinner', false);
                    return;
                }       
                    else if(amount==undefined || amount <= 0 || amount.toString().length==0){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({"type":"warning","message": component.get('v.ValidAmount')});
                        toastEvent.fire();
                        component.set('v.showSpinner', false);
                        return;
                    }
                        else if(selectedFrequency == undefined){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({"type":"warning","message": component.get('v.Frequency_NotSpecified')});
                            toastEvent.fire();
                            component.set('v.showSpinner', false);
                            return;
                        }    
                            else if(selectedInstallmentDate	 == undefined){
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({"type":"warning","message": component.get('v.InstallmentDate_NotSpecified')});
                                toastEvent.fire();
                                component.set('v.showSpinner', false);
                                return;
                            }
        
        if(selectedGateway != undefined) 
        {
            component.set('v.showSpinner', true);
            if(selectedGateway.toLowerCase() == 'stripe'){      
                helper.StripeUpdateRP(component,event);
            }else if(selectedGateway.toLowerCase() == 'payway'){
                helper.PaywayUpdateRP(component,event);
            }
                else if(selectedGateway.toLowerCase() == 'bpoint'){
                    // BPoint UpdateRP
                }else if(selectedGateway.toLowerCase() == 'simplify') {
                    helper.SimplifyUpdateRP(component,event);
                }else if(selectedGateway.toLowerCase() == 'ezidebit'){
                    helper.EzidebitUpdateRP(component,event);
                }else if(selectedGateway.toLowerCase() == 'nab transact'){
                    helper.NABTransactUpdateRP(component, event);
                }
        }
        else{            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": component.get('v.NoGateway')});
            toastEvent.fire();
        }
    }
})