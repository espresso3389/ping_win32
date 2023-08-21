# ping_win32

A simple wrapper for Win32 [IcmpSendEcho2](https://learn.microsoft.com/en-us/windows/win32/api/icmpapi/nf-icmpapi-icmpsendecho2) function.

Although there has been a handful of ping implementations that wraps the command-line `ping` utility and it supports variety of platforms including Windows, on Windows platform, it does not support locales other than en-US and it results in severe incompatibility with other locales.

`ping_win32` is a faster, efficient, and better replacement for such `ping` implementations on Windows.

## Getting started

```
dart pub add ping_win32
```

## Usage

[PingWin32.ping](https://pub.dev/documentation/ping_win32/latest/ping_win32/PingWin32/ping.html) is the only one function provided by the library:

```dart
import 'dart:io';

import 'package:ping_win32/ping_win32.dart';

void main() async {
  final result = await PingWin32.ping(
    InternetAddress.tryParse('192.168.10.12')!,
    timeout: Duration(seconds: 10),
  );
  print(result);
}
```

The returned value is in [IcmpResult](https://pub.dev/documentation/ping_win32/latest/ping_win32/IcmpResult-class.html) class and it has [status](https://pub.dev/documentation/ping_win32/latest/ping_win32/IcmpResult/status.html), [roundTripTime](https://pub.dev/documentation/ping_win32/latest/ping_win32/IcmpResult/roundTripTime.html), and [ttl](https://pub.dev/documentation/ping_win32/latest/ping_win32/IcmpResult/ttl.html).

# References

- [ping_win32 - pub.dev](https://pub.dev/packages/ping_win32)
- [IcmpSendEcho2 function](https://learn.microsoft.com/en-us/windows/win32/api/icmpapi/nf-icmpapi-icmpsendecho2)
