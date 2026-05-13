' ContentRow.brs

sub init()
    m.videos      = []
    m.focusIndex  = 0
    m.cardWidth   = 300
    m.cardGap     = 16
    m.visibleCards = 5
    m.scrollOffset = 0
end sub

sub onLabelSet()
    label = m.top.findNode("rowTitle")
    if label <> invalid then label.text = m.top.rowLabel
end sub

sub onApiKeySet()
    if m.top.apiKey = "" then return
    fetchVideos()
end sub

sub fetchVideos()
    m.task = createObject("roSGNode", "ApiTask")
    m.task.apiKey = m.top.apiKey

    if m.top.queryType = "trending"
        m.task.endpoint = "videos"
        m.task.params = {
            part: "snippet",
            chart: "mostPopular",
            maxResults: "12",
            regionCode: "US"
        }
    else
        m.task.endpoint = "search"
        m.task.params = {
            part: "snippet",
            q: m.top.queryString,
            type: "video",
            maxResults: "12",
            order: "relevance",
            videoDuration: "medium"
        }
    end if

    m.task.observeField("result", "onVideosLoaded")
    m.task.control = "RUN"
end sub

sub onVideosLoaded()
    result = m.task.result
    if result = invalid then return

    loadingLabel = m.top.findNode("loadingLabel")
    if loadingLabel <> invalid then loadingLabel.visible = false

    m.videos = []
    items = result.items
    if items = invalid then return

    for each item in items
        videoId = ""
        if m.top.queryType = "trending"
            videoId = item.id
        else
            if item.id <> invalid and item.id.videoId <> invalid
                videoId = item.id.videoId
            end if
        end if

        if videoId <> "" and videoId <> invalid
            thumb = ""
            if item.snippet.thumbnails.medium <> invalid
                thumb = item.snippet.thumbnails.medium.url
            else if item.snippet.thumbnails.default <> invalid
                thumb = item.snippet.thumbnails.default.url
            end if

            entry = {
                videoId: videoId,
                title:   item.snippet.title,
                channel: item.snippet.channelTitle,
                thumb:   thumb
            }
            m.videos.push(entry)
        end if
    end for

    renderCards()
end sub

sub renderCards()
    cardsGroup = m.top.findNode("cardsGroup")
    if cardsGroup = invalid then return

    cardsGroup.removeChildrenIndex(0, cardsGroup.getChildCount())

    xPos = 0
    for i = 0 to m.videos.count() - 1
        card = buildCard(m.videos[i], i, xPos)
        cardsGroup.appendChild(card)
        xPos += m.cardWidth + m.cardGap
    end for
end sub

function buildCard(data as object, index as integer, xPos as integer) as object
    card = createObject("roSGNode", "Group")
    card.id = "card_" + index.toStr()
    card.translation = [xPos, 0]

    ' Thumbnail background
    bg = createObject("roSGNode", "Rectangle")
    bg.id = "cardBg"
    bg.width = m.cardWidth
    bg.height = 170
    bg.color = "0x2A2A2AFF"
    bg.cornerRadius = 6
    card.appendChild(bg)

    ' Thumbnail image
    if data.thumb <> "" and data.thumb <> invalid
        poster = createObject("roSGNode", "Poster")
        poster.uri = data.thumb
        poster.width = m.cardWidth
        poster.height = 170
        card.appendChild(poster)
    end if

    ' Focus border (hidden by default)
    border = createObject("roSGNode", "Rectangle")
    border.id = "focusBorder"
    border.width = m.cardWidth + 6
    border.height = 176
    border.translation = [-3, -3]
    border.color = "0xE50914FF"
    border.cornerRadius = 8
    border.visible = false
    card.appendChild(border)

    ' Title label
    titleLabel = createObject("roSGNode", "Label")
    titleLabel.id = "cardTitle"
    titleLabel.text = data.title
    titleLabel.translation = [0, 178]
    titleLabel.width = m.cardWidth
    titleLabel.wrap = true
    titleLabel.color = "0xFFFFFFFF"
    titleLabel.font = "font:SmallSystemFont"
    card.appendChild(titleLabel)

    ' Channel label
    chanLabel = createObject("roSGNode", "Label")
    chanLabel.id = "cardChannel"
    chanLabel.text = data.channel
    chanLabel.translation = [0, 208]
    chanLabel.color = "0x808080FF"
    chanLabel.font = "font:SmallSystemFont"
    card.appendChild(chanLabel)

    return card
end function

sub updateFocusVisuals()
    cardsGroup = m.top.findNode("cardsGroup")
    if cardsGroup = invalid then return

    for i = 0 to cardsGroup.getChildCount() - 1
        card = cardsGroup.getChild(i)
        if card <> invalid
            border = card.findNode("focusBorder")
            bg     = card.findNode("cardBg")
            if border <> invalid
                border.visible = (i = m.focusIndex)
            end if
            if bg <> invalid
                if i = m.focusIndex
                    bg.color = "0x3A3A3AFF"
                else
                    bg.color = "0x2A2A2AFF"
                end if
            end if
        end if
    end for
end sub

sub scrollToFocus()
    cardsGroup = m.top.findNode("cardsGroup")
    if cardsGroup = invalid then return

    ' Calculate scroll so focused card is visible
    targetX = -(m.focusIndex * (m.cardWidth + m.cardGap))
    ' Keep first card from going too far right
    if targetX > 0 then targetX = 0
    cardsGroup.translation = [targetX, 0]
end sub

sub onFocusChange()
    if m.top.hasFocus
        updateFocusVisuals()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "right"
        if m.focusIndex < m.videos.count() - 1
            m.focusIndex++
            updateFocusVisuals()
            scrollToFocus()
        end if
        return true
    end if

    if key = "left"
        if m.focusIndex > 0
            m.focusIndex--
            updateFocusVisuals()
            scrollToFocus()
        else
            return false ' Let parent handle (go to nav)
        end if
        return true
    end if

    if key = "OK" or key = "play"
        if m.videos.count() > m.focusIndex
            data = m.videos[m.focusIndex]
            m.top.videoSelected = {
                videoId: data.videoId,
                title:   data.title
            }
        end if
        return true
    end if

    return false
end function
