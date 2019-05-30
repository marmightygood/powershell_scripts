#Re-running large numbers of ADF pipelines from the GUI can be quite difficult. This Script will re-run all pipeline runs for a particular pipeline name

$subscription_id = ""
$factory_name=""
$resource_group_name=""
$start_date=""
$end_date="2019-06-01"
$pipeline_name=""

Import-Module Az.DataFactory

function Login
{
    $needLogin = $true
    Try 
    {
        $content = Get-AzContext
        if ($content) 
        {
            $needLogin = ([string]::IsNullOrEmpty($content.Account))
        } 
    } 
    Catch 
    {
        if ($_ -like "*Login-AzAccount to login*") 
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
        Login-AzAccount
    }
}


Login
Set-AzContext -SubscriptionId $subscription_id

$factory = Get-AzDataFactoryV2 -ResourceGroupName $resource_group_name -Name $factory_name
Write-Host "Retrieving pipeline runs"
$runs = Get-AzDataFactoryV2PipelineRun -DataFactory $factory -PipelineName $pipeline_name -LastUpdatedAfter $start_date -LastUpdatedBefore $end_date

$m = $runs | measure
$i=0
$j=0

write-host $m.Count pipeline runs to re-run

foreach($run in $runs) {

    #Check the pipeline is failed
	if ($run.Status -eq "Failed") {
        
        #Copy the pipeline and parameter dictionary to the new pipeline run
		Invoke-AzDataFactoryV2Pipeline -PipelineName $run.PipelineName -ResourceGroupName $resource_group_name -DataFactoryName $factory_name -Parameter $run.Parameters
		
        #Its probably wise to check against the ADF v2 GUI that the re-runs are actually happening
        Write-Host Re-ran $run.PipelineName - reviewed $i of $m.Count . Pars were $run.Parameters

        #counting the number of re-runs
        $j = $j + 1
        if ($j -gt $limit){
            Write-Host "Limit $limit re-runs hit, exiting"
            break
        }

	}
	$i = $i + 1

}
