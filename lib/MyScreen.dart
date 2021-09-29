import 'package:flutter/material.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:web_scraper/web_scraper.dart';
import 'dart:math';

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

// ignore: must_be_immutable
class MyPic extends StatelessWidget{
  String? thumbnailUrl;
  String? jpgUrl;
  final int index;
  MyPic(this.thumbnailUrl, this.jpgUrl, this.index);

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: () => {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MyPicView(this.jpgUrl as String, this.index)))
      },
      child: Hero(
        tag: this.index,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(this.thumbnailUrl as String),
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

// ignore: must_be_immutable
class MyGrid extends StatefulWidget{
  List<Map<String, String>> origin = <Map<String, String>>[];
  List<Map<String, String>> displayed = <Map<String, String>>[];

  MyGrid(List<Map<String, String>> thumbJpgUrlPair) {
    this.origin = this.displayed = thumbJpgUrlPair;
  }

  @override
  MyGridState createState() => MyGridState();
}

class MyGridState extends State<MyGrid> {
  void shuffle() {
    int size = widget.origin.length;
    List<bool> visited = List<bool>.filled(size, false);
    List<Map<String, String>> shuffled = <Map<String, String>>[];

    Random randomObj = Random();
    while(shuffled.length < size) {
      int index = randomObj.nextInt(size);
      if(visited[index] == false) {
        shuffled.add(widget.origin[index]);
        visited[index] = true;
      }
    }

    setState(() {
      widget.displayed = shuffled;
    });
  }

  void reverse() {
    setState(() {
      widget.displayed = List.from(widget.displayed.reversed);
    });
  }

  void reset() {
    setState(() {
      widget.displayed = widget.origin;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: <Widget>[
            Expanded(
            flex: 30,
            child: GridView.count(
                shrinkWrap: true,
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
                mainAxisSpacing: 10,
                crossAxisSpacing: 20,
                crossAxisCount: 2,
                children: widget.displayed.asMap().entries.map((each) {
                  return Container(
                      child: MyPic(each.value['thumbnail'], each.value['jpgSrc'], each.key),
                  );
                }).toList()
            ),
          )
          ]
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: Container(
        height: 39.0,
        width: 39.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () => Dialogs.bottomMaterialDialog(
                msg: 'You can Shuffle or Reverse images',
                title: "Re-Order",
                color: Colors.orangeAccent,
                context: context,
                actions: [
                  IconsButton(
                    onPressed: () => {this.shuffle()},
                    text: "Shuffle",
                    iconData: Icons.shuffle,
                    color: Colors.blueAccent,
                    textStyle: TextStyle(color: Colors.white),
                    iconColor: Colors.white,
                  ),
                  IconsButton(
                    onPressed: () => {this.reverse()},
                    text: "Reverse",
                    iconData: Icons.arrow_back_outlined,
                    color: Colors.blueAccent,
                    textStyle: TextStyle(color: Colors.white),
                    iconColor: Colors.white,
                  ),
                  IconsButton(
                    onPressed: () => {this.reset()},
                    text: "Reset",
                    color: Colors.red,
                    textStyle: TextStyle(color: Colors.white),
                    iconColor: Colors.white,
                  ),
                ]
            ),
            child: Icon(Icons.arrow_upward_rounded),
            backgroundColor: Colors.lightBlue
          ),
        ),
      ),
    );
  }
}

// editing ...
class Scraper extends StatefulWidget {
  @override
  _ScraperState createState() => _ScraperState();
}

class _ScraperState extends State<Scraper> {
  final webScraper = WebScraper('https://safebooru.org/');
  final int imgPerPage = 40;

  String keyword = 'azumanga_daiou';
  List<Map<String, dynamic>> hrefPairs = [];
  List<Map<String, dynamic>> thumbPairs = [];
  List<String> hrefs = [];
  List<String> thumbs = [];
  List<Map<String, dynamic>> jpgPairs = [];
  List<Map<String, String>> thumbJpgUrlPair = [];

  void fetchThumbnailJpgPair(String? keyword) async {
    if (await webScraper.loadWebPage('index.php?page=post&s=list&tags=$keyword')) {
        hrefPairs = webScraper.getElement('span.thumb > a', ['href']);
        thumbPairs = webScraper.getElement('span.thumb > a > img', ['src']);

        for (int i = 0; i < imgPerPage; i++) {
          hrefs.add(hrefPairs[i]['attributes']['href']);
          thumbs.add(thumbPairs[i]['attributes']['src']);
        }
    }

    for (int i = 0; i < imgPerPage; i++) {
      if (await webScraper.loadWebPage(hrefs[i])) {
        jpgPairs = webScraper.getElement('div.content > div > img', ['src']);
        thumbJpgUrlPair.add({
          'thumbnail' : thumbs[i],
          'jpgSrc' : jpgPairs[0]['attributes']['src']
        });
      }
    }

    setState((){
      this.keyword = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            onChanged: (text){
              this.keyword = text;
            },
            decoration: const InputDecoration(
              hintText: '  Safebooru',
              enabledBorder: UnderlineInputBorder(      
                borderSide: BorderSide(color: Colors.white, width: 2.0),
              ),  
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange, width: 2.0),
              ),
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () => { this.fetchThumbnailJpgPair(this.keyword) },
                child: Icon(Icons.search, size: 26.0)
              ),
            )
          ],
          actionsIconTheme: IconThemeData(
            size: 30.0,
            color: Colors.white,
            opacity: 10.0
          ),
        ),
        body: Center(
          child: MyGrid( this.thumbJpgUrlPair )
        )
      )
    );
  }
}

void main() {
  runApp(
    Scraper()
  );
}