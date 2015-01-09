# See license.txt for usage.

import strutils
import threadpool
import logging as log
import rtlsdr

type
    TMsg = object
        s: bool

type
    PChan = ptr TChannel[TMsg]

proc rtlsdr_cb(buf: ptr uint8, len: uint32, userctx: UserCtx) =
    ## The rtlsdr callback function.
    ##
    ## First, print out the data buffer length, then send
    ## a "done" message over the channel.
    log.info("Length of async-read buffer - ", $len)
    var m: TMsg
    m.s = true
    var ch: PChan = cast[PChan](userctx)
    ch[].send(m)  # done

proc async_stop(s: tuple[dev: Context, ch: PChan]) {.thread.} =
    ## Pends for a "done" message, once received,
    ## cancels the async callback and returns.
    discard s.ch[].recv()
    log.info("Received async-read done, calling CancelAsync")
    var err = s.dev.CancelAsync()
    if ord(err) != 0:
        log.info("CancelAsync failed - ", err)
    else:
        log.info("CancelAsync successful...")

proc main() =
    var c = GetDeviceCount()
    if c == 0 :
        log.fatal("No devices found, exiting.")
    else:
        for i in 0..c:
            let (m, p, s, e) = GetDeviceUsbStrings(i)
            log.info("GetDeviceUsbStrings $1 - $2 $3 $4" % [$e, m, p, s])

    log.info("===== Device name: $1 =====" % GetDeviceName(0))
    log.info("===== Running tests using device index: 0 =====")

    var openedDev = OpenDev(0)
    if ord(openedDev.err) != 0:
        log.fatal("\tOpenDev failed - ", openedDev.err)

    var dev = openedDev.dev
    defer: discard dev.Close()

    # m, p, s, err
    # var strs = dev.GetUsbStrings()
    # if ord(strs.err) != 0:
    #     log.info("\tGetUsbStrings error - ", strs.err)
    # else:
    #     log.info("\tGetUsbStrings - $1, $2, $3\n", strs.m, strs.p, strs.s)

    # g, err
    var g = dev.GetTunerGains()
    if ord(g.err) != 0:
        log.info("\tGetTunerGains error - ", g.err)
    else:
        log.info("\tGains: ")
        log.info($g.gains)

    var err = dev.SetSampleRate(DfltSampleRate)
    if ord(err) != 0:
        log.info("\tSetSampleRate error - ", err)
    else:
        log.info("\tSetSampleRate rate: ", $DfltSampleRate)

    log.info("\tGetSampleRate: ", $dev.GetSampleRate())

    # status = dev.SetXtalFreq(rtl_freq, tuner_freq)
    # log.info("\tSetXtalFreq %s - Center freq: %d, Tuner freq: %d\n",
    # 	rtl.Status[status], rtl_freq, tuner_freq)

    # rtl_freq, tuner_freq, err
    var xtalFreq = dev.GetXtalFreq()
    if ord(xtalFreq.err) != 0:
        log.info("\tGetXtalFreq error - ", xtalFreq.err)
    else:
        log.info("\tGetXtalFreq - Rtl: $1, Tuner: $2" % [$xtalFreq.rtl_freq, $xtalFreq.tuner_freq])

    err = dev.SetCenterFreq(850000000)
    if ord(err) != 0:
        log.info("\tSetCenterFreq 850MHz error - ", err)
    else:
        log.info("\tSetCenterFreq 850MHz successful...")

    log.info("\tGetCenterFreq: ", $dev.GetCenterFreq())
    log.info("\tGetFreqCorrection: ", $dev.GetFreqCorrection())
    log.info("\tGetTunerType: ", $dev.GetTunerType())
    err = dev.SetTunerGainMode(false)
    if ord(err) != 0:
        log.info("\tSetTunerGainMode error - ", err)
    else:
        log.info("\tSetTunerGainMode successful...")

    log.info("\tGetTunerGain: ", $dev.GetTunerGain())

    #func SetFreqCorrection(ppm int) (err int)
    #func SetTunerGain(gain int) (err int)
    #func SetTunerIfGain(stage, gain int) (err int)
    #func SetAgcMode(on int) (err int)
    #func SetDirectSampling(on int) (err int)

    err = dev.SetTestMode(true)
    if ord(err) == 0:
        log.info("\tSetTestMode 'On' successful...")
    else:
        log.info("\tSetTestMode 'On' error - ", err)

    err = dev.ResetBuffer()
    if ord(err) == 0:
        log.info("\tResetBuffer successful...\n")
    else:
        log.info("\tResetBuffer error - ", err)

    var (b, n_read, e) = dev.ReadSync(DfltBufLen)
    if ord(err) != 0:
        log.info("\tReadSync Failed - error: ", e)
    else:
        log.info("\tReadSync num read - ", $n_read)

        if n_read < DfltBufLen:
            log.info("ReadSync short read, $1 samples lost\n", $(DfltBufLen-n_read))

    err = dev.SetTestMode(false)
    if ord(err) == 0:
        log.info("\tSetTestMode 'Off' successful...")
    else:
        log.info("\tSetTestMode 'Off' error - ", err)

    # Note, ReadAsync blocks until CancelAsync is called, so spawn
    # a goroutine running in its own system thread that'll wait
    # for the async-read callback to signal when it's done.
    var m: TMsg
    m.s = true
    var ch: TChannel[TMsg]
    var userctx: UserCtx = cast[UserCtx](addr(ch))
    createThread(async_stop, (dev, addr(ch))
    err = dev.ReadAsync(cast[read_async_cb_t](rtlsdr_cb), userctx, DfltAsyncBufNum, DfltBufLen)
    if ord(err) != 0:
        log.info("\tReadAsync call error - ", err)
        ch.send(m)
    else:
        log.info("\tReadAsync call successful...")

    sync()
    close(ch)
    log.info("Exiting...")

main()
