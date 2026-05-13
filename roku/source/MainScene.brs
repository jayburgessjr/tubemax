' TubeMax — MainScene.brs
' App-level controller: screen routing, global state, key handling

sub init()
    m.homeScreen   = m.top.findNode("homeScreen")
    m.playerScreen = m.top.findNode("playerScreen")
    m.searchScreen = m.top.findNode("searchScreen")
    m.loadingOverlay = m.top.findNode("loadingOverlay")
    m.toastGroup   = m.top.findNode("toastGroup")
    m.toastLabel   = m.top.findNode("toastLabel")
    m.toastBg      = m.top.findNode("toastBg")

    m.currentScreen = "home"
    m.apiKey = CreateObject("roAppInfo").GetValue("API_KEY")

    buildHomeScreen()
    m.top.setFocus(true)
end sub

' ─────────────────────────────────────────────
' SCREEN BUILDERS
' ─────────────────────────────────────────────

sub buildHomeScreen()
    ' Clear existing children
    m.homeScreen.removeChildrenIndex(0, m.homeScreen.getChildCount())

    ' Nav Bar
    nav = createObject("roSGNode", "NavBar")
    nav.id = "navBar"
    m.homeScreen.appendChild(nav)

    ' Hero Banner
    hero = createObject("roSGNode", "HeroBanner")
    hero.id = "heroBanner"
    hero.translation = [0, 108]
    hero.observeField("videoSelected", "onHeroVideoSelected")
    m.homeScreen.appendChild(hero)

    ' Content Rows Container
    rowsGroup = createObject("roSGNode", "Group")
    rowsGroup.id = "rowsGroup"
    rowsGroup.translation = [0, 540]
    m.homeScreen.appendChild(rowsGroup)

    ' Build content rows
    buildContentRows(rowsGroup)
end sub

sub buildContentRows(parent as object)
    rowDefs = [
        {label: "Continue Watching",   query: "continue",                  type: "history"},
        {label: "My Subscriptions",    query: "subscriptions",             type: "subscriptions"},
        {label: "Trending Now",        query: "trending",                  type: "trending"},
        {label: "Sports",              query: "sports highlights 2025",    type: "search"},
        {label: "News",                query: "world news today",          type: "search"},
        {label: "Music Videos",        query: "official music video 2025", type: "search"},
        {label: "Tech & Science",      query: "technology science 2025",   type: "search"},
        {label: "Movies",              query: "full movie 4K",             type: "search"},
        {label: "Gaming",              query: "gaming gameplay 2025",      type: "search"},
        {label: "Comedy",              query: "comedy stand up 2025",      type: "search"},
        {label: "Short Films & Shorts",query: "short film award winning",  type: "search"}
    ]

    yOffset = 0
    for each rowDef in rowDefs
        row = createObject("roSGNode", "ContentRow")
        row.id = "row_" + rowDef.label
        row.translation = [0, yOffset]
        row.rowLabel = rowDef.label
        row.queryString = rowDef.query
        row.queryType = rowDef.type
        row.apiKey = m.apiKey
        row.observeField("videoSelected", "onRowVideoSelected")
        parent.appendChild(row)
        yOffset += 220
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
' NAVIGATION
' ─────────────────────────────────────────────

sub showScreen(screenName as string)
    m.homeScreen.visible   = (screenName = "home")
    m.playerScreen.visible = (screenName = "player")
    m.searchScreen.visible = (screenName = "search")
    m.currentScreen = screenName
end sub

sub showLoading(show as boolean)
    m.loadingOverlay.visible = show
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
    ' Find which row fired — iterate all rows
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
    buildPlayerScreen(videoId, title)
    showScreen("player")
    player = m.playerScreen.findNode("videoPlayer")
    if player <> invalid then player.setFocus(true)
end sub

sub onPlayerClosed()
    showScreen("home")
    m.top.setFocus(true)
end sub

sub onSearchClosed()
    showScreen("home")
    m.top.setFocus(true)
end sub

' ─────────────────────────────────────────────
' KEY HANDLING
' ─────────────────────────────────────────────

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back"
        if m.currentScreen = "player"
            onPlayerClosed()
            return true
        else if m.currentScreen = "search"
            onSearchClosed()
            return true
        end if
    end if

    if key = "search" or key = "options"
        if m.currentScreen = "home"
            buildSearchScreen()
            showScreen("search")
            inner = m.searchScreen.findNode("searchScreen_inner")
            if inner <> invalid then inner.setFocus(true)
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
    m.toastBg.width = 400
    m.toastBg.height = 50
    m.toastBg.translation = [760, 36]
    m.toastGroup.visible = true

    ' Auto-hide after 3 seconds
    timer = createObject("roSGNode", "Timer")
    timer.duration = 3
    timer.repeat = false
    timer.observeField("fire", "hideToast")
    timer.control = "start"
    m.toastGroup.appendChild(timer)
end sub

sub hideToast()
    m.toastGroup.visible = false
end sub
