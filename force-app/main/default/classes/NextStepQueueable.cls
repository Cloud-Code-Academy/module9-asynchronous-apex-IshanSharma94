/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable implements Queueable {

    // Member variable to store the accounts
    private Map<Id,Account> accounts;

    // Constructor to accept the accounts
    public NextStepQueueable(Map<Id,Account> accounts) {
        this.accounts = accounts;
    }

    // Method to queue the job
    public static void enqueueJob() {
        List<Account> accountsList = [SELECT Id, Next_Step__c FROM Account WHERE Next_Step__c != null LIMIT 10];
        Map<Id,Account> accounts = new Map<Id,Account>(accountsList);
        if(!accounts.isEmpty()) {
            System.enqueueJob(new NextStepQueueable(accounts));
        }
    }

    /*
     * Update/Uncomment the template code to create a method
     * Method to execute the queueable job
     */
    public void execute (QueueableContext context) {
        Map<Id,Account> accsWithNextStepValue = new Map<Id,Account>(this.accounts);
        List<Account> accsToUpdate = new List<Account>();
        for (Account acc : accsWithNextStepValue.values()) {
            NextStepQueueable.removeNextStep(acc);
            accsToUpdate.add(acc);
        }
        update accsToUpdate;

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Opportunity> oppsForAccounts = [SELECT Id FROM Opportunity WHERE AccountId IN :accsWithNextStepValue.keySet()];
        for (Opportunity opp : oppsForAccounts) {
            NextStepQueueable.removeNextStep(opp);
            oppsToUpdate.add(opp);
        }
        update oppsToUpdate;
        NextStepQueueable.enqueueJob();
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an opportunity
    private static void removeNextStep(Opportunity opp) {
        opp.NextStep = null;
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an account
    private static void removeNextStep(Account acc) {
        acc.Next_Step__c = null;
    }
}   