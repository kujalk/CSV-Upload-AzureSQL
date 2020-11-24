<#
Purpose - Deploying Azure SQL Database and Importing CSV file from local folder

Pre-Requisites 
    1. Modules - AZ,dbatools,Sqlserver
    
Developer - K.Janarthanan
Date - 19/11/2020
Version - 1 
#>

Param(
    [Parameter(Mandatory)]
    [string]$ConfigFile
)

try
{
    Import-Module -Name Az.Accounts -ErrorAction Stop
    Import-Module -Name Az.Resources -ErrorAction Stop
    Import-Module -Name Az.Sql -ErrorAction Stop
    Import-Module -Name SqlServer -ErrorAction Stop
    Import-Module -Name dbatools -ErrorAction Stop

    #Reading config file
    Write-Host "Reading config file" -ForegroundColor Green
    $Config = Get-Content -Path $ConfigFile -ErrorAction Stop | ConvertFrom-Json

    if(($Config.SubscriptionName -ne $null) -and ($Config.ResourceGroup -ne $null))
    {
        Connect-AzAccount

        # Set subscription 
        Set-AzContext -SubscriptionId $Config.SubscriptionName -ErrorAction Stop
        Write-Host "Switched to the subscription" -ForegroundColor Green

        $ResourceGP = Get-AzResourceGroup | ? {$_.ResourceGroupName -eq $Config.ResourceGroup} 
        if($ResourceGP -eq $null)
        {
            Write-Host "Resource group not found. Therefore will create it" -ForegroundColor Green
            New-AzResourceGroup -Name $Config.ResourceGroup -Location $Config.Region
            Write-Host "Created new Resource Group" -ForegroundColor Green
        }

        # Create a server with a system wide unique server name
        Write-Host "Creating the DB Server" -ForegroundColor Green

        $Sqlcred = Get-Credential -Message "Provide SQL Admin Credentials"
        $server = New-AzSqlServer -ResourceGroupName $Config.ResourceGroup `
        -ServerName $Config.DataBaseServer `
        -Location $Config.Region `
        -SqlAdministratorCredentials $Sqlcred -ErrorAction Stop

        Write-Host "Created DB Server" -ForegroundColor Green

        # Create a server firewall rule that allows access from the specified IP range
        $PublicIP = (Invoke-RestMethod http://ipinfo.io/json).ip
    
        $ServerFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $Config.ResourceGroup `
        -ServerName $Config.DataBaseServer `
        -FirewallRuleName "AllowedIPs" -StartIpAddress $PublicIP -EndIpAddress $PublicIP

        Write-Host "Created Firewall rule" -ForegroundColor Green

        # Create a blank database with an S0 performance level
        Write-Host "Creating Azure SQL Database" -ForegroundColor Green

        $database = New-AzSqlDatabase  -ResourceGroupName $Config.ResourceGroup `
        -ServerName $Config.DataBaseServer `
        -DatabaseName $Config.DataBaseName `
        -RequestedServiceObjectiveName "S0" -Force -Confirm:$false

        Write-Host "Created Azure SQL Database" -ForegroundColor Green

        Write-Host "Going to apply DataBase Script on Azure SQL" -ForegroundColor Green
        Invoke-SQLCmd -ServerInstance  "$($Config.DataBaseServer).database.windows.net"  -Database $Config.DataBaseName -Credential $Sqlcred -InputFile $Config.DataBaseScript -ErrorAction Stop
        Write-Host "Applied DataBase Script on Azure SQL" -ForegroundColor Green

        foreach($item in $Config.DBCSVs)
        {
            Write-Host "`nGoing to export CSV data of $item" -ForegroundColor Green
            $Tablename = $item.split("\")[-1].replace(".csv","")
            $Datatable = Import-Csv $item -ErrorAction Stop| ConvertTo-DbaDataTable
            Write-DbaDataTable -SqlInstance "$($Config.DataBaseServer).database.windows.net" -SqlCredential $Sqlcred -Database $Config.DataBaseName -InputObject $Datatable -Table $Tablename -Schema $Config.DataBaseSchema  
        }
        
        Write-Host "Done with Export of CSVs" -ForegroundColor Green
        
        #Creating USers
        if(-not (Test-Path -PathType Leaf -Path $Config.UsersCSV))
        {
            throw "User CSV file not found" 
        }

        $UserDetails = Import-Csv -path $Config.UsersCSV -ErrorAction Stop
        $UserRecord=@()

        foreach($DBUser in $UserDetails)
        {
            $RandomPassword = [System.Web.Security.Membership]::GeneratePassword(8, 3)

            $username = $DBUser.User
            $password = $RandomPassword
            $schema = $Config.DataBaseSchema


            $UserQuery = @"
            IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE NAME = '$username')
                BEGIN
                    CREATE USER $username WITH PASSWORD = '$password';
                    ALTER USER $username WITH DEFAULT_SCHEMA = $schema;
                END


            GRANT SELECT ON SCHEMA::$schema TO $username;
            GRANT INSERT ON SCHEMA::$schema TO $username;
            GRANT UPDATE ON SCHEMA::$schema TO $username;
            GRANT DELETE ON SCHEMA::$schema TO $username;
            GRANT EXECUTE ON SCHEMA::$schema TO $username;
"@

            Write-Host "Going to create new user and set permissions on $username" -ForegroundColor Green
            Invoke-SQLCmd -ServerInstance  "$($Config.DataBaseServer).database.windows.net"  -Database $Config.DataBaseName -Credential $Sqlcred -Query $UserQuery -ErrorAction Stop
            Write-Host "Successfully created new user $username" -ForegroundColor Green

            $Record = New-Object -Type PSObject  
            $Record | Add-Member -MemberType NoteProperty -Name "User" -Value $username
            $Record | Add-Member -MemberType NoteProperty -Name "Password" -Value $password

            $UserRecord +=$Record
        }

            Write-Host "Password file is created as UserPass.csv" -ForegroundColor Gray
            $UserRecord | Export-CSV -path "UserPass.csv" -NoTypeInformation -ErrorAction Stop
    }

    else 
    {
        throw "Azure Subscription and Resource groups are must for this script"    
    }
}
catch
{
    Write-Host "Error occured : $_" -ForegroundColor Red
    Write-Host "`nDeleting the Resource Group" -ForegroundColor Red

    $ResourceGP = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -eq $Config.ResourceGroup} 
    if($ResourceGP)
    {
        Remove-AzResourceGroup -ResourceGroupName $Config.ResourceGroup -Confirm:$false -Force
        Write-Host "Deleted the Resource Group" -ForegroundColor Red
    }
}
