public class MJReportingScheduler implements Schedulable, Database.AllowsCallouts{
    public MJReportingScheduler() {

    }

    public void execute(SchedulableContext sc)
    {

        MJMonthlyReportBatch mmrb  = new MJMonthlyReportBatch();

        ID batchprocessid = Database.executeBatch(mmrb,20);

    }
    
}