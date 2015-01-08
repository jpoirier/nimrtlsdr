# See license.txt for usage.

when defined(windows):
    const rtlsdr_lib* = "rtlsdr.dll"
elif defined(macosx):
    const rtlsdr_lib* = "librtlsdr.dylib"
else:
    const rtlsdr_lib* = "librtlsdr.so"


# include "cdecl.nim"



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
        Success = (0, "")

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
    Context* = object of TObject
        ctx*: pdev_t

type
  read_async_cb_t* = proc (buf: ptr uint8; len: uint32; ctx: pointer) {.cdecl.}

include "cdecl.nim"

# GetDeviceCount gets the number of valid USB dongles detected.
proc GetDeviceCount*(): int =
    return cast[int](get_device_count())

# GetDeviceName gets the name of the USB dongle device via index,
# e.g. from an index returned from calling GainValues.
proc GetDeviceName*(index: int): string =
    return $(get_device_name(cast[uint32](index)))

# GetDeviceUsbStrings gets the USB device strings.
proc GetDeviceUsbStrings*(index: int): tuple[manufact, product, serial: string, err: Error] =
    var m: array[0..256, char]
    var p: array[0..256, char]
    var s: array[0..256, char]
    var e = get_device_usb_strings(cast[uint32](index),
                                    cast[ptr char](addr(m[0])),
                                    cast[ptr char](addr(p[0])),
                                    cast[ptr char](addr(s[0])))
    ($m, $p, $s, cast[Error](e))

# GetIndexBySerial gets the device index by USB serial string descriptor.
# Returns device index of first device where the name matched.
proc GetIndexBySerial*(serial: string): tuple[index: int, err: Error] =
    result.index = get_index_by_serial(serial)
    if result.index >= 0:
        result.err = Success
    else:
        result.err = cast[Error](result.index)

# Open opens a device based on index and returns a valid device context.
proc Open(index: int): tuple[dev: Context, err: Error] =
    result.err = cast[Error](rtlsdr_open(addr(result.dev.ctx), cast[uint32](index)))

# Close closes a previously opened device.
proc Close*(c: Context): Error =
    return cast[Error](rtlsdr_close(c.ctx))

# configuration functions

# SetXtalFreq sets the crystal oscillator frequencies used for the RTL2832
# and the tuner IC.
#
# Usually both ICs use the same clock. Changing the clock may make sense if
# you are applying an external clock to the tuner or to compensate the
# frequency (and samplerate) error caused by the original (cheap) crystal.
#
# NOTE: Call this function only if you fully understand the implications.
# Values are in Hz.
proc SetXtalFreq*(c: Context, rtl_freq, tuner_freq: int): Error =
    return cast[Error](set_xtal_freq(c.ctx, cast[uint32](rtl_freq), cast[uint32](tuner_freq)))

# GetXtalFreq gets the crystal oscillator frequencies used for the RTL2832
# and the tuner IC.
#
# Usually both ICs use the same clock.
# Frequency values are in Hz.
proc GetXtalFreq(c: Context): tuple[rtl_freq, tuner_freq: int, err: Error] =
    result.err = cast[Error](get_xtal_freq(c.ctx, cast[ptr uint32](addr(result.rtl_freq)), cast[ptr uint32](addr(result.tuner_freq))))

# GetUsbStrings gets the USB strings of the device.
proc GetUsbStrings*(c: Context, index: int): tuple[manufact, product, serial: string, err: Error] =
    var m: array[0..256, char]
    var p: array[0..256, char]
    var s: array[0..256, char]
    var e = get_usb_strings(c.ctx, cast[ptr char](addr(m[0])),
                            cast[ptr char](addr(p[0])),cast[ptr char](addr(s[0])))
    ($m, $p, $s, cast[Error](e))

# TODO(jdp): can seem to use openarray here
# WriteEeprom writes data to the EEPROM.
#
# data = buffer of data to be written, offset = address where the data should be written,
# leng = length of the data
# proc WriteEeprom*(c: Context, data: openarray[uint8], offset: uint8): Error =
#     return cast[Error](write_eeprom(c.ctx, cast[ptr uint8](addr(data[0])), offset, cast[uint16](data.len)))

# ReadEeprom reads buffered data from the EEPROM.
#
# data = buffer where the data should be written, offset = address where the data should be read from,
# leng = length of the data
proc ReadEeprom*(c: Context, offset: uint8, length: uint16): tuple[data: seq[uint8], err: Error] =
    result.data = newseq[uint8](int(length))
    result.err = cast[Error](read_eeprom(c.ctx, addr(result.data[0]), offset, length))

# SetCenterFreq sets the center frequency.
#
# Frequency values are in Hz.
proc SetCenterFreq*(c: Context, freq: int): Error =
    return cast[Error](set_center_freq(c.ctx, cast[uint32](freq)))

# GetCenterFreq gets the tuned frequency.
#
# Return value in Hz.
proc GetCenterFreq*(c: Context): int =
    return cast[int](get_center_freq(c.ctx))

# SetFreqCorrection sets the frequency correction value.
#
# Frequency values are in Hz.
proc SetFreqCorrection*(c: Context, freq: int): Error =
    return cast[Error](set_freq_correction(c.ctx, freq))

# GetFreqCorrection gets the frequency correction value.
#
# Correction value in ppm (parts per million).
proc GetFreqCorrection*(c: Context): int =
    return get_freq_correction(c.ctx)

