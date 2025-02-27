import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jan_dhan_darshak/services/models.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SearchPage extends StatefulWidget {
  final List<Ftp> ftps;
  final searchCancelCallBack;
  final Function(double, double, String) placeClick;
  final bool isText;

  const SearchPage(
      {Key key,
      this.ftps,
      this.searchCancelCallBack,
      this.placeClick,
      this.isText})
      : super(key: key);
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController textEditingController = TextEditingController();
  List<Ftp> searchresults = [];
  bool _hasSpeech = false;
  bool _listening;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = "Listening...";
  String lastError = "";
  String lastStatus = "";
  final SpeechToText speech = SpeechToText();
  FlutterTts flutterTts;

  void _searchPlace(String searchText) {
    setState(() {
      searchresults.clear();
    });
    widget.ftps.forEach((ftp) {
      if (ftp.name.toLowerCase().contains(searchText.toLowerCase()) ||
          ftp.address.toLowerCase().contains(searchText.toLowerCase()) ||
          ftp.extra.toLowerCase().contains(searchText.toLowerCase())) {
        setState(() {
          searchresults.add(ftp);
        });
      }
    });
    if (_listening && searchresults.isNotEmpty) {
      Ftp ftp = searchresults[0];
      String distance = _getDist(ftp.distance);
      String string =
          'Nearest place is ' + ftp.name + ' which is ' + distance + ' away.';
      _speak(string);
    }
  }

  String _getDist(distance) {
    String string = '';
    if (distance < 1000) {
      string = '$distance meter';
    } else {
      var dist = (distance / 1000).toStringAsFixed(1);
      string = '$dist kilometer';
    }
    return string;
  }

  String _getDistance(distance) {
    String string = '';
    if (distance < 1000) {
      string = '($distance m)';
    } else {
      var dist = (distance / 1000).toStringAsFixed(1);
      string = '($dist km)';
    }
    return string;
  }

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (!mounted) return;
    setState(() {
      _hasSpeech = hasSpeech;
    });
    if (_hasSpeech) startListening();
  }

  Future _speak(String text) async {
    if (text.isNotEmpty && text != null) {
      var result = await flutterTts.speak(text);
      print(result);
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _listening = !widget.isText;
      widget.ftps.sort((a, b) => a.distance.compareTo(b.distance));
    });
    flutterTts = FlutterTts();
    flutterTts.setVolume(1.0);
    if (_listening) initSpeechState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
          onPressed: widget.searchCancelCallBack,
        ),
        title: _listening
            ? Text(
                lastWords,
                style: TextStyle(color: Colors.grey[700]),
              )
            : TextField(
                autofocus: widget.isText,
                cursorColor: Colors.grey[800],
                decoration: new InputDecoration(
                  border: InputBorder.none,
                  hintText: EasyLocalization.of(context)
                      .delegate
                      .translations
                      .get('search_here'),
                  contentPadding: EdgeInsets.all(5),
                ),
                controller: textEditingController,
                onChanged: _searchPlace,
              ),
        actions: <Widget>[
          textEditingController.text.isEmpty
              ? Container()
              : IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[700]),
                  onPressed: () {
                    setState(() {
                      textEditingController.clear();
                      searchresults.clear();
                    });
                  },
                ),
          _listening
              ? IconButton(
                  icon: Icon(Icons.mic_off, color: Colors.red),
                  onPressed: () {
                    stopListening();
                  },
                )
              : IconButton(
                  icon: Icon(Icons.mic, color: Colors.grey[700]),
                  onPressed: () {
                    initSpeechState();
                  },
                ),
        ],
      ),
      body: searchresults.length == 0
          ? ListView.separated(
              itemCount: widget.ftps.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () => widget.placeClick(
                      widget.ftps.elementAt(index).latitude,
                      widget.ftps.elementAt(index).longitude,
                      widget.ftps.elementAt(index).ftpId),
                  title: Text(widget.ftps.elementAt(index).name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          _getDistance(
                              widget.ftps.elementAt(index).distance.floor()),
                          style: TextStyle(color: Colors.green)),
                      SizedBox(height: 5),
                      Text(widget.ftps.elementAt(index).address),
                      SizedBox(height: 5),
                      Text(widget.ftps.elementAt(index).extra),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return Divider();
              },
            )
          : ListView.separated(
              itemCount: searchresults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () => widget.placeClick(
                      searchresults.elementAt(index).latitude,
                      searchresults.elementAt(index).longitude,
                      searchresults.elementAt(index).ftpId),
                  title: Text(searchresults.elementAt(index).name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          _getDistance(
                              searchresults.elementAt(index).distance.floor()),
                          style: TextStyle(color: Colors.green)),
                      SizedBox(height: 5),
                      Text(searchresults.elementAt(index).address),
                      SizedBox(height: 5),
                      Text(searchresults.elementAt(index).extra),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return Divider();
              },
            ),
    );
  }

  void startListening() {
    setState(() {
      _listening = true;
      lastWords = "Listening...";
      lastError = "";
    });
    speech
        .listen(
      onResult: resultListener,
      listenFor: Duration(seconds: 10),
      pauseFor: Duration(seconds: 5),
      localeId: 'en',
      onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      partialResults: true,
      //onDevice: true,
      listenMode: ListenMode.search,
    )
        .then((value) {
      resultListener(value);
    });
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
      _listening = false;
    });
  }

  void cancelListening() {
    speech.cancel();
    setState(() {
      level = 0.0;
      _listening = false;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      setState(() {
        lastWords = result.recognizedWords;
      });
      _searchPlace(lastWords);
    }
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    print("sound level $level: $minSoundLevel - $maxSoundLevel ");
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    print("Received error status: $error, listening: ${speech.isListening}");
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
      level = 0.0;
      _listening = false;
    });
  }

  void statusListener(String status) {
    print(
        "Received listener status: $status, listening: ${speech.isListening}");
    setState(() {
      lastStatus = "$status";
    });
  }
}
