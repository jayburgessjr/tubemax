' SearchScreen.brs

sub init()
    m.searchText  = ""
    m.results     = []
    m.keyFocusRow = 0
    m.keyFocusCol = 0
    m.resultFocusIndex = 0
    m.mode        = "keyboard" ' "keyboard" or "results"

    m.keyRows = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L","⌫"],
        ["Z","X","C","V","B","N","M","SPACE","SEARCH",""]
    ]

    buildKeyboard()
end sub

sub buildKeyboard()
    keyboard = m.top.findNode("keyboard")
    if keyboard = invalid then return

    keyW = 62
    keyH = 58
    keyGap = 6

    for row = 0 to m.keyRows.count() - 1
        keys = m.keyRows[row]
        for col = 0 to keys.count() - 1
            keyLabel = keys[col]
            if keyLabel = "" then
                col++
                continue for
            end if

            w = keyW
            if keyLabel = "SPACE"  then w = 160
            if keyLabel = "SEARCH" then w = 160
            if keyLabel = "⌫"      then w = keyW

            keyBg = createObject("roSGNode", "Rectangle")
            keyBg.id = "key_" + row.toStr() + "_" + col.toStr()
            keyBg.width = w
            keyBg.height = keyH
            keyBg.color = "0x2A2A2AFF"
            keyBg.cornerRadius = 6

            xPos = 0
            for c = 0 to col - 1
                kw = keyW
                k = m.keyRows[row][c]
                if k = "SPACE" or k = "SEARCH" then kw = 160
                xPos += kw + keyGap
            end for

            keyBg.translation = [xPos, row * (keyH + keyGap)]
            keyboard.appendChild(keyBg)

            label = createObject("roSGNode", "Label")
            label.id = "keylabel_" + row.toStr() + "_" + col.toStr()
            label.text = keyLabel
            label.translation = [xPos + (w / 2) - 15, row * (keyH + keyGap) + 16]
            label.color = "0xFFFFFFFF"
            label.font = "font:SmallBoldSystemFont"
            keyboard.appendChild(label)
        end for
    end for

    highlightKey(0, 0)
end sub

sub highlightKey(row as integer, col as integer)
    ' Unhighlight old key
    oldBg = m.top.findNode("key_" + m.keyFocusRow.toStr() + "_" + m.keyFocusCol.toStr())
    if oldBg <> invalid then oldBg.color = "0x2A2A2AFF"

    ' Highlight new key
    m.keyFocusRow = row
    m.keyFocusCol = col
    newBg = m.top.findNode("key_" + row.toStr() + "_" + col.toStr())
    if newBg <> invalid then newBg.color = "0xE50914FF"
end sub

sub pressCurrentKey()
    keys = m.keyRows[m.keyFocusRow]
    key = keys[m.keyFocusCol]

    if key = "⌫"
        if len(m.searchText) > 0
            m.searchText = left(m.searchText, len(m.searchText) - 1)
        end if
    else if key = "SPACE"
        m.searchText += " "
    else if key = "SEARCH"
        performSearch()
        return
    else
        m.searchText += key
    end if

    updateSearchDisplay()
end sub

sub updateSearchDisplay()
    inputLabel = m.top.findNode("searchInput")
    placeholder = m.top.findNode("searchPlaceholder")
    cursor = m.top.findNode("searchCursor")

    if inputLabel <> invalid then inputLabel.text = m.searchText
    if placeholder <> invalid then placeholder.visible = (m.searchText = "")
    if cursor <> invalid then cursor.translation = [110 + (len(m.searchText) * 12), 156]
end sub

sub performSearch()
    if m.searchText = "" then return

    resultsLabel = m.top.findNode("resultsLabel")
    if resultsLabel <> invalid then resultsLabel.text = "Searching..."

    m.task = createObject("roSGNode", "ApiTask")
    m.task.apiKey = m.top.apiKey
    m.task.endpoint = "search"
    m.task.params = {
        part: "snippet",
        q: m.searchText,
        type: "video",
        maxResults: "12",
        order: "relevance"
    }
    m.task.observeField("result", "onSearchResults")
    m.task.control = "RUN"
end sub

