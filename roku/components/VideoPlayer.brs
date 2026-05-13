' VideoPlayer.brs
' Handles YouTube video resolution via unofficial stream + OSD controls

sub init()
    m.videoNode   = m.top.findNode("videoNode")
    m.osdOverlay  = m.top.findNode("osdOverlay")
    m.errorScreen = m.top.findNode("errorScreen")
    m.progressFill = m.top.findNode("progressFill")
    m.progressDot  = m.top.findNode("progressDot")
    m.currentTimeLabel = m.top.findNode("currentTime")
    m.totalTimeLabel   = m.top.findNode("totalTime")
    m.btnPlay     = m.top.findNode("btnPlay")

    m.isPlaying   = false
    m.osdVisible  = false
    m.totalSec    = 0
    m.currentSec  = 0

    ' OSD auto-hide timer
    m.osdTimer = createObject("roSGNode", "Timer")
    m.osdTimer.duration = 5
    m.osdTimer.repeat = false
    m.osdTimer.observeField("fire", "hideOSD")

    ' Progress update timer
    m.progressTimer = createObject("roSGNode", "Timer")
    m.progressTimer.duration = 1
    m.progressTimer.repeat = true
    m.progressTimer.observeField("fire", "updateProgress")

    ' Video state observer
    m.videoNode.observeField("state", "onVideoStateChange")
    m.videoNode.observeField("position", "onPositionChange")
end sub

sub onVideoIdSet()
    videoId = m.top.videoId
    if videoId = "" then return

    ' Update OSD title
    osdTitle = m.top.findNode("osdTitle")
    if osdTitle <> invalid then osdTitle.text = m.top.videoTitle

    ' Build video content object
    ' NOTE: YouTube requires stream URL resolution. We use the video's
    ' embed stream via Roku's built-in YouTube resolver when available,
    ' or the public stream URL pattern.
    fetchStreamUrl(videoId)
end sub

sub fetchStreamUrl(videoId as string)
    ' Use Roku's built-in YouTube URL scheme
    ' This resolves via the device's YouTube integration
    content = createObject("roSGNode", "ContentNode")
    content.url = "https://www.youtube.com/watch?v=" + videoId
    content.streamformat = "mp4"
    content.title = m.top.videoTitle

    ' Set playback metadata
    content.HDGRIDPOSTERURL = "https://img.youtube.com/vi/" + videoId + "/maxresdefault.jpg"

    m.videoNode.content = content
    m.videoNode.setFocus(true)
    m.videoNode.control = "play"
    m.isPlaying = true
    m.progressTimer.control = "start"
    showOSD()
end sub

sub onVideoStateChange()
    state = m.videoNode.state
    btnPlay = m.top.findNode("btnPlay")

    if state = "playing"
        m.isPlaying = true
        if btnPlay <> invalid then btnPlay.text = "Pause"
        m.progressTimer.control = "start"
    else if state = "paused"
        m.isPlaying = false
        if btnPlay <> invalid then btnPlay.text = " Play"
    else if state = "finished"
        m.top.playerClosed = true
    else if state = "error"
        showError()
    end if
end sub

sub onPositionChange()
    m.currentSec = m.videoNode.position
    updateProgress()
end sub

sub updateProgress()
    if m.totalSec = 0 and m.videoNode.duration > 0
        m.totalSec = m.videoNode.duration
        totalLabel = m.top.findNode("totalTime")
        if totalLabel <> invalid then totalLabel.text = formatTime(int(m.totalSec))
    end if

    m.currentSec = m.videoNode.position
    currentLabel = m.top.findNode("currentTime")
    if currentLabel <> invalid then currentLabel.text = formatTime(int(m.currentSec))

    ' Update progress bar
    if m.totalSec > 0
        pct = m.currentSec / m.totalSec
        fillWidth = int(1760 * pct)
        if m.progressFill <> invalid then m.progressFill.width = fillWidth
        if m.progressDot  <> invalid then m.progressDot.translation = [74 + fillWidth, 964]
    end if
end sub

function formatTime(sec as integer) as string
    mins = sec \ 60
    secs = sec mod 60
    secStr = secs.toStr()
    if secs < 10 then secStr = "0" + secStr
    return mins.toStr() + ":" + secStr
end function

sub showOSD()
    m.osdOverlay.visible = true
    m.osdVisible = true
    m.osdTimer.control = "start"
end sub

sub hideOSD()
    m.osdOverlay.visible = false
    m.osdVisible = false
end sub

sub showError()
    m.errorScreen.visible = true
    m.osdOverlay.visible = false
    m.progressTimer.control = "stop"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    ' Always show OSD on any key
    showOSD()

    if key = "back"
        m.videoNode.control = "stop"
        m.progressTimer.control = "stop"
        m.top.playerClosed = true
        return true
    end if

    if key = "OK" or key = "play"
        togglePlayPause()
        return true
    end if

    if key = "right" or key = "fastforward"
        m.videoNode.seek = m.currentSec + 10
        return true
    end if

    if key = "left" or key = "rewind"
        newPos = m.currentSec - 10
        if newPos < 0 then newPos = 0
        m.videoNode.seek = newPos
        return true
    end if

    return false
end function

sub togglePlayPause()
    if m.isPlaying
        m.videoNode.control = "pause"
    else
        m.videoNode.control = "resume"
    end if
end sub
