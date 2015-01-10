# See license.txt for usage.

{.deadCodeElim: on.}

when defined(windows):
    const rtlsdr_lib = "rtlsdr.dll"
elif defined(macosx):
    const rtlsdr_lib = "librtlsdr.dylib"
else:
    const rtlsdr_lib = "librtlsdr.so"

type ctxPointer* = pointer  # user contect

const
    ## Default parameter settings
    dfltGain* = "auto"
    dfltFc* = 80e6
    dfltRs* = 1.024e6
    dfltReadSz* = 1024
    crystalFreq* = 28800000
    dfltSampleRate* = 2048000
    dfltAsyncBufNum* = 15
    dfltBufLen* = (16 * 32)
    minBufLen* = 512
    maxBufLen* = (256 * 16384)

type Error* {.size: sizeof(int).} = enum
    OffsetTuningModeError = (-13, "getting offset tuning mode")
    NotSupportedError = (-12, "operation not supported or unimplemented")
    NoMemError = (-11, "insufficient memory")
    InterruptedError = (-10, "system call interrupted (perhaps due to signal)")
    PipeError = (-9, "pipe error")
    OverflowError = (-8, "overflow")
    TimeoutError = (-7, "operation timed out")
    BusyError = (-6, "resource busy")
    NotFoundError = (-5, "entity not found")
    NoDeviceError = (-4, "no such device (possibly disconnected)")
    AccessError = (-3, "access denied (insufficient permissions)")
    InvalidParamError = (-2, "invalid parameter(s)")
    IoError = (-1, "input/output error")
    NoError = (0, "no error")

type RtlSdrTuner* {.size: sizeof(int).} = enum
    TunerUknown = (0, "TUNER_UNKNOWN")
    TunerE4000 = (1, "TUNER_E4000")
    TunerFC0012 = (2, "TUNER_FC0012")
    TunerFC0013 = (3, "TUNER_FC0013")
    TunerFC2580 = (4, "TUNER_FC2580")
    TunerR820T = (5, "TUNER_R820T")
    TunerR828D = (6, "TUNER_R828D")

type SamplingState* {.size: sizeof(int).} = enum
    SamplingNone = (0, "None")
    SamplingIADC = (1, "IADC")
    SamplingQADC = (2, "QADC")

type
    devObjPtr* = ptr devObj
    devObj* {.final.} = object

type Context* = object of RootObj
    ctx*: devObjPtr

type
    readAsyncCbProc* = proc (buf: ptr uint8; len: uint32; ctx: ctxPointer) {.fastcall.}

const
    gains_list*: array[18, int] = [-10, 15, 40, 65, 90, 115, 140, 165, 190, 215,
                                    240, 290, 340, 420, 430, 450, 470, 490]


include "cdecl.nim"


proc getDeviceCount*(): int =
    ## *Returns*: the number of valid USB dongles detected
    return cast[int](rtlsdr_get_device_count())

proc getDeviceName*(index: int): string =
    ## *Returns*: the name of the USB device for index.
    ## E.g. an index returned from calling GainValues.
    return $(rtlsdr_get_device_name(cast[uint32](index)))


proc getDeviceUsbStrings*(index: int):
    tuple[manufact, product, serial: string, err: Error] =
    ## *Returns*: the USB device strings for index and 0 on success
    var m: array[0..257, char]
    var p: array[0..257, char]
    var s: array[0..257, char]
    let e = rtlsdr_get_device_usb_strings(cast[uint32](index),
        addr(m[0]), addr(p[0]), addr(s[0]))
    ($m, $p, $s, cast[Error](e))

proc getIndexBySerial*(serial: string): tuple[index: int, err: Error] =
    ## *Returns*: the device index for USB string serial and 0 on success
    result.index = rtlsdr_get_index_by_serial(serial)
    if result.index >= 0:
        result.err = NoError
    else:
        result.err = cast[Error](result.index)

proc openDev*(index: int): tuple[dev: Context, err: Error] =
    ## *Returns*: a device construct for index and 0 on success
    result.err = cast[Error](rtlsdr_open(addr(result.dev.ctx), cast[uint32](index)))

proc closeDev*(dev: Context): Error =
    ## Closes dev.
    ##
    ## *Returns*: 0 on success
    return cast[Error](rtlsdr_close(dev.ctx))


## configuration functions

