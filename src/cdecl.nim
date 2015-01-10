
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
proc get_device_count(): uint32 {.cdecl, importc: "rtlsdr_get_device_count", dynlib: rtlsdr_lib.}
proc get_device_name(index: uint32): cstring {.cdecl, importc: "rtlsdr_get_device_name", dynlib: rtlsdr_lib.}
proc get_device_usb_strings(index: uint32; manufact: cstring; product: cstring; serial: cstring): int {.cdecl, importc: "rtlsdr_get_device_usb_strings", dynlib: rtlsdr_lib.}
proc get_index_by_serial(serial: cstring): int {.cdecl, importc: "rtlsdr_get_index_by_serial", dynlib: rtlsdr_lib.}
proc rtlsdr_open*(dev: ptr pdev_t; index: uint32): int {.cdecl, importc: "rtlsdr_open", dynlib: rtlsdr_lib.}
proc rtlsdr_close(dev: pdev_t): int {.cdecl, importc: "rtlsdr_close", dynlib: rtlsdr_lib.}
proc set_xtal_freq(dev: pdev_t; rtl_freq: uint32; tuner_freq: uint32): int {.cdecl, importc: "rtlsdr_set_xtal_freq", dynlib: rtlsdr_lib.}
proc get_xtal_freq(dev: pdev_t; rtl_freq: ptr uint32; tuner_freq: ptr uint32): int {.cdecl, importc: "rtlsdr_get_xtal_freq", dynlib: rtlsdr_lib.}
proc get_usb_strings(dev: pdev_t; manufact: cstring; product: cstring; serial: cstring): int {.cdecl, importc: "rtlsdr_get_usb_strings", dynlib: rtlsdr_lib.}
proc write_eeprom(dev: pdev_t; data: ptr uint8; offset: uint8; len: uint16): int {.cdecl, importc: "rtlsdr_write_eeprom", dynlib: rtlsdr_lib.}
proc read_eeprom(dev: pdev_t; data: ptr uint8; offset: uint8; len: uint16): int {.cdecl, importc: "rtlsdr_read_eeprom", dynlib: rtlsdr_lib.}
proc set_center_freq(dev: pdev_t; freq: uint32): int {.cdecl, importc: "rtlsdr_set_center_freq", dynlib: rtlsdr_lib.}
proc get_center_freq(dev: pdev_t): uint32 {.cdecl, importc: "rtlsdr_get_center_freq", dynlib: rtlsdr_lib.}
proc set_freq_correction(dev: pdev_t; ppm: int): int {.cdecl, importc: "rtlsdr_set_freq_correction", dynlib: rtlsdr_lib.}
proc get_freq_correction(dev: pdev_t): int {.cdecl, importc: "rtlsdr_get_freq_correction", dynlib: rtlsdr_lib.}
proc get_tuner_type(dev: pdev_t): rtlsdr_tuner {.cdecl, importc: "rtlsdr_get_tuner_type", dynlib: rtlsdr_lib.}
proc get_tuner_gains(dev: pdev_t; gains: ptr int): int {.cdecl, importc: "rtlsdr_get_tuner_gains", dynlib: rtlsdr_lib.}
proc set_tuner_gain(dev: pdev_t; gain: int): int {.cdecl, importc: "rtlsdr_set_tuner_gain", dynlib: rtlsdr_lib.}
proc get_tuner_gain(dev: pdev_t): int {.cdecl, importc: "rtlsdr_get_tuner_gain", dynlib: rtlsdr_lib.}
proc set_tuner_if_gain(dev: pdev_t; stage: int; gain: int): int {.cdecl, importc: "rtlsdr_set_tuner_if_gain", dynlib: rtlsdr_lib.}
proc set_tuner_gain_mode(dev: pdev_t; manual: int): int {.cdecl, importc: "rtlsdr_set_tuner_gain_mode", dynlib: rtlsdr_lib.}
proc set_sample_rate(dev: pdev_t; rate: uint32): int {.cdecl, importc: "rtlsdr_set_sample_rate", dynlib: rtlsdr_lib.}
proc get_sample_rate(dev: pdev_t): uint32 {.cdecl, importc: "rtlsdr_get_sample_rate", dynlib: rtlsdr_lib.}
proc set_testmode(dev: pdev_t; on: int): int {.cdecl, importc: "rtlsdr_set_testmode", dynlib: rtlsdr_lib.}
proc set_agc_mode(dev: pdev_t; on: int): int {.cdecl, importc: "rtlsdr_set_agc_mode", dynlib: rtlsdr_lib.}
proc set_direct_sampling(dev: pdev_t; on: int): int {.cdecl, importc: "rtlsdr_set_direct_sampling", dynlib: rtlsdr_lib.}
proc get_direct_sampling(dev: pdev_t): int {.cdecl, importc: "rtlsdr_get_direct_sampling", dynlib: rtlsdr_lib.}
proc set_offset_tuning(dev: pdev_t; on: int): int {.cdecl, importc: "rtlsdr_set_offset_tuning", dynlib: rtlsdr_lib.}
proc get_offset_tuning(dev: pdev_t): int {.cdecl, importc: "rtlsdr_get_offset_tuning", dynlib: rtlsdr_lib.}
proc reset_buffer(dev: pdev_t): int {.cdecl, importc: "rtlsdr_reset_buffer", dynlib: rtlsdr_lib.}
proc read_sync(dev: pdev_t; buf: pointer; len: int; n_read: ptr int): int {.cdecl, importc: "rtlsdr_read_sync", dynlib: rtlsdr_lib.}
proc read_async(dev: pdev_t; cb: read_async_cb_t; ctx: pointer; buf_num: uint32; buf_len: uint32): int {.cdecl, importc: "rtlsdr_read_async", dynlib: rtlsdr_lib.}
proc cancel_async(dev: pdev_t): int {.cdecl, importc: "rtlsdr_cancel_async", dynlib: rtlsdr_lib.}
