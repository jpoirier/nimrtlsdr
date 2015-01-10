# See license.txt for usage.

import strutils
import threadpool
import rtlsdr

type
    TMsg = object
        s: bool

type
    PChan = ptr TChannel[TMsg]

var chan: TChannel[TMsg]

proc rtlsdr_cb*(buf: ptr uint8, len: uint32, userctx: UserCtx) {.fastcall.} =
    ## The rtlsdr callback function.
    var first {.global.}: bool = false
    if first == false:
        first = true
        var m: TMsg
        m.s = true
        var pch: PChan = cast[PChan](userctx)
        pch[].send(m)  # Send a ping to async_stop
    echo("Length of async-read buffer - ", $len)

proc async_stop(dev: Context, ch: PChan) =
    echo("async_stop started...")
    ## Pends for a ping from the rtlsdr callback,
    ## and when received it cancels the async callback.
    discard ch[].recv()
    echo("Received async-read done, calling CancelAsync")
    var err = dev.CancelAsync()
    if ord(err) != 0:
        echo("CancelAsync failed - ", err)
    else:
        echo("CancelAsync successful...")

proc main() =
    var c = GetDeviceCount()
    if c == 0 :
        echo("No devices found, exiting.")
        return
    else:
        for i in 0..(c-1):
            let (m, p, s, e) = GetDeviceUsbStrings(i)
            echo("GetDeviceUsbStrings $1, $2, $3, $4" % [m, p, s, $e])

    echo("===== Device name: $1 =====" % GetDeviceName(0))
    echo("===== Running tests using device index: 0 =====")

    var openedDev = OpenDev(0)
    if ord(openedDev.err) != 0:
        echo("\tOpenDev failed - ", openedDev.err)
        return

    var dev = openedDev.dev
    defer: discard dev.Close()

    var u = dev.GetUsbStrings()
    if u.err != Error.None:
        echo("\tGetUsbStrings error - ", u.err)
    else:
        echo("\tGetUsbStrings - $1, $2, $3\n" % [u.manufact, u.product, u.serial])

    var g = dev.GetTunerGains()
    if g.err != Error.None:
        echo("\tGetTunerGains error - ", g.err)
    else:
        echo("\tGains: ")
        echo($g.gains)

    var err = dev.SetSampleRate(DfltSampleRate)
    if err != Error.None:
        echo("\tSetSampleRate error - ", err)
    else:
        echo("\tSetSampleRate rate: ", $DfltSampleRate)

    echo("\tGetSampleRate: ", $dev.GetSampleRate())

    # err = dev.SetXtalFreq(rtl_freq, tuner_freq)
    # if err != Error.None:
    #     echo("\SetXtalFreq error - ", err)
    # else:
    #     echo("\SetXtalFreq center freq: $1, Tuner freq: $2" % [rtl_freq, tuner_freq])

    # rtl_freq, tuner_freq, err
    var xtalFreq = dev.GetXtalFreq()
    if ord(xtalFreq.err) != 0:
        echo("\tGetXtalFreq error - ", xtalFreq.err)
    else:
        echo("\tGetXtalFreq - Rtl: $1, Tuner: $2" % [$xtalFreq.rtl_freq, $xtalFreq.tuner_freq])

    err = dev.SetCenterFreq(850000000)
    if err != Error.None:
        echo("\tSetCenterFreq 850MHz error - ", err)
    else:
        echo("\tSetCenterFreq 850MHz successful...")

    echo("\tGetCenterFreq: ", $dev.GetCenterFreq())
    echo("\tGetFreqCorrection: ", $dev.GetFreqCorrection())
    echo("\tGetTunerType: ", dev.GetTunerType())

    err = dev.SetTunerGainMode(false)
    if err != Error.None:
        echo("\tSetTunerGainMode error - ", err)
    else:
        echo("\tSetTunerGainMode successful...")

    echo("\tGetTunerGain: ", $dev.GetTunerGain())

    # SetFreqCorrection(ppm: int): Error
    # SetTunerGain(gain: int): Error
    # SetTunerIfGain(stage, gain: int): Error
    # SetAgcMode(on: bool): Error
    # SetDirectSampling(on: bool): Error

    err = dev.SetTestMode(true)
    if err == Error.None:
        echo("\tSetTestMode 'On' successful...")
    else:
        echo("\tSetTestMode 'On' error - ", err)

    err = dev.ResetBuffer()
    if err == Error.None:
        echo("\tResetBuffer successful...\n")
    else:
        echo("\tResetBuffer error - ", err)

    let (b, n_read, e) = dev.ReadSync(DfltBufLen)
    if err != Error.None:
        echo("\tReadSync Failed - error: ", e)
    else:
        echo("\tReadSync num read - ", $n_read)
        if n_read < DfltBufLen:
            echo("ReadSync short read, $1 samples lost\n" % $(DfltBufLen-n_read))

    err = dev.SetTestMode(false)
    if err == Error.None:
        echo("\tSetTestMode 'Off' successful...")
    else:
        echo("\tSetTestMode 'Off' error - ", err)

    # ReadAsync blocks until CancelAsync is called, so spawn
    # a thread that'll wait for the async-read callback to send a
    # ping once it has started.
    var m: TMsg
    m.s = true
    var ch: TChannel[TMsg]
    open(ch)
    spawn async_stop(dev, addr(ch))

    var userctx: UserCtx = cast[UserCtx](addr(ch))
    err = dev.ReadAsync(cast[read_async_cb_t](rtlsdr_cb),
                        userctx,
                        DfltAsyncBufNum,
                        DfltBufLen)
    if err != Error.None:
        echo("\tReadAsync call error - ", err)
        ch.send(m)
    else:
        echo("\tReadAsync call successful...")

    sync()
    close(ch)
    # close(chan)
    echo("Exiting...")

main()
