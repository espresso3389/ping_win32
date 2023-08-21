// ignore_for_file: public_member_api_docs, sort_static constructors_first
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';

typedef _IcmpCreateFileC = IntPtr Function();
typedef _IcmpCreateFileDart = int Function();

typedef _IcmpCloseHandleC = Int32 Function(IntPtr);
typedef _IcmpCloseHandleDart = int Function(int);

typedef _IcmpSendEcho2C = Uint32 Function(
  IntPtr icmpHandle,
  IntPtr event,
  IntPtr apcRoutine,
  IntPtr apcContext,
  Uint32 destinationAddress,
  Pointer requestData,
  Uint16 requestSize,
  IntPtr requestOptions,
  Pointer replyBuffer,
  Uint32 replySize,
  Uint32 timeout,
);

typedef _IcmpSendEcho2Dart = int Function(
  int icmpHandle,
  int event,
  int apcRoutine,
  int apcContext,
  int destinationAddress,
  Pointer requestData,
  int requestSize,
  int requestOptions,
  Pointer replyBuffer,
  int replySize,
  int timeout,
);

typedef _WaitForSingleObjectC = Uint32 Function(
    IntPtr hHandle, Uint32 dwMilliseconds);

typedef _WaitForSingleObjectDart = int Function(
    int hHandle, int dwMilliseconds);

typedef _CloseHandleC = Void Function(IntPtr hHandle);
typedef _CloseHandleDart = void Function(int hHandle);

typedef _CreateEventC = IntPtr Function(IntPtr lpEventAttributes,
    Uint32 bManualReset, Uint32 bInitialState, IntPtr lpName);
typedef _CreateEventDart = int Function(
    int lpEventAttributes, int bManualReset, int bInitialState, int lpName);

typedef _GetLastErrorC = Uint32 Function();
typedef _GetLastErrorDart = int Function();

final class _ICMP_ECHO_REPLY extends Struct {
  @Int32()
  external int address;
  @Int32()
  external int status;
  @Int32()
  external int roundTripTime;
  @Int16()
  external int dataSize;
  @Int16()
  external int reserved;
  @IntPtr()
  external int data;

  // ip_options_information
  @Uint8()
  external int ttl;
  @Uint8()
  external int tos;
  @Uint8()
  external int flags;
  @Uint8()
  external int optionsSize;
  @IntPtr()
  external int optionsData;
}

abstract class _Kernel32 {
  static final DynamicLibrary kernel = DynamicLibrary.open('kernel32.dll');

  static final createEvent =
      kernel.lookupFunction<_CreateEventC, _CreateEventDart>('CreateEventW');

  static final closeHandle =
      kernel.lookupFunction<_CloseHandleC, _CloseHandleDart>('CloseHandle');

  static final waitForSingleObject =
      kernel.lookupFunction<_WaitForSingleObjectC, _WaitForSingleObjectDart>(
          'WaitForSingleObject');

  static final getLastError =
      kernel.lookupFunction<_GetLastErrorC, _GetLastErrorDart>('GetLastError');
}

abstract class _IcmpApi {
  static final DynamicLibrary icmp = DynamicLibrary.open('iphlpapi.dll');

  static final icmpOpenFile = icmp
      .lookupFunction<_IcmpCreateFileC, _IcmpCreateFileDart>('IcmpCreateFile');

  static final icmpCloseHandle =
      icmp.lookupFunction<_IcmpCloseHandleC, _IcmpCloseHandleDart>(
          'IcmpCloseHandle');

  static final icmpSendEcho2 =
      icmp.lookupFunction<_IcmpSendEcho2C, _IcmpSendEcho2Dart>('IcmpSendEcho2');
}

class _PingConfig {
  final int address;
  final int duration;
  final int sizeToSend;
  final int replyBufferSize;
  const _PingConfig(
      this.address, this.duration, this.sizeToSend, this.replyBufferSize);
}

