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

proc rtlsdrCb*(buf: ptr uint8, len: uint32, ctx: ctxPointer) {.fastcall.} =
    ## The rtlsdr callback function.
    var first {.global.}: bool = false
    if first == false:
        first = true
        var m: TMsg
        m.s = true
        var pch: PChan = cast[PChan](ctx)
        pch[].send(m)  # Send a ping to async_stop
    echo("Length of async-read buffer - ", $len)

proc asyncStop(dev: Context, ch: PChan) =
    echo("async_stop started...")
    ## Pends for a ping from the rtlsdr callback,
    ## and when received it cancels the async callback.
    discard ch[].recv()
    echo("Received async-read done, calling CancelAsync")
    var err = dev.cancelAsync()
    if ord(err) != 0:
        echo("CancelAsync failed - ", err)
    else:
        echo("CancelAsync successful...")

proc main() =
    var c = getDeviceCount()
    if c == 0 :
        echo("No devices found, exiting.")
        return
    else:
        for i in 0..(c-1):
            let (m, p, s, e) = getDeviceUsbStrings(i)
            echo("getDeviceUsbStrings $1, $2, $3, $4" % [m, p, s, $e])

    echo("===== Device name: $1 =====" % getDeviceName(0))
    echo("===== Running tests using device index: 0 =====")

    var openedDev = openDev(0)
    if openedDev.err != Error.NoError:
        echo("\tOpenDev failed - ", openedDev.err)
        return

    var dev = openedDev.dev
    defer: discard dev.closeDev()

    var u = dev.getUsbStrings()
    if u.err != Error.NoError:
        echo("\tgetUsbStrings error - ", u.err)
    else:
        echo("\tgetUsbStrings - $1, $2, $3\n" % [u.manufact, u.product, u.serial])

    var g = dev.getTunerGains()
    if g.err != Error.NoError:
        echo("\tGetTunerGains error - ", g.err)
    else:
        echo("\tGains: ")
        echo($g.gains)

    var err = dev.setSampleRate(DfltSampleRate)
    if err != Error.NoError:
        echo("\tsetSampleRate error - ", err)
    else:
        echo("\tsetSampleRate rate: ", $DfltSampleRate)

    echo("\tgetSampleRate: ", $dev.getSampleRate())

    # err = dev.setXtalFreq(rtl_freq, tuner_freq)
    # if err != Error.NoError:
    #     echo("\setXtalFreq error - ", err)
    # else:
    #     echo("\setXtalFreq center freq: $1, Tuner freq: $2" % [rtl_freq, tuner_freq])

    # rtl_freq, tuner_freq, err
    var xtalFreq = dev.getXtalFreq()
    if ord(xtalFreq.err) != 0:
        echo("\tgetXtalFreq error - ", xtalFreq.err)
    else:
        echo("\tgetXtalFreq - Rtl: $1, Tuner: $2" % [$xtalFreq.rtl_freq, $xtalFreq.tuner_freq])

    err = dev.setCenterFreq(850000000)
    if err != Error.NoError:
        echo("\tsetCenterFreq 850MHz error - ", err)
    else:
        echo("\tsetCenterFreq 850MHz successful...")

    echo("\tgetCenterFreq: ", $dev.getCenterFreq())
    echo("\tgetFreqCorrection: ", $dev.getFreqCorrection())
    echo("\tgetTunerType: ", dev.getTunerType())

    err = dev.setTunerGainMode(false)
    if err != Error.NoError:
        echo("\tsetTunerGainMode error - ", err)
    else:
        echo("\tsetTunerGainMode successful...")

    echo("\tgetTunerGain: ", $dev.getTunerGain())

    # setFreqCorrection(ppm: int): Error
    # setTunerGain(gain: int): Error
    # setTunerIfGain(stage, gain: int): Error
    # setAgcMode(on: bool): Error
    # setDirectSampling(on: bool): Error

    err = dev.setTestMode(true)
    if err == Error.NoError:
        echo("\tsetTestMode 'On' successful...")
    else:
        echo("\tsetTestMode 'On' error - ", err)

    err = dev.resetBuffer()
    if err == Error.NoError:
        echo("\tresetBuffer successful...\n")
    else:
        echo("\tresetBuffer error - ", err)

    let (b, n_read, e) = dev.readSync(DfltBufLen)
    if err != Error.NoError:
        echo("\treadSync Failed - error: ", e)
    else:
        echo("\treadSync num read - ", $n_read)
        if n_read < DfltBufLen:
            echo("readSync short read, $1 samples lost\n" % $(DfltBufLen-n_read))

    err = dev.setTestMode(false)
    if err == Error.NoError:
        echo("\tsetTestMode 'Off' successful...")
    else:
        echo("\tsetTestMode 'Off' error - ", err)

    # ReadAsync blocks until CancelAsync is called, so spawn
    # a thread that'll wait for the async-read callback to send a
    # ping once it has started.
    var m: TMsg
    m.s = true
    var ch: TChannel[TMsg]
    open(ch)
    spawn asyncStop(dev, addr(ch))

    var userctx: UserCtx = cast[UserCtx](addr(ch))
    err = dev.readAsync(cast[read_async_cb_t](rtlsdrCb),
                        userctx,
                        DfltAsyncBufNum,
                        DfltBufLen)
    if err != Error.NoError:
        echo("\treadAsync call error - ", err)
        ch.send(m)
    else:
        echo("\treadAsync call successful...")

    sync()
    closeDev(ch)
    echo("Exiting...")

main()
