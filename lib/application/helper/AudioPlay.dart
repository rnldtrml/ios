
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
// import 'package:audioplayers/audio_cache.dart';

class AudioPlay
{

  AudioPlayer audioPlugin = AudioPlayer();
  String? uri;
  
  Future<void> load(String fullpath,String file) async
  {
    final ByteData data = await rootBundle.load(fullpath);
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/'+file);
    await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    uri = tempFile.uri.toString();
  }

  
 void play({bool isLocal = false}) async
  {
    if (uri != null)
    {
      await audioPlugin.play(uri as Source);
    }
  }

 Future<void> playLocalAsset() async
 {
  //  AudioCache cache = AudioCache();
   final player = AudioPlayer();
  //  return await cache.play("myCustomSoundEffect.mp3");
   await player.play(UrlSource('myCustomSoundEffect.mp3'));
  //  AudioPlayer player = await cache.play("myCustomSoundEffect.mp3");
 }


 
}