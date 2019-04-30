#stopping large numbers of ADF pipelines from the GUI can be quite difficult. This Script will stop all pipeline runs for a particular pipeline name

$subscription_id = ""
$factory_name=""
$resource_group_name=""
$start_date=""
$end_date=""
$pipeline_name=""

function Login
{
    $needLogin = $true
    Try 
    {
        $content = Get-AzureRmContext
        if ($content) 
        {
            $needLogin = ([string]::IsNullOrEmpty($content.Account))
        } 
    } 
    Catch 
    {
        if ($_ -like "*Login-AzureRmAccount to login*") 
        {
            $needLogin = $true
        } 
        else 
        {
            throw
        }
    }

    if ($needLogin)
    {
        Login-AzureRmAccount
    }
}


Login
Set-AzureRmContext -SubscriptionId $subscription_id

$factory = Get-AzureRmDataFactoryV2 -ResourceGroupName $resource_group_name -Name $factory_name
$runs = Get-AzureRmDataFactoryV2PipelineRun -DataFactory $factory -PipelineName $pipeline_name -LastUpdatedAfter $start_date -LastUpdatedBefore $end_date

$m = $runs | measure
$i=0

write-host $m.Count pipeline runs to stop

foreach($run in $runs) {
	if ($run.Status -eq "InProgress") {
		Stop-AzureRmDataFactoryV2PipelineRun -PipelineRunId $run.RunId -ResourceGroupName $resource_group_name -DataFactoryName $factory_name
		Write-Host Stopped $run.RunId $i of $m.Count
		$i = $i + 1
	}
}
