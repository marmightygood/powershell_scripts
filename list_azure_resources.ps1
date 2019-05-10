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

$subscriptions=Get-AzureRMSubscription
ForEach ($vsub in $subscriptions){
	Select-AzureRmSubscription $vsub.SubscriptionID
	Write-Host “Exporting resources for “ $vsub.Name

	$subname = $vsub.Name
	$output = @()
	$resources = Get-AzureRMResource
	ForEach ($resource in $resources) {
	
		$taglist = @()
		ForEach ($key in $resource.Tags.Keys) {
			$value = $resource.Tags[$key]
			$taglist += "$key=$value"
		}
		
		$taglistt = $taglist -Join ","
	
		$resource | Add-Member -MemberType NoteProperty -Name "TagList" -Value $taglistt
		$output_obj = New-Object -TypeName PSObject 
		$output_obj | Add-Member -MemberType NoteProperty -Name ResourceName -Value $resource.ResourceName
		$output_obj | Add-Member -MemberType NoteProperty -Name ResourceType -Value $resource.ResourceType
		$output_obj | Add-Member -MemberType NoteProperty -Name ResourceGroupName -Value $resource.ResourceGroupName		
		$output_obj | Add-Member -MemberType NoteProperty -Name Location -Value $resource.Location		
		$output_obj | Add-Member -MemberType NoteProperty -Name TagList -Value $resource.TagList
		
		$output += $output_obj
	}
	$output | Export-CSV -Path "$subname resources.csv" -NoTypeInformation -Force 
}
