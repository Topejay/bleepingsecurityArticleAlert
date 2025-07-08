# === CONFIGURATION ===
$feedUrl = "https://www.bleepingcomputer.com/feed/"
$ntfyTopic = "Bleepingnot"  # Change to your topic
$ntfyUrl = "https://ntfy.sh/$ntfyTopic"
$seenFile = "seen-links.txt"
$keywords = @("malware", "ransomware", "virus", "trojan", "spyware", "zero-day", "vulnerabilities", "security patches")

# === LOAD SEEN LINKS ===
$seenLinks = @{}
if (Test-Path $seenFile) {
    Get-Content $seenFile | ForEach-Object { $seenLinks[$_] = $true }
}

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
            # Check if title matches keyword
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

    # Save updated seen links
    $seenLinks.Keys | Out-File -FilePath $seenFile -Encoding utf8

} catch {
    Write-Warning "Error fetching or parsing RSS feed: $_"
}
