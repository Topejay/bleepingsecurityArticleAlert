# === CONFIGURATION ===
$feedUrl = "https://www.bleepingcomputer.com/feed/"
$ntfyTopic = "TGtGaTeIfVldAkn0"  # Change to your topic
$ntfyUrl = "https://ntfy.sh/$ntfyTopic"
$checkInterval = 0  # No sleep, GitHub Actions will handle schedule

$keywords = @("malware", "ransomware", "virus", "trojan", "spyware")
$seenLinks = @{}

function Send-NtfyNotification($title, $link) {
    $body = "📰 $title`n$link"
    Invoke-RestMethod -Uri $ntfyUrl -Method Post -Body $body -ContentType "text/plain"
}

try {
    $rss = [xml](Invoke-WebRequest -Uri $feedUrl -UseBasicParsing).Content
    foreach ($item in $rss.rss.channel.item) {
        $link = $item.link
        $title = $item.title
        if (-not $seenLinks.ContainsKey($link)) {
            $match = $false
            foreach ($keyword in $keywords) {
                if ($title -match "(?i)\b$keyword\b") {
                    $match = $true
                    break
                }
            }
            if ($match) {
                Send-NtfyNotification $title $link
                Write-Host "Sent malware-related alert: $title"
            } else {
                Write-Host "Ignored: $title"
            }
            $seenLinks[$link] = $true
        }
    }
} catch {
    Write-Warning "Error fetching or parsing RSS feed: $_"
}