sealed class PingWin32 {
  static Future<IcmpResult?> ping(
    InternetAddress ipv4Address, {
    Duration timeout = const Duration(seconds: 1),
    int sizeToSend = 32,
    int replyBufferSize = 1024,
  }) async {
    if (ipv4Address.type != InternetAddressType.IPv4) {
      throw Exception('Only IPv4 address is supported');
    }
    final ipv4 = ipv4Address.rawAddress;
    final ipv4int =
        (ipv4[3] << 24) | (ipv4[2] << 16) | (ipv4[1] << 8) | ipv4[0];

    final hEvent = _Kernel32.createEvent(0, 1, 0, 0);
    final toSend = calloc<Uint8>(sizeToSend);
    final replyBuffer = calloc<_ICMP_ECHO_REPLY>(replyBufferSize);
    final icmp = _IcmpApi.icmpOpenFile();
    const WAIT_TIMEOUT = 0x102;
    const ERROR_IO_PENDING = 997;

    try {
      final result = _IcmpApi.icmpSendEcho2(
        icmp,
        hEvent,
        0,
        0,
        ipv4int,
        toSend,
        sizeToSend,
        0,
        replyBuffer,
        replyBufferSize,
        timeout.inMilliseconds,
      );
      if (result != 0) return null;
      // final error = _Kernel32.getLastError();
      // if (error != ERROR_IO_PENDING) return null;

      for (;;) {
        final result = _Kernel32.waitForSingleObject(hEvent, 0);
        if (result == 0) {
          final result = replyBuffer.ref;
          return IcmpResult(
              status: result.status,
              roundTripTime: Duration(milliseconds: result.roundTripTime),
              ttl: result.ttl);
        } else if (result != WAIT_TIMEOUT) {
          return null;
        }
        await Future.delayed(
            Duration(milliseconds: min(100, timeout.inMilliseconds)));
      }
    } finally {
      _IcmpApi.icmpCloseHandle(icmp);
      calloc.free(toSend);
      calloc.free(replyBuffer);
      _Kernel32.closeHandle(hEvent);
    }
  }
}

class IcmpResult {
  /// 0=success, 11010=timeout, ... For more info, use [statusString].
  final int status;

  /// Round-trip time.
  final Duration roundTripTime;
  // TTL
  final int ttl;
  IcmpResult({
    required this.status,
    required this.roundTripTime,
    required this.ttl,
  });

  String? get statusString => _status2String[status];

  @override
  String toString() =>
      'IcmpResult(status: $statusString($status), roundTripTime: $roundTripTime, ttl: $ttl)';

  @override
  bool operator ==(covariant IcmpResult other) {
    if (identical(this, other)) return true;

    return other.status == status &&
        other.roundTripTime == roundTripTime &&
        other.ttl == ttl;
  }

  @override
  int get hashCode => status.hashCode ^ roundTripTime.hashCode ^ ttl.hashCode;
}

final _status2String =
    Map.fromEntries(_icmpStatus.map((e) => MapEntry(e.value, e.name)));

class _IcmpStatus {
  final String name;
  final int value;
  const _IcmpStatus(this.name, this.value);
}

const _icmpStatus = [
  _IcmpStatus("IP_SUCCESS", 0), // The status was success.
  _IcmpStatus("IP_BUF_TOO_SMALL", 11001), // The reply buffer was too small.
  _IcmpStatus("IP_DEST_NET_UNREACHABLE",
      11002), // The destination network was unreachable.
  _IcmpStatus("IP_DEST_HOST_UNREACHABLE",
      11003), // The destination host was unreachable.
  _IcmpStatus("IP_DEST_PROT_UNREACHABLE",
      11004), // The destination protocol was unreachable.
  _IcmpStatus("IP_DEST_PORT_UNREACHABLE",
      11005), // The destination port was unreachable.
  _IcmpStatus(
      "IP_NO_RESOURCES", 11006), // Insufficient IP resources were available.
  _IcmpStatus("IP_BAD_OPTION", 11007), // A bad IP option was specified.
  _IcmpStatus("IP_HW_ERROR", 11008), // A hardware error occurred.
  _IcmpStatus("IP_PACKET_TOO_BIG", 11009), // The packet was too big.
  _IcmpStatus("IP_REQ_TIMED_OUT", 11010), // The request timed out.
  _IcmpStatus("IP_BAD_REQ", 11011), // A bad request.
  _IcmpStatus("IP_BAD_ROUTE", 11012), // A bad route.
  _IcmpStatus("IP_TTL_EXPIRED_TRANSIT",
      11013), // The time to live (TTL) expired in transit.
  _IcmpStatus("IP_TTL_EXPIRED_REASSEM",
      11014), // The time to live expired during fragment reassembly.
  _IcmpStatus("IP_PARAM_PROBLEM", 11015), // A parameter problem.
  _IcmpStatus("IP_SOURCE_QUENCH",
      11016), // Datagrams are arriving too fast to be processed and datagrams may have been discarded.
  _IcmpStatus("IP_OPTION_TOO_BIG", 11017), // An IP option was too big.
  _IcmpStatus("IP_BAD_DESTINATION", 11018), // A bad destination.
  _IcmpStatus("IP_GENERAL_FAILURE",
      11050), // A general failure. This error can be returned for some malformed ICMP packets.
];
