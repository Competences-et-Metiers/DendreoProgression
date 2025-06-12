
**HS Deal ID -> Dendreo prompt:**

From this excel spreadsheet, I'd like to match all the emails in the spreadsheet with the ones in the participants table in the data base (reminder: "PGPASSWORD=admin psql -U postgres -d dendreo_db")  
Keep in memory only the emails that match (maybe store it locally for later data processing)  
  
Once you have a list of emails that matched, you're gonna want to associate the emails with their respective id_particpant from participants table in the DB.  
  
Using the id_participant, you're going to obtain a list of id_lap associated with each id_participant from the database

-> Add to the laps sync process:
	- Store laps ID per id_participant

https://pro.dendreo.com/competences_et_metiers/api/laps.php?key=BaBVostSCz5RTGIwszf8&id_participant=REPLACE_HERE&include=participactions  

  
I'd like to use all the HubSpot IDs of the same email row and store them in the participant_hubspot_data table with the correct participant ID.