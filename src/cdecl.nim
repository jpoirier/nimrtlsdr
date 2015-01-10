
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
proc rtlsdr_get_device_count(): uint32 {.cdecl, importc: "rtlsdr_get_device_count", dynlib: rtlsdr_lib.}
proc rtlsdr_get_device_name(index: uint32): cstring {.cdecl, importc: "rtlsdr_get_device_name", dynlib: rtlsdr_lib.}
proc rtlsdr_get_device_usb_strings(index: uint32; manufact: cstring; product: cstring; serial: cstring): int {.cdecl, importc: "rtlsdr_get_device_usb_strings", dynlib: rtlsdr_lib.}
proc rtlsdr_get_index_by_serial(serial: cstring): int {.cdecl, importc: "rtlsdr_get_index_by_serial", dynlib: rtlsdr_lib.}
proc rtlsdr_open*(dev: ptr devObjPtr; index: uint32): int {.cdecl, importc: "rtlsdr_open", dynlib: rtlsdr_lib.}
proc rtlsdr_close(dev: devObjPtr): int {.cdecl, importc: "rtlsdr_close", dynlib: rtlsdr_lib.}
proc rtlsdr_set_xtal_freq(dev: devObjPtr; rtl_freq: uint32; tuner_freq: uint32): int {.cdecl, importc: "rtlsdr_set_xtal_freq", dynlib: rtlsdr_lib.}
proc rtlsdr_get_xtal_freq(dev: devObjPtr; rtl_freq: ptr uint32; tuner_freq: ptr uint32): int {.cdecl, importc: "rtlsdr_get_xtal_freq", dynlib: rtlsdr_lib.}
proc rtlsdr_get_usb_strings(dev: devObjPtr; manufact: cstring; product: cstring; serial: cstring): int {.cdecl, importc: "rtlsdr_get_usb_strings", dynlib: rtlsdr_lib.}
proc rtlsdr_write_eeprom(dev: devObjPtr; data: ptr uint8; offset: uint8; len: uint16): int {.cdecl, importc: "rtlsdr_write_eeprom", dynlib: rtlsdr_lib.}
proc rtlsdr_read_eeprom(dev: devObjPtr; data: ptr uint8; offset: uint8; len: uint16): int {.cdecl, importc: "rtlsdr_read_eeprom", dynlib: rtlsdr_lib.}
proc rtlsdr_set_center_freq(dev: devObjPtr; freq: uint32): int {.cdecl, importc: "rtlsdr_set_center_freq", dynlib: rtlsdr_lib.}
proc rtlsdr_get_center_freq(dev: devObjPtr): uint32 {.cdecl, importc: "rtlsdr_get_center_freq", dynlib: rtlsdr_lib.}
proc rtlsdr_set_freq_correction(dev: devObjPtr; ppm: int): int {.cdecl, importc: "rtlsdr_set_freq_correction", dynlib: rtlsdr_lib.}
proc rtlsdr_get_freq_correction(dev: devObjPtr): int {.cdecl, importc: "rtlsdr_get_freq_correction", dynlib: rtlsdr_lib.}
proc rtlsdr_get_tuner_type(dev: devObjPtr): RtlSdrTuner {.cdecl, importc: "rtlsdr_get_tuner_type", dynlib: rtlsdr_lib.}
proc rtlsdr_get_tuner_gains(dev: devObjPtr; gains: ptr int): int {.cdecl, importc: "rtlsdr_get_tuner_gains", dynlib: rtlsdr_lib.}
proc rtlsdr_set_tuner_gain(dev: devObjPtr; gain: int): int {.cdecl, importc: "rtlsdr_set_tuner_gain", dynlib: rtlsdr_lib.}
proc rtlsdr_get_tuner_gain(dev: devObjPtr): int {.cdecl, importc: "rtlsdr_get_tuner_gain", dynlib: rtlsdr_lib.}
proc rtlsdr_set_tuner_if_gain(dev: devObjPtr; stage: int; gain: int): int {.cdecl, importc: "rtlsdr_set_tuner_if_gain", dynlib: rtlsdr_lib.}
proc rtlsdr_set_tuner_gain_mode(dev: devObjPtr; manual: int): int {.cdecl, importc: "rtlsdr_set_tuner_gain_mode", dynlib: rtlsdr_lib.}
proc rtlsdr_set_sample_rate(dev: devObjPtr; rate: uint32): int {.cdecl, importc: "rtlsdr_set_sample_rate", dynlib: rtlsdr_lib.}
proc rtlsdr_get_sample_rate(dev: devObjPtr): uint32 {.cdecl, importc: "rtlsdr_get_sample_rate", dynlib: rtlsdr_lib.}
proc rtlsdr_set_testmode(dev: devObjPtr; on: int): int {.cdecl, importc: "rtlsdr_set_testmode", dynlib: rtlsdr_lib.}
proc rtlsdr_set_agc_mode(dev: devObjPtr; on: int): int {.cdecl, importc: "rtlsdr_set_agc_mode", dynlib: rtlsdr_lib.}
proc rtlsdr_set_direct_sampling(dev: devObjPtr; on: int): int {.cdecl, importc: "rtlsdr_set_direct_sampling", dynlib: rtlsdr_lib.}
proc rtlsdr_get_direct_sampling(dev: devObjPtr): int {.cdecl, importc: "rtlsdr_get_direct_sampling", dynlib: rtlsdr_lib.}
proc rtlsdr_set_offset_tuning(dev: devObjPtr; on: int): int {.cdecl, importc: "rtlsdr_set_offset_tuning", dynlib: rtlsdr_lib.}
proc rtlsdr_get_offset_tuning(dev: devObjPtr): int {.cdecl, importc: "rtlsdr_get_offset_tuning", dynlib: rtlsdr_lib.}
proc rtlsdr_reset_buffer(dev: devObjPtr): int {.cdecl, importc: "rtlsdr_reset_buffer", dynlib: rtlsdr_lib.}
proc rtlsdr_read_sync(dev: devObjPtr; buf: pointer; len: int; n_read: ptr int): int {.cdecl, importc: "rtlsdr_read_sync", dynlib: rtlsdr_lib.}
proc rtlsdr_read_async(dev: devObjPtr; cb: readAsyncCbProc; ctx: pointer; buf_num: uint32; buf_len: uint32): int {.cdecl, importc: "rtlsdr_read_async", dynlib: rtlsdr_lib.}
proc rtlsdr_cancel_async(dev: devObjPtr): int {.cdecl, importc: "rtlsdr_cancel_async", dynlib: rtlsdr_lib.}
