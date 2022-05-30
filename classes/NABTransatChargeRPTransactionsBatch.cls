@deprecated
global with sharing class NABTransatChargeRPTransactionsBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{

    global set<Id> allTransactionIds = new set<Id>();
    global Database.QueryLocator start(Database.BatchableContext bcx){
        return Database.getQueryLocator([Select Id from Transaction__c where Gateway_Name__c = 'nab transact'WITH SECURITY_ENFORCED]);  
    }

    global void execute(Database.BatchableContext bcx, List<Transaction__c> scope){
    }

    global void finish(Database.BatchableContext bcx){
    }
}