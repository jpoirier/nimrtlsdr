# See license.txt for usage.

{.deadCodeElim: on.}

when defined(windows):
    const rtlsdr_lib = "rtlsdr.dll"
elif defined(macosx):
    const rtlsdr_lib = "librtlsdr.dylib"
else:
    const rtlsdr_lib = "librtlsdr.so"


# type
#     SamplingMode: int

const
    # default parameter settings
    Dflt_GAIN* = "auto"
    DfltFc* = 80e6
    DfltRs* = 1.024e6
    DfltReadSz* = 1024
    CrystalFreq* = 28800000
    DfltSampleRate* = 2048000
    DfltAsyncBufNum* = 32
    DfltBufLen* = (16 * 16384)
    MinBufLen* = 512
    MaxBufLen* = (256 * 16384)

type
    Error* {.size: sizeof(int).} = enum
        ErrorOffsetTuningMode = (-13, "getting offset tuning mode")
        ErrorNotSupported = (-12, "operation not supported or unimplemented on this platform")
        ErrorNoMem = (-11, "insufficient memory")
        ErrorInterrupted = (-10, "system call interrupted (perhaps due to signal)")
        ErrorPipe = (-9, "pipe error")
        ErrorOverflow = (-8, "overflow")
        ErrorTimeout = (-7, "operation timed out")
        ErrorBusy = (-6, "resource busy")
        ErrorNotFound = (-5, "entity not found")
        ErrorNoDevice = (-4, "no such device (it may have been disconnected)")
        ErrorAccess = (-3, "access denied (insufficient permissions)")
        ErrorInvalidParam = (-2, "invalid parameter(s)")
        ErrorIo = (-1, "input/output error")
        Success = (0, "success")

type
    rtlsdr_tuner* {.size: sizeof(int).} = enum
        TUNER_UNKNOWN = (0, "TUNER_UNKNOWN")
        TUNER_E4000 = (1, "TUNER_E4000")
        TUNER_FC0012 = (2, "TUNER_FC0012")
        TUNER_FC0013 = (3, "TUNER_FC0013")
        TUNER_FC2580 = (4, "TUNER_FC2580")
        TUNER_R820T = (5, "TUNER_R820T")
        TUNER_R828D = (6, "TUNER_R828D")

type
    sampling_state* {.size: sizeof(int).} = enum
        SamplingNone = (0, "None")
        SamplingIADC = (1, "IADC")
        SamplingQADC = (2, "QADC")

type
    pdev_t* = ptr dev_t
    dev_t*{.final.} = object

type
    Context* = object of RootObj
        ctx*: pdev_t

type
  read_async_cb_t* = proc (buf: ptr uint8; len: uint32; ctx: pointer) {.cdecl.}

const
    gains_list: array[18, int] = [-10, 15, 40, 65, 90, 115, 140, 165, 190, 215,
                            240, 290, 340, 420, 430, 450, 470, 490]

include "cdecl.nim"


proc GetDeviceCount*(): int =
    ## *Returns*: the number of valid USB dongles detected
    return cast[int](get_device_count())

proc GetDeviceName*(index: int): string =
    ## *Returns*: the name of the USB device for index.
    ## E.g. an "index" returned from calling GainValues.
    return $(get_device_name(cast[uint32](index)))


proc GetDeviceUsbStrings*(index: int): tuple[manufact, product, serial: string, err: Error] =
    ## *Returns*: the USB device strings for index and 0 on success
    var m: array[0..256, char]
    var p: array[0..256, char]
    var s: array[0..256, char]
    var e = get_device_usb_strings(cast[uint32](index),
                                    cast[ptr char](addr(m[0])),
                                    cast[ptr char](addr(p[0])),
                                    cast[ptr char](addr(s[0])))
    ($m, $p, $s, cast[Error](e))

proc GetIndexBySerial*(serial: string): tuple[index: int, err: Error] =
    ## *Returns*: the device index for USB string serial and 0 on success
    result.index = get_index_by_serial(serial)
    if result.index >= 0:
        result.err = Success
    else:
        result.err = cast[Error](result.index)

proc Open(index: int): tuple[dev: Context, err: Error] =
    ## *Returns*: a device construct for index and 0 on success
    result.err = cast[Error](rtlsdr_open(addr(result.dev.ctx), cast[uint32](index)))

proc Close*(dev: Context): Error =
    ## Closes dev.
    ##
    ## *Returns*: 0 on success
    return cast[Error](rtlsdr_close(dev.ctx))

# configuration functions

proc SetXtalFreq*(dev: Context, rtl_freq, tuner_freq: int): Error =
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
    return cast[Error](set_xtal_freq(dev.ctx, cast[uint32](rtl_freq), cast[uint32](tuner_freq)))

