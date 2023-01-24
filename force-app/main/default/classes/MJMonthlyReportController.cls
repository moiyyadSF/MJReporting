/*************************************************************************************************
 * 
 * 
 * Controller Class for the MJ Reporting project
 * 
 * ADT
 * 
 * // Call constructor first to initialize
 * Contructor(accessToken, List of Dates to process, List of Accounts)
 * 
 * // Call method to begin processing once initialized
 * void processMonthlyReportsForAccounts()
 * 
 * Last Modified by: Moiyyad Sufi, 12/29
 * 
 *************************************************************************************************/



public class MJMonthlyReportController {
    final private String accessToken;
    final private String monthYearString;
    final private List<Account> accounts;
    final private String baseURL;

    public MJMonthlyReportController(String accessToken, String monthYearString, List<Account> accounts, String BaseURL){
        this.accessToken = accessToken;
        this.monthYearString = monthYearString;
        this.accounts = accounts;
        this.baseURL = BaseURL;
    }

    public List<MJ_Monthly_Report__c> processMonthlyReportsForAccounts(){

        // Init Map of ExtID to Monthly Report record
        Map<String,MJ_Monthly_Report__c> mjReportMap = new Map<String,MJ_Monthly_Report__c>();

        // Init List of Monthly report records
        List<MJ_Monthly_Report__c> mjReportListToUpsert = new List<MJ_Monthly_Report__c>();
        
        // For Each Account
        for(Account a: accounts) {
            
            // Get Parsed Map of MJ Reports for this Account a
            mjReportMap = MJMonthlyReportHelper.getMJMonthlyReports(accessToken, a, monthYearString, this.baseURL);
            
            System.debug(mjReportMap);

            if(mjReportMap != null) {
                
                // For each Map result turn into List element
                //for(String ExtId: mjReportMap.keySet()) {
                //    mjReportListToUpsert.add(mjReportMap.get(ExtId));
                //}

                mjReportListToUpsert.addAll(mjReportMap.Values());
            }
        }
        
        System.debug('reports to process: '+ mjReportListToUpsert);

        return mjReportListToUpsert;

		// Upsert list of MJ Reports        
        /*if(mjReportListToUpsert.size() != 0)
            upsert mjReportListToUpsert External_Id__c;
            */
    }
}