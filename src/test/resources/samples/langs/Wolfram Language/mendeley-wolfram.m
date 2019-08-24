clientId = "..."
clientSecret = "..."

CreateAuthHeader := "Basic " <> ExportString[clientId <> ":" <> clientSecret, "Base64"]

GetTokenJson := URLFetch["https://api.mendeley.com/oauth/token", 
  "Method" -> "POST", 
  "Headers" -> {"Authorization" -> CreateAuthHeader },
  "BodyData" -> "scope=all&grant_type=client_credentials"
]

GetAccessToken := "access_token" /. ImportString[GetTokenJson, "JSON"]

GetDocJson[doi_] := URLFetch["https://api.mendeley.com/catalog",
  "Headers" -> {"Authorization" -> "Bearer " <> GetAccessToken },
  "Parameters" -> {"doi" -> doi, "view" -> "stats"}
]

GetDoc[doi_] := First[ImportString[GetDocJson[doi], "JSON"]]

GetCounts[doi_] := Association["reader_count_by_country" /. GetDoc[doi]]

GetInterpretedCounts[doi_] := KeyMap[Interpreter["Country"], GetCounts[doi]]

DrawMap[doi_] := GeoRegionValuePlot[GetInterpretedCounts[doi], "ImageSize"->Larger]

CloudDeploy[FormFunction[{"DOI" -> "String"}, DrawMap[#DOI] &, "PNG"]]
