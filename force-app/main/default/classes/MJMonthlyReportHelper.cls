/**********************************************************************************************
* 
* Description: 
* Helper class to get data using callouts for MJ Monthly reports. 
* One method returns the access token as string and other returns list of monthly reports 
* 
* ADT:
* public class MJMonthlyReportHelper {
*   // Requires Token, firmcode and string of 'month_year'. Returns List of MJ MonthlyReports from the external System
*   public List<MJMonthlyReportParser.MonthlyReport> getMJMonthlyReports(String BEARER_TOKEN, String firmCode, String monthYear)
*   
*   // Returns Token for MJ
*   public String postMJToken()
*  
*
*   // Converts a string value in the format YYYY-MM-DDTHH:MM:SS to an Apex DateTime YYYY-MM-SSTHH:00:00Z
*    public static DateTime tokenExpiryDateParser(String dateTimeStr){
*
* Last Modified by: Moiyyad Sufi, 12/28
* 
**********************************************************************************************/

public class MJMonthlyReportHelper {
    //static final String BASE_URL = 'https://mj-middleware-testing.herokuapp.com';
    MJ_Monthly_Report__c mjr = new MJ_Monthly_Report__c();
    List<MJ_Monthly_Report__c> mjrlist= new List<MJ_Monthly_Report__c>();
    
    public static Map<String, MJ_Monthly_Report__c> getMJMonthlyReports(String BEARER_TOKEN, Account acc, String monthYear, String BaseURL) {
        
        // Creation of HTTP Request for Monthly Report
        HttpRequest req = new HttpRequest();

        req.setEndpoint(BaseURL +'/getMonthlyReport?month='+monthYear+'&FirmCode='+acc.firmCode__c);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer '+ BEARER_TOKEN);
        
        // Create a new http object to send the request object and generate  response   
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        // Check HTTP OK
        if(res.getStatusCode() != 200) {
            return null;
        }
        
        // Check If no data is present for current firmcode for the required month
        Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        
        // No Data Found for the particular firmcode and month-year
        if(resBody.containsKey('result')) { 
            if(resBody.get('result') == 'No Data Found') {
            	return null;
            }
        }
        
        // Error in callout
        if(resBody.containsKey('statusCode')) {  
            if(resBody.get('statusCode') == 401) {
            	return null;
        	}
        }
        
        // Calling Parser to parse the data that has been received 
        MJMonthlyReportParser result = (MJMonthlyReportParser) System.JSON.deserialize(res.getBody(), MJMonthlyReportParser.class);
        
        
        // Getting and returning monthly report list
        List<MJMonthlyReportParser.MonthlyReport> mjMonthlyReportList = result.monthlyReport;
        
        //TODO
        // Initialize Map<{String: (Firmcode)_(month)}, Corresponding Month to date report>
        Map<String,MJ_Monthly_Report__c> mjMonthlyReportMap = new Map<String,MJ_Monthly_Report__c>();

        // For each report record from callout
        for (Integer i = 0; i< mjMonthlyReportList.size() ; i++){


            String externalId = result.monthlyReport[i].FirmCode + '_' + result.monthlyReport[i].Month;

            // Initialize record with few pre recorded values
            MJ_Monthly_Report__c mjMonthlyReport;

            // If this record is present in map, update map values
            if(mjMonthlyReportMap.containsKey(externalId)) {
                mjMonthlyReport = mjMonthlyReportMap.get(externalId);
            // Create new record in map
            } else {
                mjMonthlyReport = initMonthlyReport();

                mjMonthlyReport.External_Id__c = externalId;
                mjMonthlyReport.Firmcode__c = result.monthlyReport[i].FirmCode;
                mjMonthlyReport.Month_Year__c = result.monthlyReport[i].Month;
                mjMonthlyReport.Account__r = new Account(Firmcode__c = result.monthlyReport[i].FirmCode);
                mjMonthlyReport.Name = acc.Name + '_' + result.monthlyReport[i].Month;
            }

            // Add the monthly report metrics 
            mjMonthlyReport.Total_GET_Failures__c += (result.monthlyReport[i].getFail != null ? result.monthlyReport[i].getFail : 0);
            mjMonthlyReport.Total_GET_Successes__c += (result.monthlyReport[i].getSuccess != null ? result.monthlyReport[i].getSuccess : 0);
            mjMonthlyReport.Total_POST_Failures__c += (result.monthlyReport[i].postFail != null ? result.monthlyReport[i].postFail : 0);            
            mjMonthlyReport.Total_POST_Successes__c += (result.monthlyReport[i].postSuccess != null ? result.monthlyReport[i].postSuccess : 0);              
            mjMonthlyReport.Total_Requests__c += (result.monthlyReport[i].count != null ? result.monthlyReport[i].count : 0);
            
            
            mjMonthlyReportMap.put( mjMonthlyReport.External_Id__c, mjMonthlyReport );
            
        }

        // TODO
        // Return Map
        return mjMonthlyReportMap;
        // New Code end
    
    }


    private static MJ_Monthly_Report__c initMonthlyReport() {
        return new MJ_Monthly_Report__c(
            Total_GET_Failures__c = 0,
            Total_GET_Successes__c = 0,
            Total_POST_Failures__c = 0,
            Total_POST_Successes__c = 0,
            Total_Requests__c = 0
        );
    }
    
    //public date dateStringParser(String s){
    //  date d = new date();
    //return d;
    //}
    
    // Method Callouts to External System to return BEARER_TOKEN in String Format
    public static Map<String, Object> postMJToken(String BaseURL, String username, String password) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BaseURL +'/oauth/token');
        req.setMethod('POST');
        
        // Credentials in the format '<Username>:<Password>' type Blob
        Blob concatCredentials = Blob.valueOf(username + ':' + password);
        
        //Base 64 Encoding of concatCredentials
        String encodedCredentials = 'Basic '+EncodingUtil.base64Encode(concatCredentials);
        System.debug(encodedCredentials);
        
        // Specify the header and body information 
        req.setHeader('Authorization', encodedCredentials);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=client_credentials');
        
        
        // Create a new http object to send the request object and generate  response   
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        System.debug(resBody.get('accessToken'));
        
        //return (String) resBody.get('accessToken');
        return resBody;
    }

    public static DateTime tokenExpiryDateParser(String dateTimeStr){
        Date dt = Date.valueOf( dateTimeStr.substringbefore('T') );
        Time ti = Time.newInstance( Integer.valueOf(dateTimeStr.substringbetween('T',':') ), 
                                    Integer.valueOf(dateTimeStr.substringbetween(':',':') ), 
                                    0, 0);
        return Datetime.newInstance(dt, ti);
    }
}