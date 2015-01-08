# See license.txt for usage.

when defined(windows):
    const rtlsdr_lib* = "rtlsdr.dll"
elif defined(macosx):
    const rtlsdr_lib* = "librtlsdr.dylib"
else:
    const rtlsdr_lib* = "librtlsdr.so"


type SamplingMode int

const
    # default parameter settings
    Dflt_GAIN = "auto"
    DfltFc = 80e6
    DfltRs = 1.024e6
    DfltReadSz = 1024
    CrystalFreq = 28800000
    DfltSampleRate = 2048000
    DfltAsyncBufNum = 32
    DfltBufLen = (16 * 16384)
    MinBufLen = 512
    MaxBufLen = (256 * 16384)

type
    OpStatus* {.size: sizeof(int).} = enum
        Success = (0, nil)
        ErrorIo = (-1, "input/output error")
        ErrorInvalidParam = (-1, "invalid parameter(s)")
        ErrorAccess = (-3, "access denied (insufficient permissions)")
        ErrorNoDevice = (-4, "no such device (it may have been disconnected)")
        ErrorNotFound = (-5, "entity not found")
        ErrorBusy = (-6, "resource busy")
        ErrorTimeout = (-7, "operation timed out")
        ErrorOverflow = (-8, "overflow")
        ErrorPipe = (-9, "pipe error")
        ErrorInterrupted = (-10, "system call interrupted (perhaps due to signal)")
        ErrorNoMem = (-11, "insufficient memory")
        ErrorNotSupported = (-12, "operation not supported or unimplemented on this platform")

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
    SamplingQADC = (1, "QADC")

type
    pdev_t* = ptr dev_t
    dev_t*{.final.} = object

type
    Context* = object of TObject
        var ctx: pdev_t

# GetDeviceCount gets the number of valid USB dongles detected.
proc GetDeviceCount*(): int =
    return cast[int](get_device_count())

proc get_device_count(): uint32 {.cdecl, importc: "rtlsdr_get_device_count", dynlib: rtlsdr_lib.}

# GetDeviceName gets the name of the USB dongle device via index,
# e.g. from an index returned from calling GainValues.
proc GetDeviceName(index; int)*: string =
    return $(get_device_name(cast[uint32](index)))

proc get_device_name(index: uint32): cstring {.cdecl, importc: "rtlsdr_get_device_name", dynlib: rtlsdr_lib.}

# Get USB device strings.
proc GetDeviceUsbStrings*(index: int): tuple[manufact, product, serial: string, status: OpStatus] =
    var m: array[0..256, char]
    var p: array[0..256, char]
    var s: array[0..256, char]
    var e = get_device_usb_strings(cast[uint32](index),
                                    cast[ptr char](addr(m[0])),
                                    cast[ptr char](addr(p[0])),
                                    cast[ptr char](addr(s[0])))
    ($m, $p, $s, cast[OpStatus](e))

proc get_device_usb_strings(index: uint32; manufact: cstring; product: cstring; serial: cstring): int {.cdecl, importc: "rtlsdr_get_device_usb_strings", dynlib: rtlsdr_lib.}

# Get device index by USB serial string descriptor.
# Returns device index of first device where the name matched.
proc GetIndexBySerial*(serial: string): tuple[index: int, status: OpStatus] =
    result.index = get_index_by_serial(string)
    if result.index >= 0:
        result.status = Success
    elif:
        result.status = cast[OpStatus](result.index)

proc get_index_by_serial(serial: cstring): int {.cdecl, importc: "rtlsdr_get_index_by_serial", dynlib: rtlsdr_lib.}

# Open returns a valid device's context.
proc Open(index: int): [dev: Context, status: OpStatus] =
    result.status = cast[OpStatus](rtlsdr_open(addr(result.ctx), cast[uint32](index)))

proc rtlsdr_open*(dev: ptr pdev_t; index: uint32): int {.cdecl, importc: "rtlsdr_open", dynlib: rtlsdr_lib.}


# Close closes a previously opened device context.
proc Close*(c: Context): OpStatus =
    return cast[OpStatus](rtlsdr_close(c.ctx))

proc rtlsdr_close(c.dev: pdev_t): int {.cdecl, importc: "rtlsdr_close", dynlib: rtlsdr_lib.}


# configuration functions

