({        
    ChargeStripe : function(component, event) { 
        var recordId = component.get("v.recordId"); 
        var chargeAmount = component.get("v.ChargeAmount");
        if(chargeAmount.includes('.') && chargeAmount.split('.')[1].length >=3 ){
            var msg = component.get('v.AmountTwoDecimalPlaces');
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": msg });
            toastEvent.fire(); 
            component.set('v.showSpinner',false); 
            return;
        }
        if(chargeAmount <= 0.50 || chargeAmount > 999999.99 ){
            var msg = (chargeAmount <= 0.50) ? component.get('v.StripeAmountLessThanHalfDollar') : component.get('v.StripeAmountLessThanMillion');
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({"type":"warning","message": msg });
            toastEvent.fire(); 
            component.set('v.showSpinner',false); 
            return;
        }
        
        var action = component.get("c.StripeOneOffService");
        action.setParams({'recordId' : recordId, 'Amount' : component.get("v.ChargeAmount"), 'requestingURL': window.location.href }); 
        action.setCallback(this,function(response){
            var state = response.getState();
            component.set('v.showSpinner', false);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();  
                if(result.startsWith('valid')){
                    var WindWidth = 800;
                    var WindHeight = 800;
                    var left = (screen.width - WindWidth) / 2;
                    var top = (screen.height - WindHeight) / 2;
                    window.open(result.replace("valid:",""), 'Stipe Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                    $A.get("e.force:closeQuickAction").fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": result});
                    toastEvent.fire();
                }
            }else {
                this.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action);
    },
    chargeBpoint : function(component, event) { 
        var recordId = component.get("v.recordId");   
        var action = component.get("c.bpointOneOffService");
        action.setParams({'recordId' : recordId, 'Amount' : component.get("v.ChargeAmount") ,'chargeType' :'single'}); 
        action.setCallback(this,function(response){
            var state = response.getState();
            console.log(response.getReturnValue());
            if (state === "SUCCESS") {
                var result = response.getReturnValue();   
                if(result[0] == 'success'){
                    var WindWidth = 800;
                    var WindHeight = 800;
                    var left = (screen.width - WindWidth) / 2;
                    var top = (screen.height - WindHeight) / 2;
                    window.open(result[1], '_blank', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({"type":"warning","message": result[1]});
                        toastEvent.fire();
                    }
                    $A.get("e.force:closeQuickAction").fire();

                }else {
                    this.ParseError(component, event, response);
                }             
            });
            $A.enqueueAction(action);
        },
        chargeSimplify : function(component, event) { 
            var recordId = component.get("v.recordId");
            var amount = component.get("v.ChargeAmount");
            //console.log(component.get('v.Simplify'));
            if(amount.includes('.') && amount.split('.')[1].length >=3 ){
                var msg = component.get('v.AmountTwoDecimalPlaces');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": msg });
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }
            else if(amount < 1 ){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": component.get('v.SimplifyAmountLessThanOne')});
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }else if(amount>500000){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": component.get('v.SimplifyAmountLessThanHalfMillion')});
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            } 
            var action = component.get("c.SimplifyOneOffService");
            action.setParams({"recordId" : recordId, "amount" : amount, "requestUrl":window.location.href }); 
            action.setCallback(this,function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    var WindWidth = 800;
                    var WindHeight = 800;
                    var left = (screen.width - WindWidth) / 2;
                    var top = (screen.height - WindHeight) / 2;
                    window.open(result, 'Simplify Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                    $A.get("e.force:closeQuickAction").fire(); 
                    
                }else {
                    this.ParseError(component, event, response);
                }             
            });
            $A.enqueueAction(action);
        },
        ChargeEzidebit : function(component, event) { 
            var recordId = component.get("v.recordId");   
            var amount=component.get("v.ChargeAmount");
            var action=component.get("c.EzidebitOneOffService");
            action.setParams({
                "recordId":recordId,
                "amount":amount,
                "requestUrl":window.location.href
            });
            if(amount.includes('.') && amount.split('.')[1].length >=3 ){
                var msg = component.get('v.AmountTwoDecimalPlaces');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": msg });
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }
            else if(amount < 1){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": component.get('v.EzidebitAmountLessThanOne')});
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }else if(amount > 10000){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": component.get('v.EzidebitAmountLessThanTenThousand')});
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }
            action.setCallback(this,function(response){
                var state=response.getState();
                component.set('v.showSpinner', false);
                if(state==="SUCCESS"){
                    var result=response.getReturnValue(); 
                    if(result.includes('/apex')){
                        var WindWidth = 800;
                        var WindHeight = 800;
                        var left = (screen.width - WindWidth) / 2;
                        var top = (screen.height - WindHeight) / 2;
                        window.open(result, 'Ezidebit Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                        $A.get("e.force:closeQuickAction").fire();
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({"type":"error","message": result});
                        toastEvent.fire(); 
                    }
                    
                }
                else{
                    this.ParseError(component, event, response);
                }
            })
            $A.enqueueAction(action);
        },
        ChargePayway : function(component, event) { 
            
            var recordId = component.get("v.recordId");   
            var Amount=component.get("v.ChargeAmount");
            if(Amount >= 0.01 && Amount <=10000.00){
                var action=component.get("c.paywayOneOffService");
                action.setParams({
                    "recordId":recordId,
                    "amount":Amount
                });
                action.setCallback(this,function(response){
                    var state=response.getState();
                    component.set('v.showSpinner', false);
                    if(state==="SUCCESS"){
                        var result=response.getReturnValue();
                        if(result.startsWith("/apex")){
                            var WindWidth = 800;
                            var WindHeight = 800;
                            var left = (screen.width - WindWidth) / 2;
                            var top = (screen.height - WindHeight) / 2;
                            window.open(result, 'PayWay Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                            $A.get("e.force:closeQuickAction").fire();
                        }else {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({"type":"warning","message": result});
                            toastEvent.fire();
                        }
                    }
                    else{
                        this.ParseError(component, event, response);
                    }
                })
                $A.enqueueAction(action);
            }else{
                var errormessage = (Amount <= 0.01) ? component.get('v.PayWayAmountLessThanOne') : component.get('v.PayWayAmountLessThanTenThousand');
                component.set('v.showSpinner', false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": errormessage});
                toastEvent.fire(); 
            }
        },
        ChargeNABTransact : function(component, event) { 
            var recordId = component.get("v.recordId");
            var amount = component.get("v.ChargeAmount");
            if(amount.includes('.') && amount.split('.')[1].length >=3 ){
                var msg = component.get('v.AmountTwoDecimalPlaces');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": msg });
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }
            
            var action = component.get("c.NABTransactOneOffService");
            action.setParams({"recordId" : recordId, "amount" : amount }); 
            action.setCallback(this,function(response){
                var state = response.getState();
                component.set('v.showSpinner', false);
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if(result.startsWith("/apex")){
                        var WindWidth = 800;
                        var WindHeight = 800;
                        var left = (screen.width - WindWidth) / 2;
                        var top = (screen.height - WindHeight) / 2;
                        window.open(result, 'NAB Transact Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                        $A.get("e.force:closeQuickAction").fire();
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({"type":"warning","message": result});
                        toastEvent.fire();
                    }
                }else {
                    this.ParseError(component, event, response);
                }             
            });
            $A.enqueueAction(action);
        },
        FrequencyHandler : function(component, event) {        
            var action = component.get("c.InstalmentPeriodList");
            action.setParams({"GatewayName" : component.get("v.SelectedGateway")}); 
            action.setCallback(this,function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();   
                    console.log(result);
                    component.set('v.FrequencyList',result);
                    component.set('v.showSpinner', false);
                    if(result.length > 0)
                        component.set('v.SelectedFrequency',result[0].value);
                }else{
                    helper.ParseError(component, event, response);
                }             
            });
            $A.enqueueAction(action);
        },
        ScheduleStripe : function(component, event) { 
            var recordId = component.get("v.recordId"); 
            var chargeAmount = component.get("v.ChargeAmount");
            var selectedInstallmentDate = new Date(component.get("v.SelectedInstalmentDate"));
            var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));
            if(chargeAmount.includes('.') && chargeAmount.split('.')[1].length >=3 ){
                var msg = component.get('v.AmountTwoDecimalPlaces');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": msg });
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }
            if(chargeAmount <= 0.50 || chargeAmount > 999999.99 ){
                var msg = (chargeAmount <= 0.50) ? component.get('v.StripeAmountLessThanHalfDollar') : component.get('v.StripeAmountLessThanMillion') ;
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": msg });
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }
            if(selectedInstallmentDate < MinimumInstallmentDate){
                var msg =component.get('v.PrevDate');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"type":"warning","message": msg });
                toastEvent.fire(); 
                component.set('v.showSpinner',false); 
                return;
            }  
            
            var action = component.get("c.StripeScheduleService");
            action.setParams({
                'recordId' : recordId,
                'Amount' : component.get("v.ChargeAmount"),
                'InstalPeriod' : component.get("v.SelectedFrequency"),
                'StartDate' : component.get("v.SelectedInstalmentDate"),
                'requestingURL': window.location.href }); 
                action.setCallback(this,function(response){
                    var state = response.getState();
                    component.set('v.showSpinner', false);
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        if(result.startsWith('valid')){
                            var WindWidth = 800;
                            var WindHeight = 800;
                            var left = (screen.width - WindWidth) / 2;
                            var top = (screen.height - WindHeight) / 2;
                            window.open(result.replace("valid:",""), 'Stipe Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                            $A.get("e.force:closeQuickAction").fire();
                        }else{
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({"type":"warning","message": result});
                            toastEvent.fire();
                        }
                    }else {
                        this.ParseError(component, event, response);
                    }             
                });
                $A.enqueueAction(action);
            },    
            ScheduleBpoint : function(component, event) { 
                var recordId = component.get("v.recordId");
                var selectedInstallmentDate = new Date(component.get("v.SelectedInstalmentDate"));
                var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));
                if(selectedInstallmentDate<MinimumInstallmentDate){
                    var msg =component.get('v.PrevDate');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": msg });
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }
                var action = component.get("c.BpointScheduleService");
                action.setParams({'recordId' : recordId, 'Amount' : component.get("v.ChargeAmount"),
                'InstalPeriod' : component.get('v.SelectedFrequency'),'StartDate': component.get('v.SelectedInstalmentDate')}); 
                action.setCallback(this,function(response){
                    var state = response.getState();
                    component.set('v.showSpinner', false);
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();  
                        console.log(result);
                        if(result[0]=='success'){
                            var WindWidth = 800;
                            var WindHeight = 800;
                            var left = (screen.width - WindWidth) / 2;
                            var top = (screen.height - WindHeight) / 2;
                            window.open(result[1], '_blank', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                            $A.get("e.force:closeQuickAction").fire();
                        }else{
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({"type":"warning","message": result});
                            toastEvent.fire();
                        }
                    }else {
                        this.ParseError(component, event, response);
                    }             
                });
                $A.enqueueAction(action);
            },    
            ScheduleSimplify : function(component, event) { 
                var recordId = component.get("v.recordId");   
                var action = component.get("c.SimplifyScheduleService");
                var installPeriod=component.get('v.SelectedFrequency');
                var selectedInstallmentDate = new Date(component.get("v.SelectedInstalmentDate"));
                var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));
                var amount = component.get('v.ChargeAmount');
                var month = selectedInstallmentDate.getMonth();
                var days = selectedInstallmentDate.getDay();
                var lastDayOfYear=new Date(new Date().getFullYear(),12,31);
                
               /* if(){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": 'Simplify does not support previous date. Please specify today\'s date or future date. '});
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }*/
                if(amount.includes('.') && amount.split('.')[1].length >=3 ){
                    var msg = component.get('v.AmountTwoDecimalPlaces');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": msg });
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }else if(amount < 0.5 ){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get('v.SimplifyAmountLessThanHalfDollar')});
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }else if(amount>10000){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get('v.SimplifyAmountLessThanHundredThousand')});
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }else if(selectedInstallmentDate<MinimumInstallmentDate){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get('v.PrevDate')});
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
                action.setParams({'recordId' : recordId, 'Amount' : component.get("v.ChargeAmount"), 
                'InstalPeriod' : component.get("v.SelectedFrequency"), 'StartDate' : component.get("v.SelectedInstalmentDate"), "requestUrl":window.location.href}); 
                action.setCallback(this,function(response){
                    var state = response.getState();
                    component.set('v.showSpinner', false);
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();  
                        if(result.startsWith('/apex')){
                            var WindWidth = 800;
                            var WindHeight = 800;
                            var left = (screen.width - WindWidth) / 2;
                            var top = (screen.height - WindHeight) / 2;
                            window.open(result.replace("valid:",""), 'Simplify Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                            $A.get("e.force:closeQuickAction").fire();
                        }else{
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({"type":"warning","message": result});
                            toastEvent.fire();
                        }
                    }else {
                        this.ParseError(component, event, response);
                    }             
                });
                $A.enqueueAction(action);
            },
            ScheduleEzidebit : function(component, event) { 
                var recordId = component.get("v.recordId");   
                var dt = Date.parse(component.get("v.MinimumSelectedDate"));
                var selectedDate=Date.parse(component.get("v.SelectedInstalmentDate"));
                var selectedInstallmentDate = new Date(component.get("v.SelectedInstalmentDate"));
                var currentMilliseconds = Date.now();
                var currentDate = new Date(currentMilliseconds);
                console.log(currentDate.getHours());
            	var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));
                var action = component.get("c.EzidebitScheduleService");
                action.setParams({'recordId' : recordId, 'Amount' : component.get("v.ChargeAmount"), 
                'InstallPeriod' : component.get("v.SelectedFrequency"), 'StartDate' : component.get("v.SelectedInstalmentDate"), "requestUrl":window.location.href}); 
                
                if(component.get('v.ChargeAmount').includes('.') && component.get('v.ChargeAmount').split('.')[1].length >=3 ){
                    var msg = component.get("v.AmountTwoDecimalPlaces");
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": msg });
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }
                else if(component.get('v.ChargeAmount') < 1){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get("v.EzidebitAmountLessThanOne")});
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }else if(component.get('v.ChargeAmount') > 10000){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get("v.EzidebitAmountLessThanTenThousand")});
                    toastEvent.fire();
                    component.set('v.showSpinner',false); 
                    return;
                }
                
                action.setCallback(this,function(response){
                    var state = response.getState();
                    component.set('v.showSpinner', false);
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue(); 
                        if(result.includes('/apex')){
                            var WindWidth = 800;
                            var WindHeight = 800;
                            var left = (screen.width - WindWidth) / 2;
                            var top = (screen.height - WindHeight) / 2;
                            window.open(result, 'Ezidebit Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                            $A.get("e.force:closeQuickAction").fire(); 
                        } else{
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({"type":"warning","message":result});
                            toastEvent.fire();
                        } 
                        
                    }else {
                        this.ParseError(component, event, response);
                    }            
                });
                $A.enqueueAction(action);
            },
            SchedulePayway : function(component, event) { 
                var recordId = component.get("v.recordId");   
                var amount = component.get("v.ChargeAmount");
                var InstallmentPeriod = component.get("v.SelectedFrequency");
                var StartDate = component.get("v.SelectedInstalmentDate");
                
                if(amount >= 0.01 && amount <=10000){
                    var action = component.get("c.paywayScheduleService");
                    action.setParams({'recordId' : recordId, 'amount' : amount,
                    'installPeriod' : InstallmentPeriod, 'startDate' : StartDate }); 
                    action.setCallback(this,function(response){
                        var state = response.getState();
                        component.set('v.showSpinner', false);
                        if (state === "SUCCESS") {
                            var result = response.getReturnValue();  
                            if(result.includes('/apex')){ 
                                var WindWidth = 800;
                                var WindHeight = 800;
                                var left = (screen.width - WindWidth) / 2;
                                var top = (screen.height - WindHeight) / 2;
                                window.open(result, 'PayWay Payment',  'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                                $A.get("e.force:closeQuickAction").fire();
                            }else {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({"type":"warning","message": result});
                                toastEvent.fire();
                                return;
                            }
                        }else {
                            this.ParseError(component, event, response);
                        }             
                    });
                    $A.enqueueAction(action);
                }else{
                    var errormessage = (amount < 0.01) ? component.get("v.PayWayAmountLessThanOne") : component.get("v.PayWayAmountLessThanTenThousand");
                    component.set('v.showSpinner', false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": errormessage});
                    toastEvent.fire(); 
                }
                
            },
            ScheduleNABTransact : function(component, event) { 
                var recordId = component.get("v.recordId");   
                var amount = component.get("v.ChargeAmount");
                var selectedInstallmentDate = new Date(component.get("v.SelectedInstalmentDate"));
            	var MinimumInstallmentDate = new Date(component.get("v.MinimumInstalmentDate"));
                if(amount.includes('.') && amount.split('.')[1].length >=3 ){
                    var msg = component.get("v.AmountTwoDecimalPlaces");
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": msg });
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }else if(selectedInstallmentDate<MinimumInstallmentDate){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get('v.PrevDate')});
                    toastEvent.fire(); 
                    component.set('v.showSpinner',false); 
                    return;
                }
                var action = component.get("c.NABTransactScheduleService");
                action.setParams({'recordId' : recordId, 'amount' : component.get("v.ChargeAmount"), 
                'installPeriod' : component.get("v.SelectedFrequency"), 'startDate' : component.get("v.SelectedInstalmentDate") }); 
                action.setCallback(this,function(response){
                    var state = response.getState();
                    component.set('v.showSpinner', false);
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        if(result.startsWith("/apex")){
                            var WindWidth = 800;
                            var WindHeight = 800;
                            var left = (screen.width - WindWidth) / 2;
                            var top = (screen.height - WindHeight) / 2;
                            window.open(result, 'NAB Transact Payment', 'width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                            $A.get("e.force:closeQuickAction").fire();
                        }else {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({"type":"warning","message": result});
                            toastEvent.fire();
                        } 
                    }
                    else{
                        this.ParseError(component, event, response);
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