# GetTunerType gets the tuner type.
proc GetTunerType*(c: Context): rtlsdr_tuner =
    return cast[rtlsdr_tuner](get_tuner_type(c.ctx))

# GetTunerGains gets a list of gains supported by the tuner.
#
# Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
proc GetTunerGains*(c: Context): tuple[gains: seq[int], err: Error] =
    result.err = Success
    var i = cast[int](get_tuner_gains(c.ctx, cast[ptr int](0)))
    if i < 0:
        result.err = cast[Error](i)
        return
    elif i == 0:
        result.gains = newseq[int](0)
        return
    result.gains = newseq[int](i)
    discard get_tuner_gains(c.ctx, cast[ptr int](addr(result.gains[0])))

# SetTunerGain sets the tuner gain.
# Manual gain mode must be enabled for this to work.
#
# Valid gain values (in tenths of a dB) for the E4000 tuner:
# -10, 15, 40, 65, 90, 115, 140, 165, 190, 215, 240, 290,
# 340, 420, 430, 450, 470, 490
# Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
proc SetTunerGain*(c: Context, gain: int): Error =
    return cast[Error](set_tuner_gain(c.ctx, gain))


# GetTunerGain get the configured tuner gain.
#
# Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
proc GetTunerGain*(c: Context): int =
    return get_tuner_gain(c.ctx)

# SetTunerIfGain sets the intermediate frequency gain.
#
# Intermediate frequency gain stage number (1 to 6 for E4000).
# Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
proc SetTunerIfGain*(c: Context, stage, gain: int): Error =
    return cast[Error](set_tuner_if_gain(c.ctx, stage, gain))


# SetTunerGainMode sets the gain mode (automatic/manual) for the device.
# Manual gain mode must be enabled for the gain setter function to work.
proc SetTunerGainMode*(c: Context, manualMode: bool): Error =
    return cast[Error](set_tuner_gain_mode(c.ctx, cast[int](manualMode)))

# SetSampleRate selects the baseband filters according to the requested sample rate.
#
# Samplerate is in Hz.
proc SetSampleRate*(c: Context, rate: int): Error =
    return cast[Error](set_sample_rate(c.ctx, cast[uint32](rate)))

# GetSampleRate gets the configured sample rate.
#
# Samplerate is in Hz.
proc GetSampleRate*(c: Context): int =
    return cast[int](get_sample_rate(c.ctx))

# SetTestMode enables test mode, which returns an 8 bit counter instead of samples.
# The counter is generated inside the RTL2832.
proc SetTestMode*(c: Context, testModeOn: bool): Error =
    return cast[Error](set_testmode(c.ctx, cast[int](testModeOn)))

# SetAgcMode Eenables or disables the internal digital AGC of the RTL2832.
proc SetAgcMode*(c: Context, AGCModeOn: bool): Error =
    return  cast[Error](set_agc_mode(c.ctx, cast[int](AGCModeOn)))

# SetDirectSampling enables or disables the direct sampling mode. When enabled,
# the IF mode of the RTL2832 is activated, and rtlsdr_set_center_freq() will
# control the IF-frequency of the DDC, which can be used to tune from 0 to 28.8 MHz
# (xtal frequency of the RTL2832).
proc SetDirectSampling*(c: Context, on: bool): Error =
    return cast[Error](set_direct_sampling(c.ctx, cast[int](on)))

# GetDirectSampling gets the state of the direct sampling mode.
proc GetDirectSampling*(c: Context): sampling_state =
    return cast[sampling_state](get_direct_sampling(c.ctx))

# SetOffsetTuning enables or disables offset tuning for zero-IF tuners, which
# allows to avoid problems caused by the DC offset of the ADCs and 1/f noise.
proc SetOffsetTuning*(c: Context, enable: bool): Error =
    return cast[Error](set_offset_tuning(c.ctx, cast[int](enable)))

# GetOffsetTuning gets the state of the offset tuning mode.
proc GetOffsetTuning*(c: Context): tuple[enabled: bool, err: string] =
    result.err = nil
    var i = get_offset_tuning(c.ctx)
    if i == -1:
        result.err = "error getting offset tuning mode"
    result.enabled = cast[bool](i)


# streaming functions

proc ResetBuffer*(c: Context): Error =
    return cast[Error](reset_buffer(c.ctx))

proc ReadSync*(c: Context, length: int): tuple[buf: seq[char], n_read: int, err: Error] =
    result.buf = newseq[char](length)
    result.err = cast[Error](read_sync(c.ctx, cast[ptr char](addr(result.buf)), length, cast[ptr int](addr(result.n_read))))

# ReadAsync reads samples from the device asynchronously. This function blocks
# until canceled via CancelAsync
#
# Optional buf_num buffer count, buf_num * buf_len = overall buffer size,
# set to 0 for default buffer count (32).
# Optional buf_len buffer length, must be multiple of 512, set to 0 for
# default buffer length (16 * 32 * 512).
proc ReadAsync*(c: Context, f: read_async_cb_t, userctx: pointer, buf_num, buf_len: int): Error =
    return cast[Error](read_async(c.ctx, f, userctx, cast[uint32](buf_num), cast[uint32](buf_len)))

# CancelAsync cancels all pending asynchronous operations on the device.
proc CancelAsync*(c: Context): Error =
    return cast[Error](cancel_async(c.ctx))




