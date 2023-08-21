import 'dart:io';

import 'package:ping_win32/ping_win32.dart';

void main() async {
  final ping = await PingWin32.ping(
    InternetAddress.tryParse('192.168.10.12')!,
    timeout: Duration(seconds: 10),
  );
  print(ping);
}
