/* 
* Class: NxZipCodeBasedAssignment
* Created by Duncan Stewart on 1/23/2014
* Description: Called from Lead trigger, assigns Rep based on Lead.Zip Code and
*	Area of Interest.  If there is no assignment record for the given zip code, 
*	we resort to the active Lead Assignment Rule.
*	1.29.14 DS - Phase II: Identify zip codes & areas of interest before retrieving 
*		zip code assignments to limit query results (120K+ records total)
*	x.xx.xx DS - Phase III: Convert to a batch process
*
*/
public class NxZipCodeBasedAssignment {

  	private Map<String, Map<String, Zip_Code_Assignment__c>> mapAssignmentsByInterestZipCode = new Map<String, Map<String, Zip_Code_Assignment__c>>();
	private Map<String, Zip_Code_Assignment__c> mapAssignmentsByAreaOfInterest;
	private Set<String> interestZipCodes = new Set<String>();	  	    	  

    public NxZipCodeBasedAssignment(Lead[] leads, Map<Id, Lead> newMap, Map<Id, Lead> oldMap, Boolean isInsert) {
      
      // Identify zip codes and areas of interest from the leads to be updated,
      // to limit the # of zip code assignment records returned
      String interestZip = '';	    
      if(isInsert) {	  	  
	  	  // Update the Lead Owner based on the Lead.Zip Code and Area of Interest   
	      for (Lead l : leads) {
	      	interestZip = l.market__c + '-' + l.PostalCode;
	      	interestZipCodes.add(interestZip);
	      }
	      
		} else { // This is an update
  	  	  for (Lead l : leads) {
	 	  	 // Check to see whether this is a reassignment request
	 	  	 NxDiagnostics.debug('Owner Id = ' + l.OwnerId + ', Zip: ' + l.PostalCode + ', A of I: ' + l.market__c);
	  	  	 if(l.Reassign_Lead__c == true ||
	  	  	    (l.PostalCode <> null && l.market__c <> null && l.OwnerId == '00G30000000pn9OEAQ')) {
		      	interestZip = l.market__c + '-' + l.PostalCode;
	      		interestZipCodes.add(interestZip);
	      	}
  	  	  }
  	    }
  	    
  	    // Populate the Zip Code Assignment map based on the Leads
  	    createZipCodeAssignmentMaps(); 
	    
	    // Process our Leads again, based on whether it's an insert or an update
	    // and assign the appropriate owner
	    if(isInsert) {
	    	for (Lead l : leads) {  
		      	// Retrieve the list of assignments for the current Lead's zip code & interest
		      	interestZip = l.market__c + '-' + l.PostalCode;
		      	mapAssignmentsByAreaOfInterest = mapAssignmentsByInterestZipCode.get(interestZip);
		      	if(mapAssignmentsByAreaOfInterest <> null) {
		      		// Retrieve the assignment
		  	  		Zip_Code_Assignment__c tmpZCA = mapAssignmentsByAreaOfInterest.get(l.market__c);
		  	  		NxDiagnostics.debug('Area of interest = ' + l.market__c);		  	  	
		  	  		// If we found an assignment matching the area of interest, assign the lead
		  	  		if (tmpZCA <> null) {
		  	  			l.OwnerId = tmpZCA.Rep__c;
		  	  		}
		  	  	}
	    	}
	      } else { // This is an update
	      	for (Lead l : leads) {
	  	  	 	if (l.Reassign_Lead__c == true ||
	  	  	       (l.PostalCode <> null && l.market__c <> null && l.OwnerId == '00G30000000pn9O')) {
	  	  	 		// Retrieve the list of assignments for the current Lead
		      		interestZip = l.market__c + '-' + l.PostalCode;
		      		mapAssignmentsByAreaOfInterest = mapAssignmentsByInterestZipCode.get(interestZip);
		  	  		if(mapAssignmentsByAreaOfInterest <> null) {
		  	  			// Retrieve the assignment
		  	  			Zip_Code_Assignment__c tmpZCA = mapAssignmentsByAreaOfInterest.get(l.market__c);
		  	  			NxDiagnostics.debug('Area of interest = ' + l.market__c);		  	  	
		  	  			// If we found an assignment matching the area of interest, assign the lead
		  	  			if (tmpZCA <> null) {
		  	  				l.OwnerId = tmpZCA.Rep__c;
		  	  			}
		  	  		}
		      	}
	      	}    	  
  	   	}
  	   	
  	   	NxDiagnostics.popAll();  	   	
    }
    
    private void createZipCodeAssignmentMaps() {
	  // Retrieve the current set of Zip Code Assignments based
	  // on the current group of Leads (Area of Interest + Zip Code is an indexed value)
 	  List<Zip_Code_Assignment__c> zipCodeAssignments = 
  	  	[Select Id, Interest_Zip_Code__c, Zip_Code__c, Area_of_Interest__c, Rep__c
  	     from   Zip_Code_Assignment__c
  	     where  Interest_Zip_Code__c in :interestZipCodes];

	  NxDiagnostics.debug(zipCodeAssignments.size() + ' Zip Code Assignments returned. ');
		  	  		
      // Process the list and populate the assignment maps		
  	  for (Zip_Code_Assignment__c zca : zipCodeAssignments) {
  	  	if (zca.Zip_Code__c <> null) {
	  	  	// Retrieve the map of assignments for this zip code
	  	  	mapAssignmentsByAreaOfInterest = mapAssignmentsByInterestZipCode.get(zca.Interest_Zip_Code__c);
  	  	}
  	  	// If no map exists, create one
  	  	if (mapAssignmentsByAreaOfInterest == null) {
  	  		mapAssignmentsByAreaOfInterest = new Map<String, Zip_Code_Assignment__c>();
  	  	}
  	  	// Add the current assignment to the inner map, and add that to the outer map
  	  	mapAssignmentsByAreaOfInterest.put(zca.Area_of_Interest__c, zca);
  	  	mapAssignmentsByInterestZipCode.put(zca.Interest_Zip_Code__c, mapAssignmentsByAreaOfInterest);
  	  }
    	
    }
}