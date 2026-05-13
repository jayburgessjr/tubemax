' NavBar.brs

sub init()
    m.tabs       = ["Home", "Search", "Trending", "Watchlist"]
    m.tabOffsets = [0, 160, 320, 500]
    m.tabWidths  = [46, 60, 74, 80]
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
                activeBar.translation = [380 + m.tabOffsets[i], 74]
                activeBar.width = m.tabWidths[i]
            else
                label.color = "0xB3B3B3FF"
                label.font = "font:MediumSystemFont"
            end if
        end if
    end for
end sub
