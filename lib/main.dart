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
class MyPic extends StatefulWidget{
  String? thumbnailUrl;
  String? hrefUrl;
  String? jpgSrc = '';
  final int index;
  bool isLoading = false;
  MyPic(this.thumbnailUrl, this.hrefUrl, this.index);
  
  @override
  _MyPicState createState() => _MyPicState();
}

class _MyPicState extends State<MyPic> {
  final webScraper = WebScraper('https://safebooru.org/');

  Future<String?> fetchJpgSrc() async {
    if (await webScraper.loadWebPage(widget.hrefUrl as String)) {
      List<Map<String, dynamic>> jpgMap = webScraper.getElement('div.content > div > img', ['src']);
      return jpgMap[0]['attributes']['src'];
    }  
  }

  void fetchJpgThenNaviPush() {
    setState((){
      widget.isLoading = true;
    });

    this.fetchJpgSrc().then((jpgSrc) => { 
      widget.jpgSrc = jpgSrc,
      setState((){
        widget.isLoading = false;
      }),
      Navigator.push(context, MaterialPageRoute(builder: (context) => MyPicView(widget.jpgSrc as String, widget.index)))
    });
  }

  final loadingOverlay = const Positioned.fill(
    child: Align(
      alignment: Alignment.center,
      child: CircularProgressIndicator(backgroundColor: Colors.black12),
    )
  );

  Widget imageContainer() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(widget.thumbnailUrl as String),
          fit: BoxFit.fitWidth,
        ),
        border: Border.all(
          color: Colors.black26,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: () {
        widget.jpgSrc == ''
        ? this.fetchJpgThenNaviPush()
        : Navigator.push(context, MaterialPageRoute(builder: (context) => MyPicView(widget.jpgSrc as String, widget.index)));
      },
      child: Hero(
        tag: widget.index,
        child: widget.isLoading && widget.jpgSrc == ''
          ? Stack(
            children: [
              this.imageContainer(),
              loadingOverlay
            ]
          )
          : this.imageContainer()
      ),
    );
  }
}

// ignore: must_be_immutable
class MyGrid extends StatefulWidget{
  // List<Map<String, String>?> origin = <Map<String, String>?>[];
  List<Map<String, String>?> displayed;
  MyGrid(this.displayed);

  @override
  MyGridState createState() => MyGridState();
}

class MyGridState extends State<MyGrid> {
  // void shuffle() {
  //   int size = widget.origin.length;
  //   List<bool> visited = List<bool>.filled(size, false);
  //   List<Map<String, String>?> shuffled = <Map<String, String>?>[];

  //   Random randomObj = Random();
  //   while(shuffled.length < size) {
  //     int index = randomObj.nextInt(size);
  //     if(visited[index] == false) {
  //       shuffled.add(widget.origin[index]);
  //       visited[index] = true;
  //     }
  //   }

  //   setState(() {
  //     widget.displayed = shuffled;
  //   });
  // }

  void reverse() {
    setState(() {
      widget.displayed = List.from(widget.displayed.reversed);
    });
  }

  // void reset() {
  //   setState(() {
  //     widget.displayed = widget.origin;
  //   });
  // }

