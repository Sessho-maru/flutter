import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

class MyPic extends StatelessWidget{
  final String src;
  const MyPic(this.src);

  @override
  Widget build(BuildContext context){
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(this.src),
          fit: BoxFit.fitWidth,
        ),
        border: Border.all(
          color: Colors.black26,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class MyGrid extends StatelessWidget{
  final List<String> urls;
  const MyGrid(this.urls);

  @override
  Widget build(BuildContext context){
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      mainAxisSpacing: 10,
      crossAxisSpacing: 20,
      crossAxisCount: 2,
      children: this.urls.map((each) {
        return Container(
          child: MyPic(each),
        );
      }).toList(),
    );
  }
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Future<String> fetchFileData() async{
    return await rootBundle.loadString('txt/urls.txt');
  }

  String raw = await fetchFileData();
  List<String> urls = raw.split("|");
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: MyGrid(urls)
        ),
      ),
    ),
  );
}
