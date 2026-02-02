

### 
### Features


- [ ] Add `time spent`
- [ ] SSL/HTTPS
- [ ] Filter out irrelevant courses
- [x] Make French language select + default lang
- [ ] Remove unused participants
#### Cleanup
- [ ] Clean up endpoints
- [ ] Clean up table relations

- [ ] Ensure that removed participants are also removed from database
#### HubSpot transaction ID fetcher
From contact -> GET HS property `formation_detaillee`
Relate property with contact ID in the `participants_hubspot_data` table
- This allows us to see transactions/courses related to the contact


- [x] Make contacts clickable -> redirect to Dendreo contact page
	- [x] Make DB store contacts entreprise ID using link 
		pro.dendreo.com/competences_et_metiers/participants.php?id_participant=22
- [ ] Make ADF clickable -> Dendreo 
		https://pro.dendreo.com/competences_et_metiers/actions_de_formation.php?id_action_de_formation=313

##### Add frontend filtering
- [ ] Custom inactivity date (frontend only -> does not affect activity status in the API that will send auto emails)
- [ ] Add sort by First Name in participant view and not by last name
- [ ] Allow Ascending/Descending in "sort by progress"


# Done

- [x] From existing participant database:
	- [x] Find all existing deals related to contact
		- [x] Save transaction ID

- [x] Add transaction of each participant per ADF
	 **Description:**
	 Using these 2 properties that show up in the **GET** `laps.php` response
	 `"c_url_transaction_hubspot"` and `"c_id_transaction_hubspot"`
 - [x] Add progression to transaction 
	  **Description**
	  Using transaction ID -> Update `progression_e_learning` field


- [x] Add search bar
- [x] - [x] Add "last sync"
	- [x] Fix incorrect date/time
- [x] Add progression view PER MODULES