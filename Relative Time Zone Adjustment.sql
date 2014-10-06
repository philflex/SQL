	CASE 
	
		WHEN 'columnidentifier' IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Pacific Standard Time')
                  
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM table tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM table zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM table pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM table plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-11, PracticeInteraction) 
                        
				WHEN 'columnidentifier'IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Eastern Standard Time')
                              
					THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM table tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM table zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM table pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM table plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-5, PracticeInteraction) 
                              
						WHEN 'columnidentifier' IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Central Standard Time')
                              
							THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM table tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM table zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM table pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM table plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-7, PracticeInteraction) 
                        
                        WHEN 'columnidentifier' IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'US Mountain Standard Time')                                               
                        
                  	THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM table tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM table zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM table pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM table plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, PracticeInteraction)  

               WHEN 'columnidentifier' IN (SELECT #timezone.ProfessionalID FROM #timezone WHERE #timezone.timezoneID = 'Mountain Standard Time')                                               
                        
			THEN DATEADD(hour, -(SELECT TOP 1 tz.BaseUTCOffset FROM table tz WHERE tz.TimeZoneID = (SELECT TOP 1 zc.TimeZoneID FROM table zc WHERE zc.ZipCode = (SELECT TOP 1 pl.ZIP FROM table pl WHERE pl.ID = (SELECT TOP 1 plm.ProviderLocationID FROM table plm WHERE plm.ProfessionalID = #final.CProfessionalId))))-9, PracticeInteraction) 
          
       ELSE NULL
            
    END AS 'AdjustedTimeZone'