proc GetXtalFreq(dev: Context): tuple[rtl_freq, tuner_freq: int, err: Error] =
    ## *Returns*: the crystal oscillator frequencies for the RTL2832 and the
    ## tuner IC ## *Returns*: 0 on success
    ##
    ## Usually both ICs use the same clock. Frequency values are in Hz.
    result.err = cast[Error](get_xtal_freq(dev.ctx, cast[ptr uint32](addr(result.rtl_freq)), cast[ptr uint32](addr(result.tuner_freq))))

proc GetUsbStrings*(dev: Context, index: int): tuple[manufact, product, serial: string, err: Error] =
    ## *Returns*: dev's USB strings and 0 on success
    var m: array[0..256, char]
    var p: array[0..256, char]
    var s: array[0..256, char]
    var e = get_usb_strings(dev.ctx, cast[ptr char](addr(m[0])),
                            cast[ptr char](addr(p[0])),cast[ptr char](addr(s[0])))
    ($m, $p, $s, cast[Error](e))

# TODO(jdp): can seem to use openarray here
# WriteEeprom writes data to the EEPROM.
#
# data = buffer of data to be written, offset = address where the data should be written,
# leng = length of the data
# proc WriteEeprom*(dev: Context, data: openarray[uint8], offset: uint8): Error =
#     return cast[Error](write_eeprom(dev.ctx, cast[ptr uint8](addr(data[0])), offset, cast[uint16](data.len)))

proc ReadEeprom*(dev: Context, offset: uint8, length: uint16): tuple[data: seq[uint8], cnt: int, err: Error] =
    ## Reads data from the EEPROM.
    ##
    ## *Arguments*:
    ## - ``offset``: Address where the data should be read from
    ## - ``length``: The length of the data to be read
    ##
    ## *Returns*: A buffer containing data read from the EEPROM, the count of
    ## the data actually read into the buffer, 0 on success
    result.data = newseq[uint8](int(length))
    var e = read_eeprom(dev.ctx, addr(result.data[0]), offset, length)
    if e >= 0:
        result.cnt = e
        result.err = Success
    else:
        result.cnt = e
        result.err = cast[Error](e)

proc SetCenterFreq*(dev: Context, freq: int): Error =
    ## Sets the center frequency to freq Hz.
    ##
    ## *Returns*: 0 on success
    return cast[Error](set_center_freq(dev.ctx, cast[uint32](freq)))

proc GetCenterFreq*(dev: Context): int =
    ## *Returns*: the tuned frequency in Hz and 0 on success
    return cast[int](get_center_freq(dev.ctx))

proc SetFreqCorrection*(dev: Context, freq: int): Error =
    ## Sets the frequency correction value to freq Hz.
    ##
    ## *Returns*: 0 on success
    return cast[Error](set_freq_correction(dev.ctx, freq))

proc GetFreqCorrection*(dev: Context): int =
    ## *Returns*: the frequency correction value in ppm (parts per million)
    ## and 0 on success
    return get_freq_correction(dev.ctx)


proc GetTunerType*(dev: Context): rtlsdr_tuner =
    ## *Returns*: the tuner type and 0 on success
    return cast[rtlsdr_tuner](get_tuner_type(dev.ctx))

proc GetTunerGains*(dev: Context): tuple[gains: seq[int], err: Error] =
    ## *Returns*: a list of gains, in tenths of dB, supported by the tuner
    ## and 0 on success
    ## E.g. 115 means 11.5 dB.
    result.err = Success
    var i = cast[int](get_tuner_gains(dev.ctx, cast[ptr int](0)))
    if i < 0:
        result.err = cast[Error](i)
        return
    elif i == 0:
        result.gains = newseq[int](0)
        return
    result.gains = newseq[int](i)
    discard get_tuner_gains(dev.ctx, cast[ptr int](addr(result.gains[0])))

proc SetTunerGain*(dev: Context, gain: int): Error =
    ## Sets the tuner gain. Manual gain mode must be enabled for this to work.
    ##
    ## Valid gain values (in tenths of a dB, where 115 means 11.5 dB) for the
    ## tuner are:
    ##      -10, 15, 40, 65, 90, 115, 140, 165, 190, 215, 240, 290,
    ##      340, 420, 430, 450, 470, 490
    ##
    ## *Returns*: 0 on success
    if gain in gains_list:
        return cast[Error](set_tuner_gain(dev.ctx, gain))
    return ErrorInvalidParam

proc GetTunerGain*(dev: Context): int =
    ## *Returns*: The configured tuner gain
    ##
    ## Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
    return get_tuner_gain(dev.ctx)

