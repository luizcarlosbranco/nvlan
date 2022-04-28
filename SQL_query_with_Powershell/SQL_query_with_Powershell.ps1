#----------------------------------------------------------------------------------------------------------------------
# Change THIS variables below
$DB_Server = "SERVERNAME.yourdomain.com"
$DB_Database = "DATABASE_NAME"
$DB_Username = "DATABASE_USERNAME"
$DB_Password = "DATABASE_PASSWORD"
$DB_Command = "select * from TABLE"
#----------------------------------------------------------------------------------------------------------------------
# Running
Write-Host -NoNewline "Conectando ao Banco... "
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$DB_Server;uid=$DB_Username; pwd=$DB_Password;Database=$DB_Database;Integrated Security=False;"
$connection.Open()
 	$command = $connection.CreateCommand()
    $command.CommandText = $DB_Command
   	$result = $command.ExecuteReader()
    $table = new-object "System.Data.DataTable"
    $table.Load($result)
$connection.Close()
$array = @($table)