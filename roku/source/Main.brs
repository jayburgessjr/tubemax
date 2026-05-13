' Main.brs — App entry point

sub Main(args as dynamic)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    scene = screen.CreateScene("MainScene")
    screen.show()

    ' Handle deep link launch args
    if args <> invalid
        if args.contentId <> invalid and args.contentId <> ""
            scene.launchVideoId = args.contentId
        end if
    end if

    while true
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then exit while
        end if
    end while
end sub
