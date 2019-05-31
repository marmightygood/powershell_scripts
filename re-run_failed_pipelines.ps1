#Re-running large numbers of ADF pipelines from the GUI can be quite difficult. This Script will re-run all pipeline runs for a particular pipeline name

$subscription_id = ""
$factory_name=""
$resource_group_name=""
$start_date=""
$end_date="2019-06-01"
$pipeline_name=""

#limits the number of pipelines to re-run
$limit=200
$now = Get-Date -Format g
#Don't reprocess if the pipeline has already failed this many times
$failureLimit = 5

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


#We'll need to check that the pipeline run hasn't already bee successfully re-run - this makes a list of pipelines to check against
Write-Host "Retrieving all runs"
$checkruns = Get-AzDataFactoryV2PipelineRun -DataFactory $factory -PipelineName $pipeline_name -LastUpdatedAfter $start_date -LastUpdatedBefore $now

##Get a list of runs to review for failures
Write-Host "Retrieving date range runs"
$runs = Get-AzDataFactoryV2PipelineRun -DataFactory $factory -PipelineName $pipeline_name -LastUpdatedAfter $start_date -LastUpdatedBefore $end_date

#Stats tracking
$m = $runs | measure
$i=0
$j=0

write-host $m.Count pipeline runs to re-run

foreach($run in $runs) {

    #Check the pipeline is failed
	if ($run.Status -eq "Failed") {

        #Get params string for the failed run, so that we can look for a Succeeded or InProgress one
        $rerunparams = [string]$run.Parameters.Values | % ToString
        $prevFailed = 0
        $alreadyRan = 0

        foreach($previousruns in $checkruns) {

            #Write-Host "Checking status of previous $($previousruns.Status)"
            $previousparams = [string]$previousruns.Parameters.Values | % ToString

            #Write-Host "$rerunparams  $previousparams"

            if ($rerunparams -eq $previousparams) {
                #Write-Host "Found a previous run for $rerunparams $($previousruns.Status)"
                if ($($previousruns.Status -eq "Succeeded") -or $($previousruns.Status -eq "InProgress")){
                        $alreadyRan = 1
                } else {
                    $prevFailed = $prevFailed + 1
                }
            }
        }
        
        if ($($alreadyRan -eq 0) -And $($prevFailed -lt $failureLimit)){
        
            #Copy the pipeline and parameter dictionary to the new pipeline run
		    Invoke-AzDataFactoryV2Pipeline -PipelineName $run.PipelineName -ResourceGroupName $resource_group_name -DataFactoryName $factory_name -Parameter $run.Parameters
		
            #Its probably wise to check against the ADF v2 GUI that the re-runs are actually happening
            Write-Host Re-ran $run.PipelineName - reviewed $i of $m.Count . Pars were $run.Parameters. This pipeline previously failed $prevFailed times.

            #counting the number of re-runs
            $j = $j + 1

        } else {
            Write-Host Already re-ran $run.PipelineName - previous failed attempts $prevFailed . Pars were $run.Parameters
        }

        if ($j -gt $limit){
            Write-Host "Limit $limit re-runs hit, exiting"
            break
        }

	}
	$i = $i + 1

}
