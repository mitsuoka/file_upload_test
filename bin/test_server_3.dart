/*
  Dart code sample : Simple tool for HTTP file upload server development
  Returns body contents of the HTTP request to the client.
  This server utilizes mime_multipart_transformer and HttpMultipartFormData.parse,
   and reports MIME multipart body data as List of FormField objects.
    1. Run this server.
    2. Open the file_upload_test.html file from your browser such as :
       file:///C:/ … /file_upload_servers/resouces/file_upload_test.html
       You can get the file path of this HTML file by right clicking the file
       on the Dart editor.
    3. Enter your name and select a file to upload (e.g. test_file.txt) and
       click the Send File button.
    4. This server will return available header abd body data from the request.
  October 2013, by Terry Mitsuoka
*/

import "dart:async";
import "dart:io";
import "package:http_server/http_server.dart";
import "package:mime/mime.dart";
//import "dart:convert";
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
  if (request.method == "GET") {
    sendResponse(request, null);
    }

  else if (request.method == "POST"
      && request.headers.contentType.parameters['boundary'] != null) {
    String boundary = request.headers.contentType.parameters['boundary'];
    request
    .transform(new MimeMultipartTransformer(boundary))
      .map(HttpMultipartFormData.parse)
        .map((multipart) {
          var future;
          if (multipart.isText) {
            future = multipart
                .fold(new StringBuffer(), (b, s) => b..write(s))
                  .then((b) => b.toString());
            } else {
              future = multipart
                  .fold([], (b, s) => b..addAll(s));
            }
            return future
                .then((data) {
                  String contentType;
                  if (multipart.contentType != null) {
                    contentType = multipart.contentType.mimeType;
                  }
                  return new FormField(
                      multipart.contentDisposition.parameters['name'],
                      data,
                      contentType: contentType,
                      filename:
                          multipart.contentDisposition.parameters['filename']);
                });
          })
          .fold([], (l, f) => l..add(f))
          .then(Future.wait)
          .then((formFields){
            sendResponse(request, formFields);
          }
        );
      ;
    }

  else {
    response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
    response.close();
    return;
    }
}

// process the request and send a response
sendResponse(HttpRequest request, List<FormField> formFields){
  if (LOG_REQUESTS) {
    print(createLogMessage(request, formFields));
  }
  request.response..headers.add("Content-Type", "text/html; charset=UTF-8")
                  ..write(createHtmlResponse(request, formFields))
                  ..close();
}

// FormField represents each part of the MIME multipart
class FormField {
  final String name;
  final value;
  final String contentType;
  final String filename;
  FormField(String this.name,
            this.value,
            {String this.contentType,
             String this.filename});
  String toString() {
    return "FormField('$name', '$value', '$contentType', '$filename')";
  }
}


// create html response text
String createHtmlResponse(HttpRequest request, List<FormField> formFields) {
  var res = '''<html>
  <head>
    <title>DumpHttpRequest</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  </head>
  <body>
    <H1>Data available from the request</H1>
    <pre>${makeSafe(createLogMessage(request, formFields)).toString()}
    </pre>
  </body>
</html>
''';
  return res;
}

// create log message
StringBuffer createLogMessage(HttpRequest request, [List<FormField> formFields]) {
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
  if (formFields != null) {
     sb.write("\nMIME multipart body data\n number of parts : ${formFields.length}");
     for (int i = 0; i < formFields.length; i++) {
       sb.write("\n part$i : ${formFields[i].toString()}");
     }


//     sb.write("\n file name length : ${formFields[1].filename.length}");
//     sb.write("\n file name : ${formFields[1].filename}");

  }
  sb.write("\n");
  return sb;
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