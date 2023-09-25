$amount = 5 #amount of images to grab
$subReddit = "Animewallpaper" #subreddit to grab from
$type = "new" #new, hot, top


#don't edit below this line
#---------------------------------------------
#---------------------------------------------
#---------------------------------------------

$amountRandPre = $amount * 3
$amountRand = [math]::Round($amountRandPre)
$findPre = $amountRand * 10
$find = [math]::Round($findPre)

$url = "https://www.reddit.com/r/$subReddit/$type/.json?&limit=$find&t=$type"
$response = Invoke-RestMethod -Uri $url

function findString ($f,$s) {

    ForEach ($line in $($f -split "`n"))
    {
    
        if ($line -match $s)
        {
            $line
        }
    }
}

$i=0 
$grabbed = 0

Write-Host "Looking for $amount Item(s), selecting $amountRand random posts out of $($find) results"


if(Test-Path -Path ".\Reddit\SubReddit\$subReddit" -PathType Container){
    Write-Host "Folder exists"
}else {
        New-Item -Path ".\Reddit\SubReddit\$subReddit" -ItemType Directory
}

Do{

    $randomChildren = ($response.data.children | Get-Random -Count $amountRand)
    
    foreach ($item in $randomChildren) {
        if($i -ge $amountRand){
            Write-Host "Checked $($amountRand) items, $($grabbed) results found"
            Exit
        }    
        $i++

        if ($grabbed -ne $amount){
            Write-Host "Checking item $i, out of $($amountRand)"
            $imageUrl = $item.data.url_overridden_by_dest 


            If($null -eq $imageUrl) {
                $foundImg = $null
            }
            elseif ($imageUrl.EndsWith(".jpg")) {
                $foundImg = $imageUrl
            }elseif ($imageUrl.EndsWith(".png")) {
                $foundImg = $imageUrl
            }elseif ($imageUrl.EndsWith(".gif")) {
                $foundImg = $imageUrl
            }elseif ($imageUrl.EndsWith(".gifv")) {
                $gifV = Invoke-WebRequest -Uri $imageUrl
                $foundgifv = $gifV.Content
                #if first character is a number, then it's not a gifv
                if ($foundgifv[0] -match "[0-9]") {
                    $foundImg = $null
                }else{
                    $foundImgasHTML = findString $foundgifv ".mp4"
                    $getMp4 = $foundImgasHTML[0].split('"')[3]
                    $foundImg = $getMp4
                }
            }elseif ($imageUrl.StartsWith("https://www.redgifs.com") -or $imageUrl.StartsWith("https://redgifs.com")) {
                #scrape video from redgifs
                $RGVidID = $imageUrl.Split("/")[-1]
                $redgifAuth = Invoke-WebRequest -UseBasicParsing -Uri "https://api.redgifs.com/v2/auth/temporary" 
                $RGAFromJSON = ConvertFrom-Json($redgifAuth.Content)
                $token = $RGAFromJSON.token

                $redgif = Invoke-WebRequest -Uri "https://api.redgifs.com/v2/gifs/$RGVidID"`
                -Headers @{
                  "Authorization"="Bearer $token"
                }
                $RGFromJSON = ConvertFrom-Json($redgif.Content)
                $RGHD = $RGFromJSON.gif.urls.hd

                $foundImg = $RGHD

            }else {
                $foundImg = $null
            }
            
            
                if ($foundImg) {
                        $filename = $foundImg.split("/")[-1]
                        If($filename -like "*?*") {
                            $filename = $filename.Split("?")[0]
                        }
                    try {
                        if(Test-Path -Path ".\Reddit\SubReddit\$subReddit\$filename" -PathType Leaf){
                            Write-Output "File already exists: $filename"
                            $foundImg = $null
                        }else{
                            Invoke-WebRequest -Uri $foundImg -OutFile ".\Reddit\SubReddit\$subReddit\$filename"
                            $grabbed++
                            Write-Output "Saved number $grabbed : $foundImg"
                        }
                    } catch {
                        Write-Output "Error occurred while trying to download the image: $_"
                    }

                } else {
                        Write-Output "No result found in the API response. $foundImg $imageUrl"
                }
        }
        $imageUrl = $null
        $foundImg = $null
    }
    
 }while($grabbed -ne $amount)

 If($grabbed -ge 1){
    Write-Host "Grabbed $grabbed image(s), stored in .\Reddit\SubReddit\$subReddit"
 } else{
    Write-Host "No images found"
 } 