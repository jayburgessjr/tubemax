' TubeMax — MainScene.brs
' App-level controller: screen routing, focus management, key handling

sub init()
    m.homeScreen      = m.top.findNode("homeScreen")
    m.playerScreen    = m.top.findNode("playerScreen")
    m.searchScreen    = m.top.findNode("searchScreen")
    m.loadingOverlay  = m.top.findNode("loadingOverlay")
    m.toastGroup      = m.top.findNode("toastGroup")
    m.toastLabel      = m.top.findNode("toastLabel")
    m.toastBg         = m.top.findNode("toastBg")

    m.currentScreen   = "home"
    m.focusedRowIndex = -1  ' -1 = hero has focus
    m.apiKey          = CreateObject("roAppInfo").GetValue("API_KEY")

    buildHomeScreen()
end sub

' ─────────────────────────────────────────────
' SCREEN BUILDERS
' ─────────────────────────────────────────────

sub buildHomeScreen()
    m.homeScreen.removeChildrenIndex(0, m.homeScreen.getChildCount())

    ' Nav Bar (visual chrome only)
    nav = createObject("roSGNode", "NavBar")
    nav.id = "navBar"
    nav.activeTab = "Home"
    m.homeScreen.appendChild(nav)

    ' Hero Banner
    hero = createObject("roSGNode", "HeroBanner")
    hero.id = "heroBanner"
    hero.translation = [0, 72]
    hero.apiKey = m.apiKey
    hero.observeField("videoSelected", "onHeroVideoSelected")
    m.homeScreen.appendChild(hero)

    ' Content Rows Container
    rowsGroup = createObject("roSGNode", "Group")
    rowsGroup.id = "rowsGroup"
    rowsGroup.translation = [0, 510]
    m.homeScreen.appendChild(rowsGroup)

    buildContentRows(rowsGroup)

    ' Give initial focus to the hero
    focusHero()
end sub

sub buildContentRows(parent as object)
    rowDefs = [
        {label: "Continue Watching",    query: "continue",                  type: "history"},
        {label: "Trending Now",         query: "trending",                  type: "trending"},
        {label: "Sports",               query: "sports highlights 2025",    type: "search"},
        {label: "News",                 query: "world news today",          type: "search"},
        {label: "Music Videos",         query: "official music video 2025", type: "search"},
        {label: "Tech & Science",       query: "technology science 2025",   type: "search"},
        {label: "Movies",               query: "full movie 4K",             type: "search"},
        {label: "Gaming",               query: "gaming gameplay 2025",      type: "search"},
        {label: "Comedy",               query: "comedy stand up 2025",      type: "search"},
        {label: "Short Films & Shorts", query: "short film award winning",  type: "search"}
    ]

    yOffset = 0
    for each rowDef in rowDefs
        row = createObject("roSGNode", "ContentRow")
        row.id = "row_" + rowDef.label.replace(" ", "_")
        row.translation = [0, yOffset]
        row.rowLabel = rowDef.label
        row.queryString = rowDef.query
        row.queryType = rowDef.type
        row.apiKey = m.apiKey
        row.observeField("videoSelected", "onRowVideoSelected")
        parent.appendChild(row)
        yOffset += 250
    end for
end sub

sub buildPlayerScreen(videoId as string, videoTitle as string)
    m.playerScreen.removeChildrenIndex(0, m.playerScreen.getChildCount())
    player = createObject("roSGNode", "VideoPlayer")
    player.id = "videoPlayer"
    player.videoId = videoId
    player.videoTitle = videoTitle
    player.apiKey = m.apiKey
    player.observeField("playerClosed", "onPlayerClosed")
    m.playerScreen.appendChild(player)
end sub

sub buildSearchScreen()
    m.searchScreen.removeChildrenIndex(0, m.searchScreen.getChildCount())
    search = createObject("roSGNode", "SearchScreen")
    search.id = "searchScreen_inner"
    search.apiKey = m.apiKey
    search.observeField("videoSelected", "onSearchVideoSelected")
    search.observeField("searchClosed", "onSearchClosed")
    m.searchScreen.appendChild(search)
end sub

' ─────────────────────────────────────────────
' FOCUS MANAGEMENT
' ─────────────────────────────────────────────

sub focusHero()
    hero = m.homeScreen.findNode("heroBanner")
    if hero = invalid then return

    ' Clear focus on any previously focused row
    clearRowFocus()

    m.focusedRowIndex = -1
    hero.focused = true
    hero.setFocus(true)

    ' Scroll rows back to default position
    rowsGroup = m.homeScreen.findNode("rowsGroup")
    if rowsGroup <> invalid then rowsGroup.translation = [0, 510]
end sub

sub focusRow(index as integer)
    rowsGroup = m.homeScreen.findNode("rowsGroup")
    if rowsGroup = invalid then return

    rowCount = rowsGroup.getChildCount()
    if index < 0 then index = 0
    if index >= rowCount then index = rowCount - 1

    ' Unfocus hero if it had focus
    if m.focusedRowIndex = -1
        hero = m.homeScreen.findNode("heroBanner")
        if hero <> invalid then hero.focused = false
    end if

    ' Unfocus previous row
    if m.focusedRowIndex >= 0 and m.focusedRowIndex < rowCount
        oldRow = rowsGroup.getChild(m.focusedRowIndex)
        if oldRow <> invalid then oldRow.focused = false
    end if

    m.focusedRowIndex = index
    row = rowsGroup.getChild(index)
    if row = invalid then return

    row.focused = true
    row.setFocus(true)

    ' Scroll rowsGroup so focused row is on screen
    ' Rows area starts at y=510; each row is 250px; screen height=1080
    ' Keep focused row top between y=510 and y=800
    scrollOffset = index * 250
    targetY = 510
    if scrollOffset > 200
        targetY = 510 - (scrollOffset - 200)
    end if
    ' Never scroll so rows appear above the hero bottom
    if targetY < 72 then targetY = 72
    rowsGroup.translation = [0, targetY]
