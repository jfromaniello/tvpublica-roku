' ********************************************************************
' ********************************************************************
' **  Roku Custom Video Player Channel (BrightScript)
' **
' **  May 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

Sub RunUserInterface()
    o = Setup()
    o.setup()
    o.paint()
    o.eventloop()
End Sub

Sub Setup() As Object
    this = {
        port:      CreateObject("roMessagePort")
        progress:  0 'buffering progress
        position:  0 'playback position (in seconds)
        paused:    false 'is the video currently paused?
        fonts:     CreateObject("roFontRegistry") 'global font registry
        canvas:    CreateObject("roImageCanvas") 'user interface
        player:    CreateObject("roVideoPlayer")
        setup:     SetupFullscreenCanvas
        paint:     PaintFullscreenCanvas
        eventloop: EventLoop
    }

    'Register available fonts:
    this.fonts.Register("pkg:/fonts/caps.otf")
    this.textcolor = "#406040"

    'Setup image canvas:
    this.canvas.SetMessagePort(this.port)
    this.canvas.SetLayer(0, { Color: "#000000" })
    this.canvas.Show()

    'Resolution-specific settings:
    mode = CreateObject("roDeviceInfo").GetDisplayMode()
    if mode = "720p"
        this.layout = {
            full:   this.canvas.GetCanvasRect()
            top:    { x:   0, y:   0, w:1280, h: 130 }
            left:   { x: 249, y: 177, w: 391, h: 291 }
            right:  { x: 700, y: 177, w: 350, h: 291 }
            bottom: { x: 249, y: 500, w: 780, h: 300 }
        }
        this.background = "pkg:/images/back-hd.jpg"
        this.headerfont = this.fonts.get("lmroman10 caps", 50, 50, false)
    else
        this.layout = {
            full:   this.canvas.GetCanvasRect()
            top:    { x:   0, y:   0, w: 720, h:  80 }
            left:   { x: 100, y: 100, w: 280, h: 210 }
            right:  { x: 400, y: 100, w: 220, h: 210 }
            bottom: { x: 100, y: 340, w: 520, h: 140 }
        }
        this.background = "pkg:/images/back-sd.jpg"
        this.headerfont = this.fonts.get("lmroman10 caps", 30, 50, false)
    end if

    this.player.SetMessagePort(this.port)
    this.player.SetLoop(true)
    this.player.SetPositionNotificationPeriod(1)
    this.player.SetDestinationRect({ x:0, y:0, w:0, h:0 })
    this.player.AddHeader("User-Agent", "Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.10")
    this.player.SetContentList([{
        Stream: { url: "http://prepublish.f.qaotic.net/a02/ngrp:c7live01-20034_all/Playlist.m3u8" }
        StreamFormat: "hls"
        SwitchingStrategy: "full-adaptation"
    }])
    this.player.Play()

    return this
End Sub

Sub EventLoop()
    while true
        msg = wait(0, m.port)
        if msg <> invalid
            'If this is a startup progress status message, record progress
            'and update the UI accordingly:
            if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                m.paused = false
                progress% = msg.GetIndex() / 10
                if m.progress <> progress%
                    m.progress = progress%
                    m.paint()
                end if

            'Playback progress (in seconds):
            else if msg.isPlaybackPosition()
                m.position = msg.GetIndex()
                m.paint()

            else if msg.isRemoteKeyPressed()
                index = msg.GetIndex()
                print "Remote button pressed: " + index.tostr()

                if index = 4 or index = 8  '<LEFT> or <REV>
                    m.position = m.position - 60
                    m.player.Seek(m.position * 1000)
                else if index = 5 or index = 9  '<RIGHT> or <FWD>
                    m.position = m.position + 60
                    m.player.Seek(m.position * 1000)
                else if index = 13  '<PAUSE/PLAY>
                    if m.paused m.player.Resume() else m.player.Pause()
                end if

            else if msg.isPaused()
                m.paused = true
                m.paint()

            else if msg.isResumed()
                m.paused = false
                m.paint()

            end if
            'Output events for debug
            print msg.GetType(); ","; msg.GetIndex(); ": "; msg.GetMessage()
            if msg.GetInfo() <> invalid print msg.GetInfo();
        end if
    end while
End Sub

Sub SetupFullscreenCanvas()
    m.canvas.AllowUpdates(false)
    m.paint()
    m.canvas.AllowUpdates(true)
End Sub

Sub PaintFullscreenCanvas()
    list = []

    if m.progress < 100
        color = "#000000" 'opaque black
        list.Push({
            Text: "Loading..." + m.progress.tostr() + "%"
            TextAttrs: { font: "huge" }
            TargetRect: m.layout.full
        })
    else if m.paused
        color = "#80000000" 'semi-transparent black
        list.Push({
            Text: "Paused"
            TextAttrs: { font: "huge" }
            TargetRect: m.layout.full
        })
    else
        color = "#00000000" 'fully transparent
    end if

    m.canvas.SetLayer(0, { Color: color, CompositionMode: "Source" })
    m.canvas.SetLayer(1, list)
End Sub
