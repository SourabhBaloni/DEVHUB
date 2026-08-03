public class AccountScheduler
    implements Schedulable {

    public void execute(SchedulableContext sc) {
        AccountBatch batchJob = new AccountBatch();
        Database.executeBatch(batchJob, 200);

    }
}