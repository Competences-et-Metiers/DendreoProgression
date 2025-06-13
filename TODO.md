### HupSpot integration ‼️PRIORITY: HIGH

- [ ] Add transaction of each participant per ADF
	 **Description:**
	 Using these 2 properties that show up in the **GET** `laps.php` response
	 `"c_url_transaction_hubspot"` and `"c_id_transaction_hubspot"`
- [ ] Fix `participant_id` being incorrect
 - [ ] Add progression to transaction 
	  **Description**
	  Using transaction ID -> Update `progression_e_learning` field
### Features

- [ ] Clean up endpoints
- [ ] Add progression view PER MODULES
- [ ] Add search bar
- [ ] Make contacts clickable -> redirect to Dendreo contact page
	- [ ] Make DB store contacts entreprise ID using link 
		pro.dendreo.com/competences_et_metiers/participants.php?id_participant=22
- [ ] Make ADF clickable -> Dendreo 
		https://pro.dendreo.com/competences_et_metiers/actions_de_formation.php?id_action_de_formation=313

##### Add frontend filtering
- [ ] Custom inactivity date (frontend only -> does not affect activity status in the API that will send auto emails)
- [ ] Add sort by First Name in participant view and not by last name
- [ ] Allow Ascending/Descending in "sort by progress"


# Task breakdown

DMH01
Match email in DB with Excel sheet
	Find Deals related to contact ‼️EXCLUDE PARTICIPANTS WITH 2 DEALS
		Get Deal ID
			Assign Deal ID to Participant ID
				**JSON Body:**
					
```
{            
    "id_lap": "306", /// corresponding LAP to participants courses
    "c_url_transaction_hubspot": "https://app-eu1.hubspot.com/contacts/25868618/record/0-1/202849878226",
    "c_id_transaction_hubspot": "202849878226"
}
```  
  
I'd like to use all the HubSpot IDs of the same email row and store them in the participant_hubspot_data table with the correct participant ID.

DMH02
For every contact (find pivoting var)
	Assign HS Deal ID