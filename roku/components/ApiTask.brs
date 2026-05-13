' ApiTask.brs
' Runs in background thread — makes YouTube Data API v3 calls

sub init()
    m.top.functionName = "fetchData"
end sub

sub fetchData()
    apiKey   = m.top.apiKey
    endpoint = m.top.endpoint
    params   = m.top.params

    if apiKey = "" or apiKey = "YOUR_YOUTUBE_API_KEY_HERE"
        ' Return mock data so app is testable before API key is added
        m.top.result = getMockData(endpoint)
        return
    end if

    baseUrl = "https://www.googleapis.com/youtube/v3/" + endpoint

    ' Build query string
    queryStr = "?key=" + apiKey
    for each k in params
        queryStr += "&" + k + "=" + urlEncode(params[k])
    end for

    url = baseUrl + queryStr

    http = createObject("roUrlTransfer")
    http.setUrl(url)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.initClientCertificates()
    http.addHeader("Content-Type", "application/json")
    http.enableEncodings(true)

    response = http.getToString()

    if response = "" or response = invalid
        m.top.result = {items: []}
        return
    end if

    parsed = parseJSON(response)
    if parsed = invalid
        m.top.result = {items: []}
        return
    end if

    m.top.result = parsed
end sub

function urlEncode(str as string) as string
    http = createObject("roUrlTransfer")
    return http.escape(str)
end function

' ─────────────────────────────────────────────
' MOCK DATA — used when no API key is set
' Lets you sideload and test the UI immediately
' ─────────────────────────────────────────────

function getMockData(endpoint as string) as object
    mockItems = []

    mockTitles = [
        "The Last of Us Season 2 — Official Trailer",
        "Lakers vs. Warriors | Full Game Highlights",
        "Tesla Cybertruck Review: 6 Months Later",
        "How Black Holes Actually Work",
        "Travis Scott — CIRCUS MAXIMUS Live",
        "iPhone 17 Unboxing & First Look",
        "Custom PC Build 2025 — Ultimate Setup",
        "Top 10 Most Beautiful Places on Earth",
        "NASA Artemis Moon Landing Footage",
        "Gordon Ramsay's Perfect Steak",
        "Spider-Man: Brand New Day Official Trailer",
        "NBA Top 50 Plays of the Year"
    ]

    thumbBases = [
        "https://picsum.photos/seed/",
    ]

    for i = 0 to 11
        mockId = "dQw4w9WgXcQ" ' placeholder video id

        item = {
            id:      {videoId: mockId},
            snippet: {
                title:        mockTitles[i],
                description:  "Sample description for " + mockTitles[i],
                channelTitle: "TubeMax Demo",
                thumbnails: {
                    medium: {url: "https://picsum.photos/seed/" + i.toStr() + "/480/270"},
                    high:   {url: "https://picsum.photos/seed/" + i.toStr() + "/640/360"}
                }
            }
        }

        if endpoint = "videos"
            ' videos endpoint returns id as string, not object
            item.id = "dQw4w9WgXcQ_" + i.toStr()
        end if

        mockItems.push(item)
    end for

    return {items: mockItems}
end function
