/*
  Dart code sample : Simple tool for HTTP file upload server development
  Returns contents of the HTTP request to the client.
  This server reports MIME multipart body byta data as ASCII text and hexdump.
    1. Run this server.
    2. Open the file_upload_test.html file from your browser such as :
       file:///C:/ … /file_upload_servers/resouces/file_upload_test.html
       You can get the file path of the file by right clicking the file on the Dart editor.
    3. Enter your name and select a file to upload and click the Send File button.
    4. This server will return available header and body data from the request.
  September 2013, by Terry Mitsuoka
*/

import "dart:async";
import "dart:io";
import "dart:convert";
//import "dart:utf";

final HOST = "127.0.0.1";
final PORT = 8080;
final REQUEST_PATH = "/DumpHttpMultipart";
final LOG_REQUESTS = false;

void main() {
  HttpServer.bind(HOST, PORT)
  .then((HttpServer server) {
    server.listen(
        (HttpRequest request) {
          request.response.done.then((d){
              print("sent response to the client for request : ${request.uri}");
            }).catchError((e) {
              print("Error occured while sending response: $e");
            });
          if (request.uri.path == REQUEST_PATH) {
            requestReceivedHandler(request);
          }
          else request.response.close();
        });
    print("${new DateTime.now()} : Serving $REQUEST_PATH on http://${HOST}:${PORT}.\n");
  });
}

void requestReceivedHandler(HttpRequest request) {
  HttpResponse response = request.response;
  List<int> bodyBytes = [];    // request body byte data
  var completer = new Completer();
  if (request.method == "GET") { completer.complete("query string data received");
  } else if (request.method == "POST") {
    request
      .listen(
          (bytes){bodyBytes.addAll(bytes);},
          onDone: (){
            completer.complete("body data received");},
          onError: (e){
            print('exeption occured : ${e.toString()}');}
        );
  }
  else {
    response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
    response.close();
    return;
  }
  // process the request and send a response
  completer.future.then((data){
    if (LOG_REQUESTS) {
      print(createLogMessage(request));
    }
    response.headers.add("Content-Type", "text/html; charset=UTF-8");
    response.write(createHtmlResponse(request, bodyBytes));
    response.close();
  });
}

// create html response text
String createHtmlResponse(HttpRequest request, List<int> bodyBytes) {
  var res = '''<html>
  <head>
    <title>DumpHttpRequest</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  </head>
  <body>
    <H1>Data available from the request</H1>
    <pre>${makeSafe(createLogMessage(request, bodyBytes)).toString()}
    </pre>
  </body>
</html>
''';
  return res;
}

// create log message
StringBuffer createLogMessage(HttpRequest request, [List<int> bodyBytes]) {
  var sb = new StringBuffer( '''request.headers.host : ${request.headers.host}
request.headers.port : ${request.headers.port}
request.connectionInfo.localPort : ${request.connectionInfo.localPort}
request.connectionInfo.remoteHost : ${request.connectionInfo.remoteHost}
request.connectionInfo.remotePort : ${request.connectionInfo.remotePort}
request.method : ${request.method}
request.persistentConnection : ${request.persistentConnection}
request.protocolVersion : ${request.protocolVersion}
request.contentLength : ${request.contentLength}
request.uri : ${request.uri}
request.uri.scheme : ${request.uri.scheme}
request.uri.path : ${request.uri.path}
request.uri.query : ${request.uri.query}
request.uri.queryParameters :
''');
  request.uri.queryParameters.forEach((key, value){
    sb.write("  ${key} : ${value}\n");
  });
  sb.write('''request.cookies :
''');
  request.cookies.forEach((value){
    sb.write("  ${value.toString()}\n");
  });
  sb.write('''request.headers.expires : ${request.headers.expires}
request.headers :
  ''');
  var str = request.headers.toString();
  for (int i = 0; i < str.length - 1; i++){
    if (str[i] == "\n") { sb.write("\n  ");
    } else { sb.write(str[i]);
    }
  }
  sb.write('''\nrequest.session.id : ${request.session.id}
requset.session.isNew : ${request.session.isNew}
''');
  if (request.method == "POST") {
     sb.write("\nbody byte data\n size : ${bodyBytes.length}\n data as ASCII:\n");
     for (int i = 0; i < bodyBytes.length; i++) {
       sb.write(new String.fromCharCode(bodyBytes[i]));
      }
     sb.write("\n data as UTF-8:\n${new Utf8Decoder().convert(bodyBytes)}");
     new HexDump().hexDump(sb, bodyBytes);
  }
  sb.write("\n");
  return sb;
}

// Hex dump List<int> data
class HexDump {

  StringBuffer hexDump(StringBuffer sb, List<int> data) {
    sb.write("\n hexa dump:");
    int lines = data.length ~/ 32;
    int lastLineBytes = data.length % 32;
    for (int l = 0; l < lines; l++) {
      dumpLine(sb, data, l, 32);
    }
    if (lastLineBytes != 0) dumpLine(sb, data, lines, lastLineBytes);
    return sb;
  }

  StringBuffer dumpLine(StringBuffer sb, List<int> data, int line, int col) {
    sb.write('\n');
    for (int c = 0; c < col; c++){
      int byte = data[line * 32 + c];
      int n = byte ~/ 16;
      if (n > 9) n = n + 7;
      sb.write(' ' + new String.fromCharCode(n + 48));
      n = byte & 15;
      if (n > 9) n = n + 7;
      sb.write(new String.fromCharCode(n + 48));
    }
    sb.write(' ');
    for (int c = 0; c < col; c++){
      int byte = data[line * 32 + c];
      if (byte < 32) byte = 46;
      if (byte >126) byte = 46;
      sb.write(new String.fromCharCode(byte));
    }
  }
}

// make safe string buffer data as HTML text
StringBuffer makeSafe(StringBuffer b) {
  var s = b.toString();
  b = new StringBuffer();
  for (int i = 0; i < s.length; i++){
    if (s[i] == '&') { b.write('&amp;');
    } else if (s[i] == '"') { b.write('&quot;');
    } else if (s[i] == "'") { b.write('&#x27;');
    } else if (s[i] == '<') { b.write('&lt;');
    } else if (s[i] == '>') { b.write('&gt;');
    } else if (s[i] == '/') { b.write('&#x2F;');
    } else { b.write(s[i]);
    }
  }
  return b;
}