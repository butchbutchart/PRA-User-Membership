# Define the API credentials
$tokenUrl = "https://URL.beyondtrustcloud.com/oauth2/token";
$baseUrl = "https://URL.beyondtrustcloud.com/api/config/v1"
$client_id = "--";
$secret = "--"; 

#endregion creds
###########################################################################

#region Authent 
###########################################################################

# Step 1. Create a client_id:secret pair
$credPair = "$($client_id):$($secret)"
# Step 2. Encode the pair to Base64 string
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
# Step 3. Form the header and add the Authorization attribute to it
$headersCred = @{ Authorization = "Basic $encodedCredentials" }
# Step 4. Make the request and get the token
$responsetoken = Invoke-RestMethod -Uri "$tokenUrl" -Method Post -Body "grant_type=client_credentials" -Headers $headersCred
$token = $responsetoken.access_token
$headersToken = @{ Authorization = "Bearer $token" }
# Step 5. Prepare the header for future request
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Accept", "application/json")
$headers.Add("Authorization", "Bearer $token")
#endregion
###########################################################################

# Prompt the user for the region prefix
$regionPrefix = Read-Host "Enter the region prefix this is simulating data passed from service manager about the user (e.g., dk-)"

# Invoke the REST method to get the list of group policies
$groupresponse = Invoke-RestMethod "$baseUrl/group-policy" -Method 'GET' -Headers $headers

# Check if the response is not empty
if ($groupresponse) {
    # Filter records where the name starts with the user-provided region prefix
    $filteredGroupResponse = $groupresponse | Where-Object { $_.name -like "$regionPrefix*" }

    # Create a custom object for each filtered record with only the name and id fields
    $groupoutput = $filteredGroupResponse | ForEach-Object {
        [PSCustomObject]@{
            ID   = $_.id
            Group_Name = $_.name
        }
    }

    # Display the output in a table format
    $groupoutput | Format-Table -AutoSize
} else {
    Write-Output "No records found."
    exit
}

# Invoke the REST method to get the list of users
$usersresponse = Invoke-RestMethod "$baseUrl/user" -Method 'GET' -Headers $headers

# Check if the response is not empty
if ($usersresponse) {
    # Filter records where the name starts with the user-provided region prefix
    $filteredUsersResponse = $usersresponse | Where-Object { $_.public_display_name -like "$regionPrefix*" }

    # Create a custom object for each filtered record with only the name and id fields
    $usersoutput = $filteredUsersResponse | ForEach-Object {
        [PSCustomObject]@{
            ID         = $_.id
            User_Name  = $_.public_display_name
        }
    }

    # Display the output in a table format
    $usersoutput | Format-Table -AutoSize
} else {
    Write-Output "No records found."
    exit
}

# Prompt the user to select a group policy ID
$grouppolicyid = Read-Host "Enter the ID of the group policy to which you want to add a user"

# Prompt the user to select a user ID
$userid = Read-Host "Enter the ID of the user you want to add to the group policy"



# Prepare the body for the request

#Note- the id property becomess user_id and there is another property for a member object called id that is unrelated
$body = @{
    security_provider_id = 1
    user_id = [int]$userid

} | ConvertTo-Json

# Invoke the REST method to add the user to the group policy
$response = Invoke-RestMethod "$baseUrl/group-policy/$grouppolicyid/member" -Method 'POST' -Headers $headers -Body $body

# Display the response
Write-Output "Object Written:"
$response | ConvertTo-Json
