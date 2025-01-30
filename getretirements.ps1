# Fetch RSS feed
try {
    $rssFeed = Invoke-RestMethod -Uri "https://www.microsoft.com/releasecommunications/api/v2/azure/rss" -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve RSS feed: $_"
    return
}

# Filter for retirement announcements
$retirements = $rssFeed | Where-Object {
    $_.category -match "Retirements" -and $_.title -match "(?i)retirement|end of support|retiring|from\s+\w+\s+\d{1,2},?\s+\d{4}|by\s+\w+\s+\d{1,2},?\s+\d{4}"
}

# Process retirements
$sortedRetirements = $retirements | Sort-Object { [datetime]$_.pubDate } | ForEach-Object {
    $title = $_.title
    $description = $_.description
    $retirementDate = "Unknown"
    $dates = @()

    # Improved regex for extracting dates
    if ($description -match "(?i)(?:retires|end of support|effective|on|as of|scheduled for)\s+(\w+\s+\d{1,2},?\s+\d{4})") {
        $dates += $matches[1]
    }
    
    if ($title -match "(?i)(?:from|by)\s+(\w+\s+\d{1,2},?\s+\d{4})") {
        $dates += $matches[1]
    }

    # Parse dates to datetime objects
    $validDates = $dates | ForEach-Object {
        try { [datetime]::Parse($_) } catch { $null }
    } | Where-Object { $_ }

    # Get the latest retirement date
    if ($validDates.Count -gt 0) {
        $retirementDate = ($validDates | Sort-Object -Descending | Select-Object -First 1).ToString("MMMM dd, yyyy")
    }

    # Format publish date
    $pubDate = [datetime]$_.pubDate
    $formattedPubDate = $pubDate.ToString("MMMM dd, yyyy")

    [PSCustomObject]@{
        PubDate        = $formattedPubDate
        Title          = $title
        RetirementDate = $retirementDate
        Link           = $_.link
    }
}

# Display results
$sortedRetirements | Format-Table -Property PubDate, RetirementDate, Title, Link -AutoSize