# Set crystal oscillator frequencies used for the RTL2832 and the tuner IC.
#
# Usually both ICs use the same clock. Changing the clock may make sense if
# you are applying an external clock to the tuner or to compensate the
# frequency (and samplerate) error caused by the original (cheap) crystal.
#
# NOTE: Call this function only if you fully understand the implications.
# Values are in Hz.
proc SetXtalFreq*(c: Context, rtl_freq, tuner_freq: int): OpStatus =
    return cast[OpStatus](set_xtal_freq(c.ctx, cast[uint32](rtl_freq), cast[uint32](tuner_freq)))

proc set_xtal_freq(dev: pdev_t; rtl_freq: uint32; tuner_freq: uint32): int {.cdecl, importc: "rtlsdr_set_xtal_freq", dynlib: rtlsdr_lib.}

# Get crystal oscillator frequencies used for the RTL2832 and the tuner IC.
#
# Usually both ICs use the same clock.
# Frequency values are in Hz.
proc GetXtalFreq(c: Context): tuple[rtl_freq, tuner_freq: int, status: OpStatus] =
    result.status = cast[OpStatus](get_xtal_freq(c.ctx, cast[ptr uint32](addr(result.rtl_freq)), cast[ptr uint32](addr(result.tuner_freq))))

proc get_xtal_freq(dev: pdev_t; rtl_freq: ptr uint32; tuner_freq: ptr uint32): int {.cdecl, importc: "rtlsdr_get_xtal_freq", dynlib: rtlsdr_lib.}

# Get USB strings.
proc GetUsbStrings*(c: Context, index: int): tuple[manufact, product, serial: string, status: OpStatus] =
    var m: array[0..256, char]
    var p: array[0..256, char]
    var s: array[0..256, char]
    var e = get_device_usb_strings(c.ctx,
                                    cast[ptr char](addr(m[0])),
                                    cast[ptr char](addr(p[0])),
                                    cast[ptr char](addr(s[0])))
    ($m, $p, $s, cast[OpStatus](e))

proc get_usb_strings(dev: pdev_t; manufact: cstring; product: cstring; serial: cstring): int {.cdecl, importc: "rtlsdr_get_usb_strings", dynlib: rtlsdr_lib.}

# Write the EEPROM
#
# data = buffer of data to be written, offset = address where the data should be written,
# leng = length of the data
proc WriteEeprom*(c: Context, data: openarray[uint8], offset uint8): status
    return cast[OpStatus](write_eeprom(c.ctx, cast[ptr uint8]addr(data[0]), offset, cast[uint16](data.len)))

proc write_eeprom(dev: pdev_t; data: ptr uint8_t; offset: uint8_t; len: uint16_t): int {.cdecl, importc: "rtlsdr_write_eeprom", dynlib: rtlsdr_lib.}

# Read the EEPROM
#
# data = buffer where the data should be written, offset = address where the data should be read from,
# leng = length of the data
proc ReadEeprom*(c: Context, offset: uint8; len: uint16): tuple[data: seq[uint8], status: OpStatus] =
    result.data = newseq[uint8](len)
    result.status = cast[OpStatus](read_eeprom(c.ctx, addr(data[0]), offset, len))
proc read_eeprom(dev: pdev_t; data: ptr uint8_t; offset: uint8_t; len: uint16_t): int {.cdecl, importc: "rtlsdr_read_eeprom", dynlib: rtlsdr_lib.}

# Set the center frequency.
#
# Frequency values are in Hz.
proc SetCenterFreq*(c: Context, freq: int): status =
    return cast[OpStatus](set_center_freq(c.ctx, cast[uint32](freq)))
proc set_center_freq(dev: pdev_t; freq: uint32): int {.cdecl, importc: "rtlsdr_set_center_freq", dynlib: rtlsdr_lib.}

# Get the tuned frequency.
#
# Return value in Hz.
proc GetCenterFreq*(c: Context): int =
    return cast[int](get_center_freq(c.ctx))
proc get_center_freq(dev: pdev_t): uint32 {.cdecl, importc: "rtlsdr_get_center_freq", dynlib: rtlsdr_lib.}

# Set the frequency correction value.
#
# Frequency values are in Hz.
proc SetFreqCorrection*(c: Context, freq: int): status =
    return cast[OpStatus](set_freq_correction(c.ctx, freq))
proc set_freq_correction(dev: pdev_t; ppm: int): int {.cdecl, importc: "rtlsdr_set_freq_correction", dynlib: rtlsdr_lib.}