  Widget bottomAction(String text){
    return IconsButton(
      onPressed: () => {this.reverse()},
      text: text,
      color: text == 'Reset' ? Colors.red : Colors.blueAccent,
      textStyle: TextStyle(color: Colors.white),
    );
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
                      child: MyPic(each.value!['thumbnail'], each.value!['hrefUrl'], each.key),
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
                  bottomAction('Shuffle'),
                  bottomAction('Reverse'),
                  bottomAction('Reset'),
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

class Scraper extends StatefulWidget {
  @override
  _ScraperState createState() => _ScraperState();
}

class _ScraperState extends State<Scraper> {
  final webScraper = WebScraper('https://safebooru.org/');

  String keyword = 'azumanga_daiou';
  bool newKeyword = false;

  int index = 0;
  int startIndex = 0;
  int paginationMarker = 0;

  int numFetchedPage = 0;
  int currentPage = 1;

  List<Map<String, dynamic>> thumbMap = [];
  List<Map<String, dynamic>> hrefMap = [];
  List<Map<String, String>?> thumbHrefPair = [];
  List<Map<String, String>?> toBeRendered = [];
  bool isProcessing = false;
  
  Future<void> fetchThumbnailHrefPair() async {
    if(this.newKeyword == true) {
      this.thumbHrefPair.clear();
      this.index = 0;
      this.numFetchedPage = 0;
      this.currentPage = 1;
      this.newKeyword = false;
    }

    setState((){
      this.isProcessing = true;
    });

    String pagePostfix = "&pid=${this.index}";
    print('index.php?page=post&s=list&tags=' + this.keyword + pagePostfix);
    if (await webScraper.loadWebPage('index.php?page=post&s=list&tags=' + this.keyword + pagePostfix)) {
      thumbMap = webScraper.getElement('span.thumb >  a > img', ['src']);
      hrefMap = webScraper.getElement('span.thumb > a', ['href']);
      int indexEachFetching = 0;

      final int size = thumbMap.length + this.index;
      this.thumbHrefPair += List<Map<String, String>?>.filled(thumbMap.length, null);
      for (this.startIndex = this.index; this.index < size; this.index++) {
        print(this.index);
        thumbHrefPair[this.index] = {
          'thumbnail' : thumbMap[indexEachFetching]['attributes']['src'],
          'hrefUrl' : hrefMap[indexEachFetching]['attributes']['href'],
        };
        indexEachFetching++;
      }
      this.numFetchedPage++;
      print('----------------');
    }
  }

  void assignTobeRendered(MapEntry<int, Map<String, String>?> each) {
    int pageStartIdx = this.paginationMarker * 40;
    if(each.key >= pageStartIdx) {
       if(this.toBeRendered.length == 40) return;
       this.toBeRendered.add(each.value);
    }
  }

  void paginate(String dir) {
    if (this.currentPage > this.numFetchedPage) {
      this.paginationMarker++;
      this.toBeRendered.clear();
      this.fetchThumbnailHrefPair().then((res) => {
        this.thumbHrefPair.asMap().entries.forEach(assignTobeRendered),
        setState(() {
          this.isProcessing = false;
        })
      });
      return;
    }

    if (this.currentPage < this.numFetchedPage && dir == 'left') {
      this.paginationMarker--;
      this.toBeRendered.clear();
      this.thumbHrefPair.asMap().entries.forEach(assignTobeRendered);
      setState(() {
        this.isProcessing = false;
      });
      return;
    }

    dir == 'init' ? this.paginationMarker = this.currentPage - 1 : this.paginationMarker++;
    this.toBeRendered.clear();
    this.thumbHrefPair.asMap().entries.forEach(assignTobeRendered);
    setState(() {
      this.isProcessing = false;
    });
  }

  Widget paginationArrow(String dir) {
    return Align(
      alignment: dir == 'left' ? Alignment.bottomLeft : Alignment.bottomRight,
      child: Padding(
        padding: dir == 'left' ? EdgeInsets.only(bottom: 25, left: 14.0) : EdgeInsets.only(bottom: 25, right: 14.0),
        child: SizedBox(
          height: 34.5,
          width: 34.5,
          child: FloatingActionButton(
            heroTag: null,
            onPressed: () => { dir == 'left' ? this.currentPage-- : this.currentPage++, this.paginate(dir == 'left' ? 'left' : 'right') },
            child: dir == 'left' ? Icon(Icons.arrow_left_rounded) : Icon(Icons.arrow_right_rounded),
            backgroundColor: Colors.orangeAccent
          )
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            onChanged: (text){
              this.keyword = text;
              this.newKeyword = true;
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
                onTap: () => { this.fetchThumbnailHrefPair().then((res) => { this.paginate('init') })},
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
        body: Stack(
          children: [
            Center(
              child: MyGrid( this.toBeRendered )
            ),
            this.paginationArrow('left'),
            this.paginationArrow('right')
          ],
        )
      ),
    );
  }
}

void main() {
  runApp(
    Scraper()
  );
}