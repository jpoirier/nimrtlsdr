# See license.txt for usage.

import strutils
import logging as log
import rtlsdr


# proc rtlsdr_cb(buf []byte, userctx *rtl.UserCtx)
#     log.info("Length of async-read buffer: %d", len(buf))
#     if c, ok := (*userctx).(chan bool); ok {
#         c <- true // async-read done signal

# proc async_stop(dev *rtl.Context, c chan bool)
# 	<-c // async-read done signal

# 	log.Println("Received async-read done, calling CancelAsync")
# 	if err := dev.CancelAsync(); err != nil
# 		log.Println("CancelAsync failed")
# 	else
# 		log.Println("CancelAsync successful")

# 	os.Exit(0)


# func sig_abort(dev *rtl.Context) {
# 	ch := make(chan os.Signal)
# 	signal.Notify(ch, syscall.SIGINT)
# 	<-ch
# 	_ = dev.CancelAsync()
# 	dev.Close()
# 	os.Exit(0)
# }

proc main() =
	var err: Error
	var dev: Context

    var c = GetDeviceCount()
    if c == 0 :
		log.fatal("No devices found, exiting.")
    else:
        for i = 0; i < c; i++:
            let (m, p, s, err) = GetDeviceUsbStrings(i)
            log.info("GetDeviceUsbStrings $1 - $2 $3 $4" % [err, m, p, s])

    log.info("===== Device name: $1 =====", rtl.GetDeviceName(0))
    log.info("===== Running tests using device indx: $1 =====", $0)

    var o = OpenDev(0)
	if ord(o.err) != 0:
		log.fatal("\tError: $1", err)

    dev = o.dev
	defer: dev.Close()
	# go sig_abort(dev)

    # m, p, s, err
    var strs = dev.GetUsbStrings()
    if ord(strs.err) != 0:
        log.info("\tGetUsbStrings Failed - error: %s\n", strs.err)
    else:
        log.info("\tGetUsbStrings - %s %s %s\n", strs.m, strs.p, strs.s)

    # g, err
    var gains = dev.GetTunerGains()
    if ord(gains.err) != 0:
        log.info("\tGetTunerGains Failed - error: %s\n", err)
    else:
        gains := fmt.Sprintf("\tGains: ")
		for _, j := range g
			gains += fmt.Sprintf("%d ", j)
		log.info("%s\n", gains)

    var err = dev.SetSampleRate(DefaultSampleRate)
    if ord(err) != 0:
        log.info("\tSetSampleRate Failed - error: ", err)
    else:
        log.info("\tSetSampleRate - rate: ", DefaultSampleRate)
    log.info("\tGetSampleRate: $1\n", $dev.GetSampleRate())

	# status = dev.SetXtalFreq(rtl_freq, tuner_freq)
	# log.info("\tSetXtalFreq %s - Center freq: %d, Tuner freq: %d\n",
	# 	rtl.Status[status], rtl_freq, tuner_freq)

    # rtl_freq, tuner_freq, err
    var xtalFreq = dev.GetXtalFreq()
    if ord(xtalFreq.err) != 0:
        log.info("\tGetXtalFreq Error: ", xtalFreq.err)
    else:
        log.info("\tGetXtalFreq - Rtl: $1, Tuner: $2" % [$xtalFreq.rtl_freq, $xtalFreq.tuner_freq])

    err = dev.SetCenterFreq(850000000)
    if ord(err) != 0:
		log.info("\tSetCenterFreq 850MHz Failed, error: ", err)
    else
        log.info("\tSetCenterFreq 850MHz Successful")

    log.info("\tGetCenterFreq: ", dev.GetCenterFreq())
    log.info("\tGetFreqCorrection: ", dev.GetFreqCorrection())
    log.info("\tGetTunerType: ", dev.GetTunerType())
    err = dev.SetTunerGainMode(false)
    if ord(err) != 0:
        log.info("\tSetTunerGainMode Failed - error: ", err)
    else
        log.info("\tSetTunerGainMode Successful\n")

    log.info("\tGetTunerGain: %d\n", dev.GetTunerGain())

	#func SetFreqCorrection(ppm int) (err int)
	#func SetTunerGain(gain int) (err int)
	#func SetTunerIfGain(stage, gain int) (err int)
	#func SetAgcMode(on int) (err int)
	#func SetDirectSampling(on int) (err int)

     err = dev.SetTestMode(true)
    if ord(err) == 0 {
        log.info("\tSetTestMode 'On' Successful")
    else
        log.info("\tSetTestMode 'On' Failed - error: ", err)

    err = dev.ResetBuffer()
    if ord(err) == 0:
        log.info("\tResetBuffer Successful\n")
    else
        log.info("\tResetBuffer Failed - error: %s\n", err)

    var (buffer, n_read, e) = dev.ReadSync(DefaultBufLength)
    if ord(err) != 0:
        log.info("\tReadSync Failed - error: ", e)
    else:
        log.info("\tReadSync ", $n_read)

        if n_read < rtl.DefaultBufLength:
            log.info("ReadSync short read, $1 samples lost\n" % $(DefaultBufLength-n_read))

    err = dev.SetTestMode(false)
    if ord(err) == 0:
        log.info("\tSetTestMode 'Off' Successful")
    else
        log.info("\tSetTestMode 'Off' Fail - error: ", err)

    # Note, ReadAsync blocks until CancelAsync is called, so spawn
    # a goroutine running in its own system thread that'll wait
    # for the async-read callback to signal when it's done.
    IQch := make(chan bool)
    go async_stop(dev, IQch)
    var userctx rtl.UserCtx = IQch
    err = dev.ReadAsync(rtlsdr_cb, &userctx, DefaultAsyncBufNumber, DefaultBufLength)
    if ord(err) == 0:
        log.info("\tReadAsync Successful")
    else
        log.info("\tReadAsync Fail - error: ", err)

    log.info("Exiting...\n")

main()
