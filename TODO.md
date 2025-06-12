### HupSpot integration ‼️PRIORITY: HIGH

- [ ] Add transaction of each participant per ADF
	 **Description:**
	 Using these 2 properties that show up in the **GET** `laps.php` response
	 `"c_url_transaction_hubspot"` and `"c_id_transaction_hubspot"`
 - [ ] Add progression to transaction 
	  **Description**
	  Using transaction ID -> Update "Global progression" field
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