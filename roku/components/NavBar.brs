' NavBar.brs

sub init()
    m.tabs = ["Home", "Search", "Trending", "Watchlist"]
    m.tabOffsets = [0, 130, 280, 440]
end sub

sub onActiveTabChange()
    activeTab = m.top.activeTab
    navItems = m.top.findNode("navItems")
    activeBar = m.top.findNode("activeBar")

    for i = 0 to m.tabs.count() - 1
        label = navItems.findNode("tab_" + m.tabs[i])
        if label <> invalid
            if m.tabs[i] = activeTab
                label.color = "0xFFFFFFFF"
                label.font = "font:MediumBoldSystemFont"
                activeBar.translation = [320 + m.tabOffsets[i], 76]
            else
                label.color = "0xA0A0A0FF"
                label.font = "font:MediumSystemFont"
            end if
        end if
    end for
end sub