proc setXtalFreq*(dev: Context, rtl_freq, tuner_freq: int): Error =
    ## Sets the crystal oscillator frequencies for the RTL2832 and the tuner IC.
    ##
    ## Usually both ICs use the same clock. Changing the clock may make sense if
    ## you are applying an external clock to the tuner or to compensate the
    ## frequency (and samplerate) error caused by the original (cheap) crystal.
    ##
    ## NOTE: Call this function only if you fully understand the implications.
    ## Values are in Hz.
    ##
    ## *Returns*: 0 on success
    return cast[Error](rtlsdr_set_xtal_freq(dev.ctx,
        cast[uint32](rtl_freq), cast[uint32](tuner_freq)))

proc getXtalFreq*(dev: Context): tuple[rtl_freq, tuner_freq: int, err: Error] =
    ## *Returns*: the crystal oscillator frequencies for the RTL2832 and the
    ## tuner IC ## *Returns*: 0 on success
    ##
    ## Usually both ICs use the same clock. Frequency values are in Hz.
    result.err = cast[Error](rtlsdr_get_xtal_freq(dev.ctx,
        cast[ptr uint32](addr(result.rtl_freq)),
        cast[ptr uint32](addr(result.tuner_freq))))

proc getUsbStrings*(dev: Context): tuple[manufact, product, serial: string, err: Error] =
    ## *Returns*: dev's USB strings and 0 on success
    var m: array[0..256, char]
    var p: array[0..256, char]
    var s: array[0..256, char]
    let e = rtlsdr_get_usb_strings(dev.ctx, addr(m[0]), addr(p[0]), addr(s[0]))
    ($m, $p, $s, cast[Error](e))

proc writeEeprom*(dev: Context, data: var seq[uint8], offset: uint8): Error =
    ## Write data to the EEPROM.
    ##
    ## *Arguments*:
    ## - ``data``: the data to be written
    ## - ``offset``: the address where the data is to be written
    ##
    ## *Returns*: 0 on success
    return cast[Error](rtlsdr_write_eeprom(dev.ctx,
        cast[ptr uint8](addr(data)),
        offset,
        cast[uint16](data.len)))

proc readEeprom*(dev: Context, offset: uint8, length: uint16):
    tuple[data: seq[uint8], cnt: int, err: Error] =
    ## Reads data from the EEPROM.
    ##
    ## *Arguments*:
    ## - ``offset``: Address where the data should be read from
    ## - ``length``: The length of the data to be read
    ##
    ## *Returns*: A buffer containing data read from the EEPROM, the count of
    ## the data actually read into the buffer, 0 on success
    result.data = newseq[uint8](int(length))
    let e = rtlsdr_read_eeprom(dev.ctx, addr(result.data[0]), offset, length)
    result.cnt = e
    if e >= 0:
        result.err = NoError
    else:
        result.err = cast[Error](e)

proc setCenterFreq*(dev: Context, freq: int): Error =
    ## Sets the center frequency to freq Hz.
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_set_center_freq(dev.ctx, cast[uint32](freq)))

proc getCenterFreq*(dev: Context): int =
    ## *Returns*: the tuned frequency in Hz.
    result = cast[int](rtlsdr_get_center_freq(dev.ctx))

proc setFreqCorrection*(dev: Context, freq: int): Error =
    ## Sets the frequency correction value to freq Hz.
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_set_freq_correction(dev.ctx, freq))

proc getFreqCorrection*(dev: Context): int =
    ## *Returns*: the frequency correction value in ppm (parts per million)
    result = rtlsdr_get_freq_correction(dev.ctx)


proc getTunerType*(dev: Context): RtlSdrTuner =
    ## *Returns*: the tuner type.
    result = cast[RtlSdrTuner](rtlsdr_get_tuner_type(dev.ctx))

proc getTunerGains*(dev: Context): tuple[gains: seq[int], err: Error] =
    ## *Returns*: a list of gains, in tenths of dB, supported by the tuner
    ## and 0 on success. E.g. 115 means 11.5 dB.
    result.err = NoError
    let i = cast[int](rtlsdr_get_tuner_gains(dev.ctx, cast[ptr int](0)))
    if i < 0:
        result.err = cast[Error](i)
    elif i == 0:
        result.gains = newseq[int](0)
    else:
        result.gains = newseq[int](i)
        discard rtlsdr_get_tuner_gains(dev.ctx,
            cast[ptr int](addr(result.gains[0])))

proc setTunerGain*(dev: Context, gain: int): Error =
    ## Sets the tuner gain. Manual gain mode must be enabled for this to work.
    ##
    ## Valid gain values (in tenths of a dB, where 115 means 11.5 dB) for the
    ## tuner are:
    ##      -10, 15, 40, 65, 90, 115, 140, 165, 190, 215,
    ##      240, 290, 340, 420, 430, 450, 470, 490
    ##
    ## *Returns*: 0 on success
    if gain notin gains_list:
        result = InvalidParamError
    else:
        result = cast[Error](rtlsdr_set_tuner_gain(dev.ctx, gain))

