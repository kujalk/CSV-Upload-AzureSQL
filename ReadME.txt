PreRequisites
------------------
1. Open PowerShell and install following module
Install-Module -Name Az -AllowClobber -Scope CurrentUser
Install-Module -Name SqlServer AllowClobber -Scope CurrentUser
Install-Module -Name dbatools -Scope CurrentUser

2. Fill the Users.CSV [These users will be given permissions]

3. Create the database script [demo.sql]

4. Make sure the CSV files to be imported are saved with "Table" Names

5. Fill the config.json
    "SubscriptionName" -> Subscription ID
    "ResourceGroup" -> Resource Group Name
    "Region" -> Region/Location
    "DataBaseServer" -> Server name [All should be simple case]
    "DataBaseName" -> Data base name
    "DataBaseScript" -> Full path of SQL script
    "DataBaseSchema" -> Data base schema name 
    "UsersCSV" -> Full path of User CSV list
    "DBCSVs" -> Provide the full path of CSV file and make sure the order in which the data needs to be added. Because of FK constraints

Running the script
-----------------------
1. Open PowerShell -> Change Directory to the script location -> ./Deploy-SQLServer.ps1 -ConfigFile config.json
2. Powershell will prompt to input Azure credentials and SQL Master Credentials
3. Password file will be created in the same folder as "UserPass.csv"

