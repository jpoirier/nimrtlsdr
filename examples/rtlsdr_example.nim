# See license.txt for usage.

import strutils
import threadpool
import rtlsdr

type Msg = object
    s: bool

var chan: TChannel[Msg]

proc rtlsdrCb*(buf: ptr uint8, len: uint32, userCtx: UserCtxPtr) {.fastcall.} =
    ## The rtlsdr callback function.
    var first {.global.}: bool = false
    if first == false:
        first = true
        var msg: Msg
        msg.s = true
        chan.send(msg)  # Send a ping to asyncStop
    echo("Length of async-read buffer - ", $len)

proc asyncStop(dev: Context) =
    echo("asyncStop running...")
    ## Pends for a ping from the rtlsdr callback,
    ## and when received it cancels the async callback.
    discard chan.recv()
    echo("Received ping from rtlsdrCb, calling cancelAsync")
    var err = dev.cancelAsync()
    if ord(err) != 0:
        echo("CancelAsync failed - ", err)
    else:
        echo("CancelAsync successful...")

proc main() =
    let cnt = getDeviceCount()
    if cnt == 0 :
        echo("No devices found, exiting.")
        return
    else:
        for i in 0..(cnt-1):
            let (m, p, s, e) = getDeviceUsbStrings(i)
            echo("getDeviceUsbStrings $1, $2, $3, $4" % [m, p, s, $e])

    echo("===== Device name: $1 =====" % getDeviceName(0))
    echo("===== Running tests using device index: 0 =====")

    let openedDev = openDev(0)
    if openedDev.err != Error.NoError:
        echo("\tOpenDev failed - ", openedDev.err)
        return

    let dev = openedDev.dev
    defer: discard dev.closeDev()

    let u = dev.getUsbStrings()
    if u.err != Error.NoError:
        echo("\tgetUsbStrings error - ", u.err)
    else:
        echo("\tgetUsbStrings - $1, $2, $3\n" % [u.manufact, u.product, u.serial])

    let g = dev.getTunerGains()
    if g.err != Error.NoError:
        echo("\tGetTunerGains error - ", g.err)
    else:
        echo("\tGains: ")
        echo($g.gains)

    var err = dev.setSampleRate(dfltSampleRate)
    if err != Error.NoError:
        echo("\tsetSampleRate error - ", err)
    else:
        echo("\tsetSampleRate rate: ", $dfltSampleRate)

    echo("\tgetSampleRate: ", $dev.getSampleRate())

    # err = dev.setXtalFreq(rtl_freq, tuner_freq)
    # if err != Error.NoError:
    #     echo("\setXtalFreq error - ", err)
    # else:
    #     echo("\setXtalFreq center freq: $1, Tuner freq: $2" % [rtl_freq, tuner_freq])

    # rtl_freq, tuner_freq, err
    let xtalFreq = dev.getXtalFreq()
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

    let (b, nRead, e) = dev.readSync(dfltBufLen)
    if e != Error.NoError:
        echo("\treadSync Failed - error: ", e)
    else:
        echo("\treadSync num read - ", $nRead)
        if nRead < dfltBufLen:
            echo("readSync short read, $1 samples lost\n" % $(dfltBufLen-nRead))

    err = dev.setTestMode(false)
    if err == Error.NoError:
        echo("\tsetTestMode 'Off' successful...")
    else:
        echo("\tsetTestMode 'Off' error - ", err)

    # ReadAsync blocks until CancelAsync is called, so spawn
    # a thread that'll wait for the async-read callback to send a
    # ping once it has started.
    var msg: Msg
    msg.s = true
    open(chan)
    spawn asyncStop(dev)

    var userCtx: UserCtxPtr = nil
    err = dev.readAsync(cast[readAsyncCbProc](rtlsdrCb),
                        userCtx,
                        dfltAsyncBufNum,
                        dfltBufLen)
    if err != Error.NoError:
        echo("\treadAsync call error - ", err)
        chan.send(msg)
    else:
        echo("\treadAsync call successful...")

    sync()
    close(chan)
    echo("Exiting...")

main()
