# See license.txt for usage.

import strutils
import threadpool
import rtlsdr

type Msg = object
    s: bool

var chan: TChannel[Msg]

proc rtlsdrCb*(buf: ptr uint8, len: uint32, userCtx: UserCtxPtr) {.fastcall.} =
    ## The rtlsdr callback function.
    var intit {.global.}: bool = false
    if intit == false:
        intit = true
        var msg: Msg
        msg.s = true
        chan.send(msg)  # Send a ping to asyncStop
    echo("Length of async-read buffer - ", $len)

proc asyncStop(dev: Context) =
    ## Pends for a ping from the rtlsdrCb function callback,
    ## and when received cancel the async callback.
    echo("asyncStop running...")
    discard chan.recv()
    echo("Received ping from rtlsdrCb, calling cancelAsync")
    let err = dev.cancelAsync()
    if err != NoError:
        echo("CancelAsync failed - ", err)
    else:
        echo("CancelAsync successful...")

proc main() =
    #---------- Device Check ----------
    let cnt = getDeviceCount()
    if cnt == 0 :
        echo("No devices found, exiting.")
        return
    else:
        for i in 0..(cnt-1):
            # manufact, product, serial, error
            let (m, p, s, e) = getDeviceUsbStrings(i)
            echo("Usb Strings: $1, $2, $3, $4" % [m, p, s, $e])

    echo("===== Device name - $1 =====" % getDeviceName(0))
    echo("===== Running tests using device index: 0 =====")

    #---------- Open Device ----------
    var (dev, err) = openDev(0)
    if err != NoError:
        echo("\tOpenDev failed - ", err)
        return

    defer: discard dev.closeDev()

    #---------- Device Strings ----------
    let (manufact, product, serial, er) = dev.getUsbStrings()
    if er != NoError:
        echo("\tgetUsbStrings error - ", er)
    else:
        echo("\tgetUsbStrings - $1, $2, $3\n" %
            [manufact, product, serial])

    echo("\tgetTunerType: ", dev.getTunerType())

    #---------- Get/Set Tuner Gains ----------
    let (gains, e) = dev.getTunerGains()
    if e != NoError:
        echo("\tGetTunerGains error - ", e)
    else:
        echo("\tGains: ")
        echo($gains)

    let tunerGain = dev.getTunerGain()
    echo("\tgetTunerGain: ", $tunerGain)

    err = dev.setTunerGainMode(true) # manualMode = false
    if err != NoError:
        echo("\tsetTunerGainMode error - ", err)
    else:
        echo("\tsetTunerGainMode successful...")

    err = dev.setTunerGain(tunerGain)
    if err != NoError:
        echo("\tsetTunerGain error - ", err)
    else:
        echo("\tsetTunerGain successful...")

    #---------- Get/Set Sample Rate ----------
    err = dev.setSampleRate(dfltSampleRate)
    if err != NoError:
        echo("\tsetSampleRate error - ", err)
    else:
        echo("\tsetSampleRate rate: ", $dfltSampleRate)

    echo("\tgetSampleRate: ", $dev.getSampleRate())

    #---------- Get/Set Xtal Freq ----------
    # rtlFreq, tuneFreq, err
    let xtalFreq = dev.getXtalFreq()
    if xtalFreq.err != NoError:
        echo("\tgetXtalFreq error - ", xtalFreq.err)
    else:
        echo("\tgetXtalFreq - Rtl: $1, Tuner: $2" %
            [$xtalFreq.rtlFreq, $xtalFreq.tunerFreq])

    err = dev.setXtalFreq(xtalFreq.rtlFreq, xtalFreq.tunerFreq)
    if err != NoError:
        echo("\tsetXtalFreq error - ", err)
    else:
        echo("\tsetXtalFreq Center freq: $1, Tuner freq: $2" %
            [$xtalFreq.rtlFreq, $xtalFreq.tunerFreq])

    #---------- Get/Set Center Freq ----------
    err = dev.setCenterFreq(850_000_000)
    if err != NoError:
        echo("\tsetCenterFreq 850MHz error - ", err)
    else:
        echo("\tsetCenterFreq 850MHz successful...")

    echo("\tgetCenterFreq: ", $dev.getCenterFreq())

    #---------- Get/Set Freq Correction ----------
    let freqCorr = dev.getFreqCorrection()
    echo("\tgetFreqCorrection: ", $freqCorr)

    err = dev.setFreqCorrection(freqCorr)
    if err != NoError:
        echo("\tsetFreqCorrection error - ", err)
    else:
        echo("\tsetFreqCorrection successful...")

    #---------- Get/Set AGC Mode ----------
    err = dev.setAgcMode(false) # off
    if err != NoError:
        echo("\tsetAgcMode error - ", err)
    else:
        echo("\tsetAgcMode successful...")

    #---------- Get/Set Direct Sampling ----------
    let samplingState = dev.getDirectSampling()
    echo("\tgetDirectSampling - ", samplingState)
    err = dev.setDirectSampling(false) # set to off
    if err == NoError:
        echo("\tsetDirectSampling 'Off' successful...")
    else:
        echo("\tsetDirectSampling 'Off' error - ", err)

    #---------- Get/Set Tuner IF Gain ----------
    # setTunerIfGain(stage, gain: int): Error

    #---------- Get/Set test mode ----------
    err = dev.setTestMode(true)
    if err == NoError:
        echo("\tsetTestMode 'On' successful...")
    else:
        echo("\tsetTestMode 'On' error - ", err)

    err = dev.setTestMode(false)
    if err == NoError:
        echo("\tsetTestMode 'Off' successful...")
    else:
        echo("\tsetTestMode 'Off' error - ", err)

    #---------- Get/Set misc. streaming ----------
    err = dev.resetBuffer()
    if err == NoError:
        echo("\tresetBuffer successful...\n")
    else:
        echo("\tresetBuffer error - ", err)

    let (b, numRead, ere) = dev.readSync(dfltBufLen)
    if er != NoError:
        echo("\treadSync Failed - error: ", ere)
    else:
        echo("\treadSync num read - ", $numRead)
        if numRead < dfltBufLen:
            echo("readSync short read, $1 samples lost\n" % $(dfltBufLen-numRead))

    # ReadAsync blocks until CancelAsync is called, so spawn
    # a thread that'll wait for the async-read callback to send a
    # ping once it has started.
    open(chan)
    spawn asyncStop(dev)

    var userCtx: UserCtxPtr = nil
    err = dev.readAsync(cast[readAsyncCbProc](rtlsdrCb),
                        userCtx,
                        dfltAsyncBufNum,
                        dfltBufLen)
    if err != NoError:
        echo("\treadAsync call error - ", err)
        var msg: Msg
        msg.s = true
        chan.send(msg)
    else:
        echo("\treadAsync call successful...")

    sync()
    close(chan)
    echo("Done...")


main()
