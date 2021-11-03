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
      List<Map<String, dynamic>> jpgSrcMap = webScraper.getElement('div.content > div > img', ['src']);
      return jpgSrcMap[0]['attributes']['src'];
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

  // void reverse() {
  //   setState(() {
  //     widget.displayed = List.from(widget.displayed.reversed);
  //   });
  // }

  void reset() {
  }

  Widget bottomAction(String text){
    return IconsButton(
      onPressed: () => {this.reset()},
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

  String keyword = 'show_top_png';
  bool newKeyword = false;

  int index = 0;
  int startIndex = 0;
  int endIndex = 0;
  int lastPageFromIdx = 0;

  int paginationMarker = 0;
  int numFetchedPage = 0;
  int currentPage = 1;

  List<Map<String, dynamic>> thumbMap = [];
  List<Map<String, dynamic>> hrefMap = [];
  List<Map<String, dynamic>> paginationMap = [];
  List<Map<String, String>?> thumbHrefPair = [];
  List<Map<String, String>?> toBeRendered = [];
  
  bool isProcessing = false;
  bool isNotFound = false;
  int resultEndsAt = 0;
  
  Future<void> fetchThumbnailHrefPair() async {
    if (this.newKeyword == true) {
      this.thumbHrefPair.clear();
      this.index = 0;
      this.numFetchedPage = 0;
      this.currentPage = 1;
      this.isNotFound = false;
      this.resultEndsAt = 0;
      this.lastPageFromIdx = 0;
      this.newKeyword = false;
    }

    setState((){
      this.isProcessing = true;
    });

    String urlPostfix = "&pid=${this.index}";
    print('index.php?page=post&s=list&tags=' + this.keyword + urlPostfix);
    if (await webScraper.loadWebPage('index.php?page=post&s=list&tags=' + this.keyword + urlPostfix)) {
      thumbMap = webScraper.getElement('span.thumb > a > img', ['src']);
      if (thumbMap.length == 0) {
        this.isNotFound = true;
        return;
      }
      hrefMap = webScraper.getElement('span.thumb > a', ['href']);

      if (this.lastPageFromIdx == 0) {
        paginationMap = webScraper.getElement('div.pagination > a', ['href']);
        String tailHref = paginationMap.removeLast()['attributes']['href'];
        this.lastPageFromIdx = int.parse(tailHref.substring(tailHref.indexOf('&pid=') + 5));
      }

      int indexEachFetching = 0;

      this.startIndex = this.index;
      this.endIndex = thumbMap.length + this.index;
      this.thumbHrefPair += List<Map<String, String>?>.filled(thumbMap.length, null);

      for (; this.index < endIndex; this.index++) {
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

  void assignTobeRendered(int fromIdx, int endIdx) {
      for(int i = fromIdx; i < endIdx; i++) {
        this.toBeRendered.add(this.thumbHrefPair[i]);
      }
  }

  void paginate(String dir) {
    if (this.currentPage > this.numFetchedPage && dir != 'init') {
      this.paginationMarker++;
      this.toBeRendered.clear();

      this.fetchThumbnailHrefPair().then((res) => {
        assignTobeRendered(this.startIndex, this.endIndex),
        if (this.startIndex == this.lastPageFromIdx) {
          this.resultEndsAt = this.currentPage
        },
        setState(() {
          this.isProcessing = false;
        })
      });
      return;
    }

    if (this.currentPage < this.numFetchedPage && dir == 'left') {
      this.toBeRendered.clear();
      this.paginationMarker--;
      assignTobeRendered(this.paginationMarker * 40, (this.paginationMarker * 40) + 40);
      setState(() {
        this.isProcessing = false;
      });
      return;
    }

    if (this.isNotFound == true) {
      setState(() {
        this.isProcessing = false;
      });
      return;
    } 

    this.toBeRendered.clear();
    if (dir == 'init') {
      this.paginationMarker = 0;
      if (this.thumbHrefPair.length < 40) {
        this.resultEndsAt = this.currentPage;
      }
      assignTobeRendered(0, this.thumbHrefPair.length);
    }
    else {
      this.paginationMarker++;
      int endIdx = (this.currentPage == this.resultEndsAt)
        ? this.thumbHrefPair.length
        : (40 * this.paginationMarker) + 40;
        assignTobeRendered(40 * this.paginationMarker, endIdx);
    }
    setState(() {
      this.isProcessing = false;
    });
  }

  bool isLeftmostFirstpageOrRightMostNoMoreResult(String dir) {
    return (this.paginationMarker == 0 && dir == 'left') || (this.resultEndsAt == this.currentPage && dir == 'right');
  }

  Widget paginatorArrow(String dir) {
    if (this.isProcessing == false && this.keyword != 'show_top_png') {
      return Align(
        alignment: dir == 'left' ? Alignment.bottomLeft : Alignment.bottomRight,
        child: Padding(
          padding: dir == 'left' ? EdgeInsets.only(bottom: 25, left: 14.0) : EdgeInsets.only(bottom: 25, right: 14.0),
          child: SizedBox(
            height: 34.5,
            width: 34.5,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () => {
                if (isLeftmostFirstpageOrRightMostNoMoreResult(dir)) {
                  null
                }
                else {
                  dir == 'left' ? this.currentPage-- : this.currentPage++, this.paginate(dir == 'left' ? 'left' : 'right')
                }
              },
              child: dir == 'left' ? Icon(Icons.arrow_left_rounded) : Icon(Icons.arrow_right_rounded),
              backgroundColor: isLeftmostFirstpageOrRightMostNoMoreResult(dir) ? Colors.grey : Colors.orangeAccent
            )
          ),
        )
      );
    }
    return Align();
  }

  final loading = const SizedBox(
    height: 170.0,
    width: 170.0,
    child: CircularProgressIndicator(
      strokeWidth: 11,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
    )
  );

  final coverImg = const Padding(
    padding: EdgeInsets.only(bottom: 170.0), 
    child: Image(
      image: AssetImage('data-original_merged.png')
    )
  );

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
              child: this.keyword == 'show_top_png'
                ? coverImg
                : this.isProcessing
                  ? loading
                  : this.isNotFound 
                    ? Text('Sorry, result has not found with given keyword')
                    : MyGrid( this.toBeRendered )
            ),
            this.paginatorArrow('left'),
            this.paginatorArrow('right')
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

/*
  TODO:
    block pagination on right-most page - completed
    magnify, swipe event handler on MyPicView widget
*/