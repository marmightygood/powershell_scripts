function sql($sqlText, $database = "master", $server = ".")
{
    $connection = new-object System.Data.SqlClient.SQLConnection("Data Source=$server;Integrated Security=SSPI;Initial Catalog=$database");
    $cmd = new-object System.Data.SqlClient.SqlCommand($sqlText, $connection);

    $connection.Open();
    $reader = $cmd.ExecuteReader()

    $results = @()
    while ($reader.Read())
    {
        $row = @{}
        for ($i = 0; $i -lt $reader.FieldCount; $i++)
        {
            $row[$reader.GetName($i)] = $reader.GetValue($i)
        }
        $results += new-object psobject -property $row            
    }
    $connection.Close();

    $results
}

$results = sql -sqlText "SELECT GETDATE()" -server "MyServer" -database "MyDatabase"
