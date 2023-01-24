public class MJMonthlyReportBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{

    public final String accessToken;
    public final DateTime expiry;
    public final String monthsToProcessString;
    public final MJ_Reporting_Metrics_Callout_Data__c calloutData;
    public final String BaseURL;

    public List<MJ_Monthly_Report__c> monthlyReportList;
	

   public MJMonthlyReportBatch(){

        monthlyReportList = new List<MJ_Monthly_Report__c>();

        // Access Custom Setting to get the callout data 
        calloutData = MJ_Reporting_Metrics_Callout_Data__c.getOrgDefaults();
       
        DateTime accessTokenExpiresAt = calloutData.Expiry__c;
        String accessToken = calloutData.accessToken__c;        
       
       // If current token or expiry date is null, get new token
       if(accessTokenExpiresAt == null || accessToken == null) {
           
            Map<String,Object> tokenMap = MJMonthlyReportHelper.postMJToken(calloutData.Base_URL__c, calloutData.MJ_Middleware_Username__c, calloutData.MJ_Middleware_Password__c);
        
            String dateTimeStr = (String) tokenMap.get('accessTokenExpiresAt');
            
         	// Set the instance vars to new Values
            accessToken = (String) tokenMap.get('accessToken');
         	accessTokenExpiresAt = MJMonthlyReportHelper.tokenExpiryDateParser(dateTimeStr); 
           
       } // If old token has only half an hour or less left till expiry date, get new token
      
       
       if ( accessTokenExpiresAt  < Datetime.now().addMinutes(30) ) {
            Map<String,Object> tokenMap = MJMonthlyReportHelper.postMJToken(calloutData.Base_URL__c, calloutData.MJ_Middleware_Username__c, calloutData.MJ_Middleware_Password__c);        
        	String dateTimeStr = (String) tokenMap.get('accessTokenExpiresAt');   

         	// Set the instance vars to new Values
            accessToken = (String) tokenMap.get('accessToken');
         	accessTokenExpiresAt = MJMonthlyReportHelper.tokenExpiryDateParser(dateTimeStr);          
       }
       
        this.accessToken = accessToken;
        this.expiry = accessTokenExpiresAt;
        this.BaseURL = calloutData.Base_URL__c;


        // Initialize monthsToProcess
        List<Date> monthsToProcess = new List<Date>();

        // Initialize month_year string List
        List<String> monthYearStrings = new List<String>();
       
        // Binding the last callout datetime to a temporary variable
        Datetime curCalloutStartDateTime = calloutData.LastCallout__c;

        // If last callout date is not available, use today as the last callout date
        if(curCalloutStartDateTime == null) curCalloutStartDateTime = Date.today();
    
        System.debug(curCalloutStartDateTime);


        // Set the temp variable to the 1st of the month/year of the last callout date
        curCalloutStartDateTime= Datetime.newInstanceGMT(
            curCalloutStartDateTime.year(), curCalloutStartDateTime.month(), 1
            );

            System.debug(curCalloutStartDateTime);

        /* 
        * The following loop collects placeholder dates for each month callout is required
        * 
        * For ex: lastcallout = 1/1/22
        * today =  1/7/22
        * 
		* then dates collected = {1/1/22,1/2/22,1/3/22,....,1/7/22}
        * 
        */

        // Iterate over each month from last callout to today
        while(
            curCalloutStartDateTime <= Datetime.now()
             ) {

            monthsToProcess.add(
                Date.newInstance(
                curCalloutStartDateTime.year(), 
                curCalloutStartDateTime.month(),
                1
            ));

            monthYearStrings.add( String.valueOf(curCalloutStartDateTime.month()) + '_' + String.valueOf(curCalloutStartDateTime.year()) );


            curCalloutStartDateTime = curCalloutStartDateTime.addMonths(1);

            // Loop to create list of Month_Year Strings i.e {'month1_Year1','month2_Year2','month3_Year3'...} etc.
        }

       // Create a string of month year strings
        monthsToProcessString = String.join(monthYearStrings, ',');

       System.debug(this.monthsToProcessString);
       System.debug(curCalloutStartDateTime);
       System.debug(Datetime.now());
       System.debug(monthsToProcessString);

    }


   public Database.QueryLocator start(Database.BatchableContext BC){

    // If no months gathered then abort job 
       if(this.monthsToProcessString == null) {
       	System.abortJob(BC.getJobId());
       }
       
       // If error in getting access token, abort job
       System.assert(this.accessToken!=null);
       
       System.debug(accessToken);
            
       System.debug(monthsToProcessString);
       
       String query = 'SELECT id, Name, firmcode__c from account WHERE Firmcode__c != NULL AND Active_MJ_Customer__c=TRUE';
       return Database.getQueryLocator(query);
   }

   public void execute(Database.BatchableContext BC, List<sObject> scope){
       System.debug(scope);
       
    MJMonthlyReportController controller = new MJMonthlyReportController(this.accessToken, this.monthsToProcessString, scope, this.BaseURL);
        monthlyReportList.addAll(controller.processMonthlyReportsForAccounts());

    }

   public void finish(Database.BatchableContext BC){

        System.debug(monthlyReportList);

        if(monthlyReportList.size() != 0) {
            try {
                upsert monthlyReportList External_Id__c;
            } catch (Exception e) {
                System.debug(e.getMessage());
            }       
       }

   	   calloutData.LastCallout__c = DateTime.Now();
       calloutData.accessToken__c = this.accessToken;
       calloutData.Expiry__c = this.expiry;
           
		upsert calloutData;
       
   }
}