sub onSearchResults()
    result = m.task.result
    if result = invalid then return

    m.results = []
    items = result.items
    if items = invalid then return

    for each item in items
        if item.id <> invalid and item.id.videoId <> invalid
            thumb = ""
            if item.snippet.thumbnails.medium <> invalid
                thumb = item.snippet.thumbnails.medium.url
            end if
            entry = {
                videoId: item.id.videoId,
                title:   item.snippet.title,
                channel: item.snippet.channelTitle,
                thumb:   thumb
            }
            m.results.push(entry)
        end if
    end for

    resultsLabel = m.top.findNode("resultsLabel")
    if resultsLabel <> invalid then resultsLabel.text = m.results.count().toStr() + " results for """ + m.searchText + """"

    renderResults()
    m.mode = "results"
    m.resultFocusIndex = 0
    highlightResult(0)
end sub

sub renderResults()
    resultsGroup = m.top.findNode("resultsGroup")
    if resultsGroup = invalid then return
    resultsGroup.removeChildrenIndex(0, resultsGroup.getChildCount())

    cardW = 240
    cardH = 136
    gapX  = 14
    gapY  = 80
    cols  = 4

    for i = 0 to m.results.count() - 1
        data = m.results[i]
        col = i mod cols
        row = i \ cols

        card = createObject("roSGNode", "Group")
        card.id = "result_" + i.toStr()
        card.translation = [col * (cardW + gapX), row * (cardH + gapY)]

        bg = createObject("roSGNode", "Rectangle")
        bg.id = "resultBg"
        bg.width = cardW
        bg.height = cardH
        bg.color = "0x2A2A2AFF"
        bg.cornerRadius = 6
        card.appendChild(bg)

        if data.thumb <> "" and data.thumb <> invalid
            poster = createObject("roSGNode", "Poster")
            poster.uri = data.thumb
            poster.width = cardW
            poster.height = cardH
            card.appendChild(poster)
        end if

        border = createObject("roSGNode", "Rectangle")
        border.id = "resultBorder"
        border.width = cardW + 6
        border.height = cardH + 6
        border.translation = [-3, -3]
        border.color = "0xE50914FF"
        border.cornerRadius = 8
        border.visible = false
        card.appendChild(border)

        titleLabel = createObject("roSGNode", "Label")
        titleLabel.text = data.title
        titleLabel.translation = [0, cardH + 6]
        titleLabel.width = cardW
        titleLabel.wrap = true
        titleLabel.color = "0xFFFFFFFF"
        titleLabel.font = "font:SmallSystemFont"
        card.appendChild(titleLabel)

        resultsGroup.appendChild(card)
    end for
end sub

sub highlightResult(index as integer)
    resultsGroup = m.top.findNode("resultsGroup")
    if resultsGroup = invalid then return

    for i = 0 to resultsGroup.getChildCount() - 1
        card = resultsGroup.getChild(i)
        if card <> invalid
            border = card.findNode("resultBorder")
            if border <> invalid then border.visible = (i = index)
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back"
        if m.mode = "results"
            m.mode = "keyboard"
            return true
        end if
        m.top.searchClosed = true
        return true
    end if

    if m.mode = "keyboard"
        return handleKeyboardNav(key)
    else
        return handleResultsNav(key)
    end if
end function

function handleKeyboardNav(key as string) as boolean
    if key = "OK"
        pressCurrentKey()
        return true
    end if

    if key = "right"
        newCol = m.keyFocusCol + 1
        if newCol < m.keyRows[m.keyFocusRow].count() and m.keyRows[m.keyFocusRow][newCol] <> ""
            highlightKey(m.keyFocusRow, newCol)
        end if
        return true
    end if

    if key = "left"
        newCol = m.keyFocusCol - 1
        if newCol >= 0
            highlightKey(m.keyFocusRow, newCol)
        end if
        return true
    end if

    if key = "down"
        newRow = m.keyFocusRow + 1
        if newRow < m.keyRows.count()
            col = m.keyFocusCol
            if col >= m.keyRows[newRow].count() then col = m.keyRows[newRow].count() - 1
            highlightKey(newRow, col)
        end if
        return true
    end if

    if key = "up"
        newRow = m.keyFocusRow - 1
        if newRow >= 0
            highlightKey(newRow, m.keyFocusCol)
        end if
        return true
    end if

    return false
end function

function handleResultsNav(key as string) as boolean
    cols = 4
    if key = "OK" or key = "play"
        if m.results.count() > m.resultFocusIndex
            data = m.results[m.resultFocusIndex]
            m.top.videoSelected = {videoId: data.videoId, title: data.title}
        end if
        return true
    end if

    if key = "right"
        if m.resultFocusIndex < m.results.count() - 1
            m.resultFocusIndex++
            highlightResult(m.resultFocusIndex)
        end if
        return true
    end if

    if key = "left"
        if m.resultFocusIndex > 0
            m.resultFocusIndex--
            highlightResult(m.resultFocusIndex)
        end if
        return true
    end if

    if key = "down"
        newIdx = m.resultFocusIndex + cols
        if newIdx < m.results.count()
            m.resultFocusIndex = newIdx
            highlightResult(m.resultFocusIndex)
        end if
        return true
    end if

    if key = "up"
        newIdx = m.resultFocusIndex - cols
        if newIdx >= 0
            m.resultFocusIndex = newIdx
            highlightResult(m.resultFocusIndex)
        else
            m.mode = "keyboard"
        end if
        return true
    end if

    return false
end function
