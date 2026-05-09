param($Request)

$body = "Hello from Azure Function app!"

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $body
})