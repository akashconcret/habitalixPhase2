//@Description == This class is written to check Portfolio Object's Sharing Modal.
public class PortFolioSharingUtility{
    
    public static string getSessionIdFrmVFPg(PageReference vfPageContainSessionId){
       String data = vfPageContainSessionId.getContent().toString();
       String sessioId = (data.split('Session_Id_Start_Here')[1]).split('Session_Id_End_Here')[0];
       return sessioId;
       //return data.substring(data.indexOf('Webkul_Session_Id_Start_Here') + 'Webkul_Session_Id_Start_Here'.length(), data.indexOf('Webkul_Session_Id_End_Here'));
  }
    
    public static String isPortFolioPrivate(){ 
        String sharingModel;
        MetadataService.MetadataPort metadataWS = new MetadataService.MetadataPort();
        metadataWs.SessionHeader = new MetadataService.SessionHeader_element();
        metadataWs.SessionHeader.sessionId = getSessionIdFrmVFPg(Page.FetchSessionId);
        MetadataService.ReadCustomObjectResult rs = (MetadataService.ReadCustomObjectResult) metadataWS.readMetadata('CustomObject', new String[] {'HBX_Portfolio__c'});
        
        for (MetadataService.Metadata md : rs.getRecords()) {
            if (md != null) {
                MetadataService.CustomObject obj = (MetadataService.CustomObject) md;
                // System.debug('Custom object full name: ' + obj.fullName);
                // System.debug('Label: ' + obj.label);
                // System.debug('Sharing model: ' + obj.sharingmodel);
                sharingModel = obj.sharingmodel;
            } else {
                //System.debug('Empty metadata.');
            }
        }
        return sharingModel;
    }
}