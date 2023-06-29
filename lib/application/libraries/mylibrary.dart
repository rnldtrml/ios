import 'dart:convert'; 
import 'package:in_out_ios/application/config/constants.dart'; 
import 'package:crypto/crypto.dart';
class MyLibrary
{
    String hmacSha256(data)
    {
      var key = utf8.encode(APP_KEY);
      var bytes = utf8.encode(data);

      var hmacSha256 = Hmac(sha256, key);
      var digest = hmacSha256.convert(bytes);

      return digest.toString();
    }
   
}