
if (-Not (Get-Command "aws" -ErrorAction SilentlyContinue)) {
    Write-Output "Downloading and installing AWS CLI..."
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "$env:USERPROFILE\Downloads\AWSCLIV2.msi"
    Start-Process -FilePath "$env:USERPROFILE\Downloads\AWSCLIV2.msi" -ArgumentList "/quiet" -Wait
}


Write-Output "Please ensure AWS CLI is configured with aws configure if not already done."

$keyMetadata = aws kms create-key --multi-region --description "Multi-region primary key for my application from powershell script" --region us-east-1 | ConvertFrom-Json
$keyId = $keyMetadata.KeyMetadata.KeyId
Write-Output "Created Multi-Region CMK with Key ID: $keyId"

aws kms create-alias --region us-east-1 --alias-name alias/my-multi-region-key --target-key-id $keyId
Write-Output "Alias alias/my-mr-ps-key created for Key ID: $keyId"

aws kms enable-key-rotation --region us-east-1 --key-id $keyId
Write-Output "Key rotation enabled for Key ID: $keyId"


aws kms put-key-policy --region us-east-1 --key-id $keyId --policy-name default --policy file://policykey.json
Write-Output "Custom key policy applied to Key ID: $keyId"

$replicaRegions = @('us-west-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1', 'ap-northeast-1', 'sa-east-1')

foreach ($region in $replicaRegions) {
    $replicaKeyMetadata = aws kms replicate-key --key-id $keyId --replica-region $region --description "Replica of multi-region key powershell" | ConvertFrom-Json
    $replicaKeyId = $replicaKeyMetadata.ReplicaKeyMetadata.KeyId
    Write-Output "Replica multi-region key created in $region with Key ID: $replicaKeyId"

    aws kms create-alias --region $region --alias-name "alias/my-multi-region-key-$region" --target-key-id $replicaKeyId
    Write-Output "Alias alias/my-multi-region-key-$region created for Key ID: $replicaKeyId in $region"
}

Write-Output "All operations completed successfully."