proc getTunerGain*(dev: Context): int =
    ## *Returns*: The configured tuner gain
    ##
    ## Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
    result = rtlsdr_get_tuner_gain(dev.ctx)

proc setTunerIfGain*(dev: Context, stage, gain: int): Error =
    ## Sets the Intermediate frequency gain stage number.
    ## Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
    ##
    ## *Arguments*:
    ## - ``stage``: intermediate frequency gain stage number (1 to 6 for E4000)
    ## - ``gain``: in tenths of a dB, -30 means -3.0 dB.
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_set_tuner_if_gain(dev.ctx, stage, gain))

proc setTunerGainMode*(dev: Context, manualMode: bool): Error =
    ## Sets the gain mode (automatic or manual) for the device.
    ## Manual gain mode must be enabled for the gain setter function to work.
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_set_tuner_gain_mode(dev.ctx, cast[int](manualMode)))

proc setSampleRate*(dev: Context, rate: int): Error =
    ## Selects the baseband filters according to the requested sample rate in Hz
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_set_sample_rate(dev.ctx, cast[uint32](rate)))

proc getSampleRate*(dev: Context): int =
    ## *Returns*: the configured sample rate in Hz
    result = cast[int](rtlsdr_get_sample_rate(dev.ctx))

proc setTestMode*(dev: Context, testModeOn: bool): Error =
    ## Enables test mode that returns an 8 bit counter instead of samples.
    ## The counter is generated inside the RTL2832.
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_set_testmode(dev.ctx, cast[int](testModeOn)))


proc setAgcMode*(dev: Context, agcModeOn: bool): Error =
    ## Enables or disables the internal digital AGC of the RTL2832.
    ##
    ## *Returns*: 0 on success
    result =  cast[Error](rtlsdr_set_agc_mode(dev.ctx, cast[int](agcModeOn)))

proc setDirectSampling*(dev: Context, on: bool): Error =
    ## Enables or disables the direct sampling mode. When enabled,
    ## the IF mode of the RTL2832 is activated, and rtlsdr_set_center_freq()
    ## will control the IF-frequency of the DDC, which can be used to tune
    ## from 0 to 28.8 MHz  (xtal frequency of the RTL2832).
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_set_direct_sampling(dev.ctx, cast[int](on)))

proc getDirectSampling*(dev: Context): SamplingState =
    ## *Returns*: the state of the direct sampling mode.
    result = cast[SamplingState](rtlsdr_get_direct_sampling(dev.ctx))

proc setOffsetTuning*(dev: Context, enable: bool): Error =
    ## Enables or disables offset tuning for zero-IF tuners, which
    ## avoid problems caused by the DC offset of the ADCs and 1/f noise.
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_set_offset_tuning(dev.ctx, cast[int](enable)))

proc getOffsetTuning*(dev: Context): tuple[enabled: bool, err: Error] =
    ## *Returns*: the state of the offset tuning mode
    result.err = NoError
    let i = rtlsdr_get_offset_tuning(dev.ctx)
    if i == -1:
        result.err = OffsetTuningModeError
    result.enabled = cast[bool](i)

## streaming functions

proc resetBuffer*(dev: Context): Error =
    ##
    result = cast[Error](rtlsdr_reset_buffer(dev.ctx))

proc readSync*(dev: Context, length: int): tuple[buf: seq[char], nRead: int, err: Error] =
    ##
    result.buf = newseq[char](length)
    result.err = cast[Error](rtlsdr_read_sync(dev.ctx,
        cast[pointer](addr(result.buf[0])),
        length,
        addr(result.nRead)))

proc readAsync*(dev: Context, f: readAsyncCbProc, ctx: ctxPointer, bufNum, bufLen: int): Error =
    ## Reads samples from the device asynchronously. This function blocks
    ## until canceled via CancelAsync
    ##
    ## Optional bufNum buffer count, bufNum * bufLen = overall buffer size,
    ## set to 0 for default buffer count (32).
    ## Optional bufLen buffer length, must be multiple of 512, set to 0 for
    ## default buffer length (16 * 32 * 512).
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_read_async(dev.ctx, f, ctx, cast[uint32](bufNum),
        cast[uint32](bufLen)))

proc cancelAsync*(dev: Context): Error =
    ## Cancels all pending asynchronous operations on the device.
    ##
    ## *Returns*: 0 on success
    result = cast[Error](rtlsdr_cancel_async(dev.ctx))