# Get actual frequency correction value of the device.
#
# Correction value in ppm (parts per million).
proc GetFreqCorrection*(c: Context): int =
    return get_freq_correction(c.ctx)
proc get_freq_correction(dev: pdev_t): int {.cdecl, importc: "rtlsdr_get_freq_correction", dynlib: rtlsdr_lib.}

# Get the tuner type.
proc GetTunerType*(c: Context): rtlsdr_tuner =
    return cast[rtlsdr_tuner](get_tuner_type(c.ctx))
proc get_tuner_type(dev: pdev_t): rtlsdr_tuner {.cdecl, importc: "rtlsdr_get_tuner_type", dynlib: rtlsdr_lib.}

# Get a list of gains supported by the tuner.
#
# Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
proc GetTunerGains*(c: Context): tuple[gains: seq[int], status: OpStatus] =
    result.status = Success
    var i = cast[int](get_tuner_gains(c.ctx, cast[ptr int](0)))
    if i < 0:
        result.err = cast[OpStatus](i)
        return
    elif i == 0:
        result.gains = newseq[char](0)
        return
    result.gains = newseq[char](i)
    discard get_tuner_type(c.ctx, cast[ptr int](addr(result.gains[0])))

proc get_tuner_gains(dev: pdev_t; gains: ptr int): int {.cdecl, importc: "rtlsdr_get_tuner_gains", dynlib: rtlsdr_lib.}

# Set the gain.
# Manual gain mode must be enabled for this to work.
#
# Valid gain values (in tenths of a dB) for the E4000 tuner:
# -10, 15, 40, 65, 90, 115, 140, 165, 190, 215, 240, 290,
# 340, 420, 430, 450, 470, 490
# Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
proc SetTunerGain*(c: Context, gain: int): OpStatus =
    return cast[OpStatus](set_tuner_gain(c.ctx, gain))
proc set_tuner_gain(dev: pdev_t; gain: int): int {.cdecl, importc: "rtlsdr_set_tuner_gain", dynlib: rtlsdr_lib.}

# Get the configured gain.
#
# Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
proc GetTunerGain*(c: Context): int =
    return set_tuner_gain(c.ctx)
proc get_tuner_gain(dev: pdev_t): int {.cdecl, importc: "rtlsdr_get_tuner_gain", dynlib: rtlsdr_lib.}

# Set the intermediate frequency gain.
#
# Intermediate frequency gain stage number (1 to 6 for E4000).
# Gain values are in tenths of dB, e.g. 115 means 11.5 dB.
proc SetTunerIfGain*(c: Context, stage, gain: int): OpStatus =
    return cast[OpStatus](set_tuner_if_gain(c.ctx, gain))
proc set_tuner_if_gain(dev: pdev_t; stage: int; gain: int): int {.cdecl, importc: "rtlsdr_set_tuner_if_gain", dynlib: rtlsdr_lib.}

# Set the gain mode (automatic/manual) for the device.
# Manual gain mode must be enabled for the gain setter function to work.
proc SetTunerGainMode*(c: Context, manualMode: bool): OpStatus =
    return cast[OpStatus](set_tuner_gain_mode(c.ctx, cast[int](manualMode)))
proc set_tuner_gain_mode(dev: pdev_t; manual: int): int {.cdecl, importc: "rtlsdr_set_tuner_gain_mode", dynlib: rtlsdr_lib.}

# Selects the baseband filters according to the requested sample rate.
#
# Samplerate is in Hz.
proc SetSampleRate*(c: Context, rate: int): OpStatus =
    return cast[OpStatus](set_sample_rate(c.ctx, cast[int32](rate)))
proc set_sample_rate(dev: pdev_t; rate: uint32): int {.cdecl, importc: "rtlsdr_set_sample_rate", dynlib: rtlsdr_lib.}

# Get actual sample rate the device is configured to.
#
# Samplerate is in Hz.
proc GetSampleRate*(c: Context): int =
    return cast[int](get_sample_rate(c.ctx))
proc get_sample_rate(dev: pdev_t): uint32 {.cdecl, importc: "rtlsdr_get_sample_rate", dynlib: rtlsdr_lib.}

# Enable test mode that returns an 8 bit counter instead of the samples.
# The counter is generated inside the RTL2832.
proc SetTestMode*(c: Context, testModeOn: bool): OpStatus =
    return cast[OpStatus](set_testmode(c.ctx, cast[int](testModeOn)))