end sub

sub clearRowFocus()
    rowsGroup = m.homeScreen.findNode("rowsGroup")
    if rowsGroup = invalid then return
    for i = 0 to rowsGroup.getChildCount() - 1
        r = rowsGroup.getChild(i)
        if r <> invalid then r.focused = false
    end for
end sub

' ─────────────────────────────────────────────
' NAVIGATION
' ─────────────────────────────────────────────

sub showScreen(screenName as string)
    m.homeScreen.visible   = (screenName = "home")
    m.playerScreen.visible = (screenName = "player")
    m.searchScreen.visible = (screenName = "search")
    m.currentScreen        = screenName
end sub

' ─────────────────────────────────────────────
' EVENT HANDLERS
' ─────────────────────────────────────────────

sub onHeroVideoSelected()
    hero = m.homeScreen.findNode("heroBanner")
    if hero = invalid then return
    data = hero.videoSelected
    if data = invalid then return
    navigateToPlayer(data.videoId, data.title)
end sub

sub onRowVideoSelected()
    rowsGroup = m.homeScreen.findNode("rowsGroup")
    if rowsGroup = invalid then return
    for i = 0 to rowsGroup.getChildCount() - 1
        row = rowsGroup.getChild(i)
        if row <> invalid and row.hasField("videoSelected")
            data = row.videoSelected
            if data <> invalid and data.videoId <> ""
                navigateToPlayer(data.videoId, data.title)
                exit for
            end if
        end if
    end for
end sub

sub onSearchVideoSelected()
    inner = m.searchScreen.findNode("searchScreen_inner")
    if inner = invalid then return
    data = inner.videoSelected
    if data = invalid then return
    navigateToPlayer(data.videoId, data.title)
end sub

sub navigateToPlayer(videoId as string, title as string)
    ' Deep link into the official YouTube Roku channel (ID 2285)
    ' User selects a video in TubeMax → YouTube app opens and plays it
    ' Pressing Back in YouTube returns the user to TubeMax
    appManager = CreateObject("roAppManager")
    launched = appManager.LaunchApp({
        id:     "2285",
        params: {
            contentid: videoId,
            mediatype: "episode"
        }
    })

    if not launched
        ' YouTube app not installed — show a toast
        showToast("Install the YouTube app to watch videos")
    end if
end sub

sub onPlayerClosed()
    ' Called if our internal player ever closes — return home
    showScreen("home")
    focusHero()
end sub

sub onSearchClosed()
    showScreen("home")
    ' Restore focus: return to hero
    focusHero()
end sub

' ─────────────────────────────────────────────
' KEY HANDLING — vertical navigation between hero and rows
' ─────────────────────────────────────────────

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if m.currentScreen = "home"
        ' DOWN: hero → row 0, row N → row N+1
        if key = "down"
            rowsGroup = m.homeScreen.findNode("rowsGroup")
            rowCount = 0
            if rowsGroup <> invalid then rowCount = rowsGroup.getChildCount()

            if m.focusedRowIndex = -1
                ' Hero → first row
                if rowCount > 0 then focusRow(0)
                return true
            else if m.focusedRowIndex < rowCount - 1
                ' Row N → Row N+1
                focusRow(m.focusedRowIndex + 1)
                return true
            end if
            return true
        end if

        ' UP: row 0 → hero, row N → row N-1
        if key = "up"
            if m.focusedRowIndex = 0
                ' First row → hero
                focusHero()
                return true
            else if m.focusedRowIndex > 0
                ' Row N → Row N-1
                focusRow(m.focusedRowIndex - 1)
                return true
            end if
            ' Already at hero, up does nothing
            return true
        end if

        ' BACK from home — exit app
        if key = "back"
            return false
        end if

        ' * or options key → search
        if key = "search" or key = "options"
            buildSearchScreen()
            showScreen("search")
            inner = m.searchScreen.findNode("searchScreen_inner")
            if inner <> invalid then inner.setFocus(true)
            return true
        end if
    end if

    if key = "back"
        if m.currentScreen = "player"
            onPlayerClosed()
            return true
        else if m.currentScreen = "search"
            onSearchClosed()
            return true
        end if
    end if

    return false
end function

' ─────────────────────────────────────────────
' TOAST HELPER
' ─────────────────────────────────────────────

sub showToast(msg as string)
    m.toastLabel.text = " " + msg + " "
    m.toastLabel.translation = [760, 40]
    m.toastBg.width  = 400
    m.toastBg.height = 50
    m.toastBg.translation = [760, 36]
    m.toastGroup.visible = true

    timer = createObject("roSGNode", "Timer")
    timer.duration = 3
    timer.repeat   = false
    timer.observeField("fire", "hideToast")
    timer.control  = "start"
    m.toastGroup.appendChild(timer)
end sub

sub hideToast()
    m.toastGroup.visible = false
end sub
