

Function log([string]$fileName ,[string]$Message) {
   
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Message"
    Add-Content $fileName -Value $Line
    
}


$datestr = "logs\$((Get-Date).ToString('yyyy-MM-dd'))"
#Write-Host($datestr)
if (-not (Test-Path -LiteralPath $datestr)) {
    New-Item -ItemType Directory -Path $datestr
} 

$fileName = $datestr+"\$((Get-Date).toString('yyyy-MM-dd_HH_mm_ss')).log"
if (-not (Test-Path -LiteralPath $fileName)) {
   New-Item -ItemType File -Path $fileName
}

Add-Content $fileName -Value "Log file created Successfully"

#$configval = Get-Content -Path config.json  
Get-Content "config.txt" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }

Add-Content $fileName -Value "config.txt file Enteries loaded  Successfully"


$bucketName = $h.Get_Item("S3BUCKET_NAME")
$inputDir = $h.Get_Item("INPUT_FILES_FOLDER")
$outputDir = $h.Get_Item("OUTPUT_FILES_FOLDER")
#$awsKey = $h.Get_Item("AWS_S3_KEY")
$awsRegion = $h.Get_Item("AWS_S3_REGION")


Add-Content $fileName -Value $bucketName
Add-Content $fileName -Value $inputDir
Add-Content $fileName -Value $outputDir
#Add-Content $fileName -Value $awsKey
Add-Content $fileName -Value $awsRegion


$bucketName = $h.Get_Item("S3BUCKET_NAME")
#log(  $fileName, $bucketName )

$msg0 = 'Get the files received in the last 24 hours from '+$inputDir
Add-Content $fileName -Value $msg0

# for getting files/folders created the last 24 hours of the script running time
$files = Get-ChildItem $inputDir | Where-Object { $_.CreationTime -gt (Get-Date).AddDays(-1) } 

# for getting files/folders created in the last 1 hour of the script running time
#$files = Get-ChildItem $inputDir | Where-Object { $_.CreationTime -gt (Get-Date).AddHours(-1) } 

# for getting files/folders created in the last 30 mins of the script running time
#$files = Get-ChildItem $inputDir | Where-Object { $_.CreationTime -gt (Get-Date).AddMinutes(-30) } 

for( $i=0;$i -lt $files.Count ; $i++) {

    
    Add-Content $fileName -Value $files[$i].FullName


    try {

        $isDir = (Test-Path -Path $files[$i].FullName -PathType Container)

        if($isDir){
            
            
            Write-S3Object -BucketName $bucketName -region $awsRegion $files[$i].Name -Folder $files[$i].FullName -ProfileName s3messaposter -Recurse

            $msg1 = " folder "+$files[$i].FullName+" and its content uploaded successfully to "+$bucketName

            Add-Content $fileName -Value $msg1

        } else {

            #Write-s3Object -BucketName $bucketName -Key $awsKey -region $awsRegion -File $files[$i].FullName -ServerSideEncryption AES256 -ProfileName snippy
            Write-S3Object -BucketName $bucketName -region $awsRegion -File $files[$i].FullName -ProfileName s3messaposter
            $msg1 = $files[$i].FullName+' successfully loaded into S3 '+$bucketName
            Add-Content $fileName -Value $msg1
            #Move-item –path $files[$i].FullName –destination $outputDir
            #$msg2 = $files[$i].FullName+' successfully moved to  S3 '+$outputDir
            #Add-Content $fileName -Value $msg2

        }

    }catch {
        $errMsg = $files[$i].FullName+' S3 upload failed:'+ $PSItem.ToString()
        Add-Content $fileName -Value $errMsg
    } finally {
    }
}

