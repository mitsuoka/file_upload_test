file\_upload\_test (under construction)
==

**file\_upload\_test** is a set of file upload test servers for development of
server applicationｓ utilizing Dart [http\_server](https://pub.dartlang.org/packages/http_server)
pub package.

This repository consists of following server codes.

- **bin/test\_server\_1.dart** : Returns contents of the HTTP request to the client.
  This server reports MIME multipart body byte data as ASCII text, UTF-8 text and hexdump.
 You can confirm what actual HTTP request the client sent to the server.

- **bin/test\_server\_2.dart** : Returns contents of the HTTP request to the client.
 This server utilizes **HttpBodyHandler** of the http\_server package and
   reports body data based on the content type header parameter. This code refers
 to[ "http\_body\_test.dart"]
(https://code.google.com/p/dart/codesearch#dart/trunk/dart/pkg/http_server/test/http_body_test.dart&sq=package:dart)
 written by Dart team.

- **bin/test\_server\_3.dart** : Returns contents of the HTTP request to the client.
 This server utilizes **mime\_multipart\_transformer** and
 **HttpMultipartFormData.parse** static method,
   and reports MIME multipart body data as a List of **FormField** objects. This code refers
 to[ "http\_multipart\_test.dart]
(https://code.google.com/p/dart/codesearch#dart/trunk/dart/pkg/http_server/test/http_multipart_test.dart&sq=package:dart)
 written by Dart team.

Following files are also included:

- **resources/file\_upload\_test.html** : HTML file to send a HTML MIME multipart request to one of above servers.
You can type "your\_name" in the name field, and selects a
   file (e.g. "test\_file.txt") for the answer to 'What files are you sending?'.  Click "Send File" button
 to send a MIME multipart request including selected file.

- **resources/get\_post\_query\_test.html** : HTML file to send a form data using GET / POST method. This file
is used to test how those above servers can handle GET and POST query.
 You can send a text including multi-byte characters like Kanji as text/plain or application/x-www-form-urlencoded encoding.


- **resources/test\_file.txt** : Short test text file to upload.

このサンプルは[「プログラミング言語Dartの基礎」]
(http://www.cresc.co.jp/tech/java/Google_Dart/DartLanguageGuide_about.html)の
添付資料です。詳細は「ファイル・アップロード (File Upload Servers)」の章をご覧ください。

### Installing ###

1. Download this repository, uncompress and rename the folder to **file\_upload\_test**.
2. From Dart Editor, File > Open Existion Folder and select this  **file\_upload\_test** folder.

### Try it ###

1. Run one of above servers.
2. Access **file\_upload\_test.html** or **get\_post\_query\_test.html** from your browser.
3. Click submit button to send HTTP request to  the server.


### License ###
This sample is licensed under [MIT License][MIT].
[MIT]: http://www.opensource.org/licenses/mit-license.php