proc SetTunerIfGain*(dev: Context, stage, gain: int): Error =
    ## Sets the Intermediate frequency gain stage number.
    ## Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
    ##
    ## *Arguments*:
    ## - ``stage``: intermediate frequency gain stage number (1 to 6 for E4000)
    ## - ``gain``: in tenths of a dB, -30 means -3.0 dB.
    ##
    ## *Returns*: 0 on success
    return cast[Error](set_tuner_if_gain(dev.ctx, stage, gain))

proc SetTunerGainMode*(dev: Context, manualMode: bool): Error =
    ## Sets the gain mode (automatic or manual) for the device.
    ## Manual gain mode must be enabled for the gain setter function to work.
    ##
    ## *Returns*: 0 on success
    return cast[Error](set_tuner_gain_mode(dev.ctx, cast[int](manualMode)))

proc SetSampleRate*(dev: Context, rate: int): Error =
    ## Selects the baseband filters according to the requested sample rate in Hz
    ##
    ## *Returns*: 0 on success
    return cast[Error](set_sample_rate(dev.ctx, cast[uint32](rate)))

proc GetSampleRate*(dev: Context): int =
    ## *Returns*: the configured sample rate in Hz
    return cast[int](get_sample_rate(dev.ctx))

proc SetTestMode*(dev: Context, testModeOn: bool): Error =
    ## Enables test mode that returns an 8 bit counter instead of samples.
    ## The counter is generated inside the RTL2832.
    ##
    ## *Returns*: 0 on success
    return cast[Error](set_testmode(dev.ctx, cast[int](testModeOn)))


proc SetAgcMode*(dev: Context, AGCModeOn: bool): Error =
    ## Enables or disables the internal digital AGC of the RTL2832.
    ##
    ## *Returns*: 0 on success
    return  cast[Error](set_agc_mode(dev.ctx, cast[int](AGCModeOn)))

proc SetDirectSampling*(dev: Context, on: bool): Error =
    ## Enables or disables the direct sampling mode. When enabled,
    ## the IF mode of the RTL2832 is activated, and rtlsdr_set_center_freq()
    ## will control the IF-frequency of the DDC, which can be used to tune
    ## from 0 to 28.8 MHz  (xtal frequency of the RTL2832).
    ##
    ## *Returns*: 0 on success
    return cast[Error](set_direct_sampling(dev.ctx, cast[int](on)))

proc GetDirectSampling*(dev: Context): sampling_state =
    ## *Returns*: the state of the direct sampling mode.
    return cast[sampling_state](get_direct_sampling(dev.ctx))

proc SetOffsetTuning*(dev: Context, enable: bool): Error =
    ## Enables or disables offset tuning for zero-IF tuners, which
    ## avoid problems caused by the DC offset of the ADCs and 1/f noise.
    ##
    ## *Returns*: 0 on success
    return cast[Error](set_offset_tuning(dev.ctx, cast[int](enable)))

proc GetOffsetTuning*(dev: Context): tuple[enabled: bool, err: Error] =
    ## *Returns*: the state of the offset tuning mode
    result.err = Success
    var i = get_offset_tuning(dev.ctx)
    if i == -1:
        result.err = ErrorOffsetTuningMode
    result.enabled = cast[bool](i)

# streaming functions

proc ResetBuffer*(dev: Context): Error =
    ##
    return cast[Error](reset_buffer(dev.ctx))

proc ReadSync*(dev: Context, length: int): tuple[buf: seq[char], n_read: int, err: Error] =
    ##
    result.buf = newseq[char](length)
    result.err = cast[Error](read_sync(dev.ctx, cast[ptr char](addr(result.buf)), length, cast[ptr int](addr(result.n_read))))

proc ReadAsync*(dev: Context, f: read_async_cb_t, userctx: pointer, buf_num, buf_len: int): Error =
    ## Reads samples from the device asynchronously. This function blocks
    ## until canceled via CancelAsync
    ##
    ## Optional buf_num buffer count, buf_num * buf_len = overall buffer size,
    ## set to 0 for default buffer count (32).
    ## Optional buf_len buffer length, must be multiple of 512, set to 0 for
    ## default buffer length (16 * 32 * 512).
    ##
    ## *Returns*: 0 on success
    return cast[Error](read_async(dev.ctx, f, userctx, cast[uint32](buf_num), cast[uint32](buf_len)))

proc CancelAsync*(dev: Context): Error =
    ## Cancels all pending asynchronous operations on the device.
    ##
    ## *Returns*: 0 on success
    return cast[Error](cancel_async(dev.ctx))




