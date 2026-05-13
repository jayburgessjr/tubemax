' NavBar.brs

sub init()
    m.tabs       = ["Home", "Search", "Trending", "Watchlist"]
    m.tabOffsets = [0, 150, 300, 470]
    m.tabWidths  = [50, 60, 74, 80]
end sub

sub onActiveTabChange()
    activeTab = m.top.activeTab
    navItems  = m.top.findNode("navItems")
    activeBar = m.top.findNode("activeBar")

    for i = 0 to m.tabs.count() - 1
        label = navItems.findNode("tab_" + m.tabs[i])
        if label <> invalid
            if m.tabs[i] = activeTab
                label.color = "0xFFFFFFFF"
                label.font = "font:MediumBoldSystemFont"
                activeBar.translation = [360 + m.tabOffsets[i], 68]
                activeBar.width = m.tabWidths[i]
            else
                label.color = "0x808080FF"
                label.font = "font:MediumSystemFont"
            end if
        end if
    end for
end sub
