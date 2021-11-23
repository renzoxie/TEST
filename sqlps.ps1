<#
     Powershell with SQL Server 2012
#>

#######################
# create view
# import module SQLPS
import-module SQLPS -DisableNameChecking
$instanceName = "WIN-87I0KBHU7CK\ATLAS3SQL"
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

$dbName = "AdventureWorks2008R2"
$db = $server.Databases[$dbName]
$viewName = "vwVCPerson"
$view = $db.Views[$viewName]
#if view exists, drop it
if ($view)
{
　　　$view.Drop()
}
$view = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View –ArgumentList $db, $viewName, "dbo"
#TextMode = false meaning we are not
#going to explicitly write the CREATE VIEW header
$view.TextMode = $True
$view.TextHeader = "CREATE VIEW dbo.vwVCPerson AS "
$view.TextBody = @"
SELECT 
　　 TOP 100
 BusinessEntityID,
 LastName,
 FirstName 
FROM 
 Person.Person
WHERE 
　　PersonType = 'IN'
ORDER BY
　　LastName
"@
$view.Create()


########################
# create procedure

import-module SQLPS -DisableNameChecking

$instanceName = "WIN-87I0KBHU7CK\ATLAS3SQL"
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

$sprocName = "uspGetPersonByLastName"
$sproc = $db.StoredProcedures[$sprocName]
#if stored procedure exists, drop it
if ($sproc)
{
　　　$sproc.Drop()
}
$sproc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.StoredProcedure -ArgumentList $db, $sprocName
#TextMode = false means stored procedure header 
#is not editable as text
#otherwise our text will contain the CREATE PROC block
$sproc.TextMode = $false
$sproc.IsEncrypted = $true
$paramtype = [Microsoft.SqlServer.Management.SMO.Datatype]::VarChar(50);
$param = New-Object –TypeName Microsoft.SqlServer.Management.SMO.StoredProcedureParameter –ArgumentList $sproc,"@LastName",$paramtype 
$sproc.Parameters.Add($param)
#Set the TextBody property to define the stored procedure. 
$sproc.TextBody =　@" 
SELECT 
　　TOP 10 
　　BusinessEntityID,
　　LastName
FROM 
　　Person.Person
WHERE 
　　LastName = @LastName
"@

# Create the stored procedure on the instance of SQL Server. 
$sproc.Create()

#######################
# create triger

import-module SQLPS -DisableNameChecking
$instanceName = "WIN-87I0KBHU7CK\ATLAS3SQL"
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

$dbName = "AdventureWorks2008R2"
$db = $server.Databases[$dbName]
$tableName = "Person"
$schemaName = "Person" 
#get a handle to the Person.Person table
$table = $db.Tables | 
　　　　　　　Where Schema -Like "$schemaName" |　
　　　　　　　Where Name -Like "$tableName"
$triggerName = "tr_u_Person";
#note here we need to check triggers attached to table
$trigger = $table.Triggers[$triggerName]
#if trigger exists, drop it
if ($trigger) {
　　　$trigger.Drop()
}
$trigger = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Trigger -ArgumentList $table, $triggerName 
$trigger.TextMode = $false
#this is just an update trigger
$trigger.Insert = $false
$trigger.Update = $true
$trigger.Delete = $false
#3 options for ActivationOrder: First, Last, None
$trigger.InsertOrder = [Microsoft.SqlServer.Management.SMO.Agent.ActivationOrder]::None
$trigger.ImplementationType = [Microsoft.SqlServer.Management.SMO.ImplementationType]::TransactSql
#simple example
$trigger.TextBody = @"
　　SELECT 
　　　　GETDATE() AS UpdatedOn,
　　　　SYSTEM_USER AS UpdatedBy,
　　　　i.LastName AS NewLastName,
　　　　i.FirstName AS NewFirstName,
　　　　d.LastName AS OldLastName,
　　　　d.FirstName AS OldFirstName
　　FROM 
　　　　inserted i
　　　　INNER JOIN deleted d
　　　　ON i.BusinessEntityID = d.BusinessEntityID
"@
$trigger.Create()

#######################
# create index

import-module SQLPS -DisableNameChecking
$instanceName = "WIN-87I0KBHU7CK\ATLAS3SQL"
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

$dbName = "AdventureWorks2008R2"
$db = $server.Databases[$dbName]

$tableName = "Person"
$schemaName = "Person" 
$table = $db.Tables | Where Schema -Like "$schemaName" | Where Name -Like "$tableName"
$indexName = "idxLastNameFirstName"
$index = $table.Indexes[$indexName]
#if stored procedure exists, drop it
if ($index)
{
　　　$index.Drop()
}
$index = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -ArgumentList $table, $indexName
#first index column, by default sorted ascending
$idxCol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $index, "LastName", $false 
$index.IndexedColumns.Add($idxCol1)
#second index column, by default sorted ascending
$idxCol2 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $index, "FirstName", $false 
$index.IndexedColumns.Add($idxCol2)
#included column
$inclCol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $index, "MiddleName"
$inclCol1.IsIncluded = $true
$index.IndexedColumns.Add($inclCol1)
#Set the index properties. 
<#
None　　　　　　　　　 - no constraint
DriPrimaryKey - primary key
DriUniqueKey - unique constraint
#>
$index.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None 
$index.IsClustered = $false
$index.FillFactor = 70
#Create the index on the instance of SQL Server. 
$index.Create()

#######################
# excute a passthrought query, and export to a CSV file

import-module SQLPS -DisableNameChecking
$instanceName = "WIN-87I0KBHU7CK\ATLAS3SQL"
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

$dbName = "AdventureWorks2008R2"
$db = $server.Databases[$dbName]
Invoke-Sqlcmd `
-Query "SELECT * FROM Person.Person" `
-ServerInstance "$instanceName" `
-Database $dbName | 
Export-Csv -LiteralPath "C:\Temp\ResultsFromPassThrough.csv" -NoTypeInformation
 
#execute the SampleScript.sql, and display results to screen 
Invoke-SqlCmd `
-InputFile "C:\Temp\SampleScript.sql" `
-ServerInstance "$instanceName" `
-Database $dbName | 
Select FirstName, LastName, ModifiedDate | 
Format-Table

