import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

class MyPicView extends StatelessWidget{
  final String src;
  final int index;
  const MyPicView(this.src, this.index);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: GestureDetector(
        onTap: () => {
          Navigator.pop(context)
        },
        child: Center(
          child: Hero(
            tag: this.index,
            child: Image.network(this.src),
          )
        )
      ),
    );
  }
}

class MyPic extends StatelessWidget{
  final String src;
  final int index;
  const MyPic(this.src, this.index);

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: () => {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MyPicView(this.src, this.index)))
      },
      child: Hero(
        tag: this.index,
        child: Container(
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
        ),
      ),
    );
  }
}

class MyGrid extends StatelessWidget{
  final List<String> urls;
  const MyGrid(this.urls);

  @override
  Widget build(BuildContext context){
    return SafeArea(
      child: GridView.count(
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
        mainAxisSpacing: 10,
        crossAxisSpacing: 20,
        crossAxisCount: 2,
        children: this.urls.asMap().entries.map((each) {
          return Container(
            child: MyPic(each.value, each.key),
          );
        }).toList(),
      ),
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