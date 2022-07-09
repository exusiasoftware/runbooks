param(
[object]$WebhookData
) $
WebhookData.WebhookName |
ConvertFrom-Json |
Format-List *
$WebhookData.RequestHeaders | ConvertFrom-Json | Format-List *
$WebhookData.RequestBody | ConvertFrom-Json | Format-List *