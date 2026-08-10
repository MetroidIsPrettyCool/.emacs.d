# -*- mode: snippet -*-
# name: #include <stddefer.h>
# key: defer.h
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# --
#if __has_include(<stddefer.h>) && !defined(__STDC_DEFER_TS25755__)
    #define __STDC_DEFER_TS25755__ 1
#endif
#if __STDC_DEFER_TS25755__ == 1
    #include <stddefer.h>
#endif$0