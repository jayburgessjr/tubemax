' HeroBanner.brs

sub init()
    m.heroData = []
    m.currentIndex = 0
    m.focusedBtn = "play" ' "play" or "info"

    ' Auto-rotate timer
    m.rotateTimer = createObject("roSGNode", "Timer")
    m.rotateTimer.duration = 8
    m.rotateTimer.repeat = true
    m.rotateTimer.observeField("fire", "onRotate")
end sub

sub onApiKeySet()
    if m.top.apiKey = "" then return
    fetchHeroVideos()
end sub

sub fetchHeroVideos()
    m.task = createObject("roSGNode", "ApiTask")
    m.task.apiKey = m.top.apiKey
    m.task.endpoint = "videos"
    m.task.params = {
        part: "snippet,contentDetails",
        chart: "mostPopular",
        maxResults: "5",
        videoCategoryId: "0",
        regionCode: "US"
    }
    m.task.observeField("result", "onHeroDataLoaded")
    m.task.control = "RUN"
end sub

sub onHeroDataLoaded()
    result = m.task.result
    if result = invalid or result.items = invalid then return

    m.heroData = []
    for each item in result.items
        entry = {
            videoId: item.id,
            title:   item.snippet.title,
            desc:    item.snippet.description,
            thumb:   item.snippet.thumbnails.maxres?.url
        }
        if entry.thumb = invalid
            entry.thumb = item.snippet.thumbnails.high?.url
        end if
        m.heroData.push(entry)
    end for

    if m.heroData.count() > 0
        displayHero(0)
        m.rotateTimer.control = "start"
    end if
end sub

sub displayHero(index as integer)
    if m.heroData.count() = 0 then return
    m.currentIndex = index

    data = m.heroData[index]

    heroTitle = m.top.findNode("heroTitle")
    heroDesc  = m.top.findNode("heroDesc")
    heroThumb = m.top.findNode("heroThumb")

    heroTitle.text = data.title
    heroDesc.text  = left(data.desc, 200)
    if data.thumb <> "" and data.thumb <> invalid
        heroThumb.uri = data.thumb
    end if
end sub

sub onRotate()
    nextIndex = (m.currentIndex + 1) mod m.heroData.count()
    displayHero(nextIndex)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK" or key = "play"
        fireVideoSelected()
        return true
    end if

    if key = "right" and m.focusedBtn = "play"
        m.focusedBtn = "info"
        highlightBtn("info")
        return true
    end if

    if key = "left" and m.focusedBtn = "info"
        m.focusedBtn = "play"
        highlightBtn("play")
        return true
    end if

    if key = "down"
        ' Pass focus to content rows
        return false
    end if

    return false
end function

sub fireVideoSelected()
    if m.heroData.count() = 0 then return
    data = m.heroData[m.currentIndex]
    m.top.videoSelected = {
        videoId: data.videoId,
        title:   data.title
    }
end sub

sub highlightBtn(btn as string)
    playBtn  = m.top.findNode("playBtn")
    infoBtn  = m.top.findNode("infoBtn")

    if btn = "play"
        playBtn.color = "0xFFFFFFFF"
        infoBtn.color = "0x6D6D6DBB"
    else
        playBtn.color = "0x6D6D6DBB"
        infoBtn.color = "0x9A9A9ABB"
    end if
end sub
