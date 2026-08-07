# -*- mode: snippet -*-
# name: #include <stddefer.h>
# key: defer.h
# --
#if __has_include(<stddefer.h>) && !defined(__STDC_DEFER_TS25755__)
    #define __STDC_DEFER_TS25755__ 1
#endif
#if __STDC_DEFER_TS25755__ == 1
    #include <stddefer.h>
#endif$0