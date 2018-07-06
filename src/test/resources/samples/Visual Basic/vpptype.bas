' -------------------------------------------------------------------------
'  Distributed by VXIplug&play Systems Alliance
'  Do not modify the contents of this file.
' -------------------------------------------------------------------------
'  Title   : VPPTYPE.BAS
'  Date    : 02-14-95
'  Purpose : VXIplug&play instrument driver header file
' -------------------------------------------------------------------------

Global Const VI_NULL                             = 0
Global Const VI_TRUE                             = 1
Global Const VI_FALSE                            = 0

' - Completion and Error Codes --------------------------------------------

Global Const VI_WARN_NSUP_ID_QUERY               = &H3FFC0101&
Global Const VI_WARN_NSUP_RESET                  = &H3FFC0102&
Global Const VI_WARN_NSUP_SELF_TEST              = &H3FFC0103&
Global Const VI_WARN_NSUP_ERROR_QUERY            = &H3FFC0104&
Global Const VI_WARN_NSUP_REV_QUERY              = &H3FFC0105&

Global Const VI_ERROR_PARAMETER1                 = &HBFFC0001&
Global Const VI_ERROR_PARAMETER2                 = &HBFFC0002&
Global Const VI_ERROR_PARAMETER3                 = &HBFFC0003&
Global Const VI_ERROR_PARAMETER4                 = &HBFFC0004&
Global Const VI_ERROR_PARAMETER5                 = &HBFFC0005&
Global Const VI_ERROR_PARAMETER6                 = &HBFFC0006&
Global Const VI_ERROR_PARAMETER7                 = &HBFFC0007&
Global Const VI_ERROR_PARAMETER8                 = &HBFFC0008&
Global Const VI_ERROR_FAIL_ID_QUERY              = &HBFFC0011&
Global Const VI_ERROR_INV_RESPONSE               = &HBFFC0012&

' - Additional Definitions ------------------------------------------------

Global Const VI_ON                               = 1
Global Const VI_OFF                              = 0
