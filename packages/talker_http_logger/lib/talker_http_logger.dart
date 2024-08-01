library talker_http_logger;

import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:talker/talker.dart';

class TalkerHttpLogger extends InterceptorContract {
  static Map<String, Stopwatch> requestsTimes = {};

  TalkerHttpLogger({Talker? talker}) {
    _talker = talker ?? Talker();
  }

  late Talker _talker;

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    final message = '${request.url}';
    _talker.logTyped(HttpRequestLog(message, request: request));
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final message = '${response.request?.url}';
    _talker.logTyped(HttpResponseLog(message, response: response));
    return response;
  }
}

const encoder = JsonEncoder.withIndent('  ');
const decoder = JsonDecoder();

class HttpRequestLog extends TalkerLog {
  HttpRequestLog(
    String title, {
    required this.request,
  }) : super(title);

  final BaseRequest request;

  @override
  AnsiPen get pen => (AnsiPen()..xterm(219));

  @override
  String get key => TalkerLogType.httpRequest.key;

  @override
  String generateTextMessage(
      {TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    var id = '[${request.method}] $message ${request.hashCode}';
    var msg = '[$title] [${request.method}] $message';

    final headers = (request as Request).headers;
    final body = (request as Request).body.isNotEmpty ? decoder.convert((request as Request).body) : "";

    try {
      if (headers.isNotEmpty) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }

      if (body?.isNotEmpty ?? false) {
        final prettyBody = encoder.convert(body);
        msg += '\nBody: $prettyBody';
      }
    } catch (_) {
      // TODO: add handling can`t convert
    }
    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();
    TalkerHttpLogger.requestsTimes[id] = stopwatch;
    return msg;
  }
}

class HttpResponseLog extends TalkerLog {
  HttpResponseLog(
    String title, {
    required this.response,
  }) : super(title);

  final BaseResponse response;

  @override
  AnsiPen get pen => (AnsiPen()..xterm(46));

  @override
  String get title => TalkerLogType.httpResponse.key;

  @override
  String generateTextMessage(
      {TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    var id = '[${response.request?.method}] $message ${response.request?.hashCode}';
    var msg = '[$title] [${response.request?.method}] $message';

    final headers = (response as Response).headers;
    final body = (response as Response).body.isNotEmpty ? decoder.convert((response as Response).body) : "";

    msg += '\nStatus: ${response.statusCode}';
    msg += '\nDuration (ms): ${TalkerHttpLogger.requestsTimes[id]?.elapsedMilliseconds ?? 0}';
    TalkerHttpLogger.requestsTimes[id]?.stop();
    TalkerHttpLogger.requestsTimes.removeWhere((key, value) => key == id);

    try {
      if (headers?.isNotEmpty ?? false) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }

      if (body?.isNotEmpty ?? false) {
        final prettyBody = encoder.convert(body);
        msg += '\nBody: $prettyBody';
      }
    } catch (_) {
      // TODO: add handling can`t convert
    }
    return msg;
  }
}