proc set_testmode(dev: pdev_t; on: int): int {.cdecl, importc: "rtlsdr_set_testmode", dynlib: rtlsdr_lib.}

# Enable or disable the internal digital AGC of the RTL2832.
proc SetAgcMode*(c: Context, AGCModeOn: bool): OpStatus =
    return  cast[OpStatus](set_agc_mode(c.ctx, cast[int](AGCModeOn)))
proc set_agc_mode(dev: pdev_t; on: int): int {.cdecl, importc: "rtlsdr_set_agc_mode", dynlib: rtlsdr_lib.}

# Enable or disable the direct sampling mode. When enabled, the IF mode
# of the RTL2832 is activated, and rtlsdr_set_center_freq() will control
# the IF-frequency of the DDC, which can be used to tune from 0 to 28.8 MHz
# (xtal frequency of the RTL2832).
proc SetDirectSampling*(c: Context, on bool): OpStatus =
    return cast[OpStatus](set_direct_sampling(c.ctx, cast[int](on)))
proc set_direct_sampling(dev: pdev_t; on: int): int {.cdecl, importc: "rtlsdr_set_direct_sampling", dynlib: rtlsdr_lib.}

// Get state of the direct sampling mode.
proc GetDirectSampling*(c: Context): sampling_state =
    return cast[sampling_state](get_direct_sampling(c.ctx))
proc get_direct_sampling(dev: pdev_t): int {.cdecl, importc: "rtlsdr_get_direct_sampling", dynlib: rtlsdr_lib.}

# Enable or disable offset tuning for zero-IF tuners, which allows to avoid
# problems caused by the DC offset of the ADCs and 1/f noise.
proc SetOffsetTuning*(c: Context, enable: bool): OpStatus =
    return cast[OpStatus](set_offset_tuning(c.ctx, cast[int](enable)))
proc set_offset_tuning(dev: pdev_t; on: int): int {.cdecl, importc: "rtlsdr_set_offset_tuning", dynlib: rtlsdr_lib.}

# Get state of the offset tuning mode.
proc GetOffsetTuning*(c: Context): tuple[enabled: bool, status: string] =
    result.status = nil
    var i = get_offset_tuning(c.ctx)
    if i == -1:
        result.status = "error getting offset tuning mode"
    result.status = cast[bool](i)

proc get_offset_tuning(dev: pdev_t): int {.cdecl, importc: "rtlsdr_get_offset_tuning", dynlib: rtlsdr_lib.}


# streaming functions

proc ResetBuffer*(c: Context): OpStatus =
    return cast[OpStatus](reset_buffer(c.ctx))
proc reset_buffer(dev: pdev_t): int {.cdecl, importc: "rtlsdr_reset_buffer", dynlib: rtlsdr_lib.}

proc ReadSync*(c: Context, length: int): [buf: seq[char], int: n_read, status: OpStatus] =
    result.buf = newseq[char](length)
    result.status = cast[OpStatus](read_sync(c.ctx, length, cast[ptr int](addr(result.n_read))))
proc read_sync(dev: pdev_t; buf: pointer; len: int; n_read: ptr int): int {.cdecl, importc: "rtlsdr_read_sync", dynlib: rtlsdr_lib.}

type
  read_async_cb_t* = proc (buf: ptr uint8; len: uint32; ctx: pointer) {.cdecl.}


# Read samples from the device asynchronously. This function will block until
# it is being canceled using CancelAsync
#
# Optional buf_num buffer count, buf_num * buf_len = overall buffer size,
# set to 0 for default buffer count (32).
# Optional buf_len buffer length, must be multiple of 512, set to 0 for
# default buffer length (16 * 32 * 512).
proc ReadAsync*(c: Context, f read_async_cb_t, userctx pointer, buf_num, buf_len: int): OpStatus =
    return cast[OpStatus](read_async(c.ctx, f, userctx, cast[uint32](buf_num), cast[uint32](buf_len)))
proc read_async(dev: pdev_t; cb: read_async_cb_t; ctx: pointer; buf_num: uint32; buf_len: uint32): int {.cdecl, importc: "rtlsdr_read_async", dynlib: rtlsdr_lib.}

# Cancel all pending asynchronous operations on the device.
proc CancelAsync**(c: Context): OpStatus =
    return cast[OpStatus](cancel_async(c.ctx))
proc cancel_async(dev: pdev_t): int {.cdecl, importc: "rtlsdr_cancel_async", dynlib: rtlsdr_lib.}

