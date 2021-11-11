import 'package:flutter/material.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:web_scraper/web_scraper.dart';
import 'dart:math';

const int NUM_IMG_PER_PAGE = 40;
enum eDir {
  LEFT, RIGHT, INIT
}

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
        if (FocusScope.of(context).hasPrimaryFocus == false) {
          FocusScope.of(context).focusedChild!.unfocus();
          return;
        }

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
  List<Map<String, String>?> displayed;
  MyGrid(this.displayed);

  @override
  MyGridState createState() => MyGridState();
}

class MyGridState extends State<MyGrid> {
  void shuffle() {
    int size = widget.displayed.length;
    List<bool> visited = List<bool>.filled(size, false);
    List<Map<String, String>?> shuffled = <Map<String, String>?>[];

    Random randomObj = Random();
    while(shuffled.length < size) {
      int index = randomObj.nextInt(size);
      if(visited[index] == false) {
        shuffled.add(widget.displayed[index]);
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

  Widget bottomAction(String text){
    return IconsButton(
      onPressed: () => {
        text == 'Shuffle'
          ? this.shuffle()
          : this.reverse()
      },
      text: text,
      color: Colors.blueAccent,
      textStyle: TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Column(
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

  String keyword = 'NOT_SET';
  bool newKeyword = false;

  int index = 0;
  int idxStartCurPageFrom = 0;
  int idxEndCurPageTo = 0;
  int idxlastPageFrom = 0;

  int paginationMarker = 0;
  int numFetchedPage = 0;
  int currentPage = 1;
  
  bool isProcessing = false;
  bool isNotFound = false;
  int resultEndsAt = 0;

  bool get isKeywordSet {
    return this.keyword != 'NOT_SET';
  }

  bool get isFirstPage {
    return this.paginationMarker == 0;
  }

  bool get isLastPage {
    return this.currentPage == this.resultEndsAt;
  }

  int get initialIdxCurPage {
    return NUM_IMG_PER_PAGE * this.paginationMarker;
  }

  List<Map<String, dynamic>> thumbMap = [];
  List<Map<String, dynamic>> hrefMap = [];
  List<Map<String, dynamic>> paginationMap = [];
  List<Map<String, String>?> thumbHrefPair = [];
  List<Map<String, String>?> toBeRendered = [];
  
  Future<void> fetchThumbnailHrefPair() async {
    if (this.newKeyword == true) {
      this.thumbHrefPair.clear();
      this.index = 0;
      this.numFetchedPage = 0;
      this.currentPage = 1;
      this.isNotFound = false;
      this.resultEndsAt = 0;
      this.idxlastPageFrom = 0;
      this.newKeyword = false;
    }

    setState((){
      this.isProcessing = true;
    });

    String urlPostfix = "&pid=${this.index}";
    print('index.php?page=post&s=list&tags=' + this.keyword.replaceAll(' ', '_').toLowerCase() + urlPostfix);
    if (await webScraper.loadWebPage('index.php?page=post&s=list&tags=' + this.keyword.replaceAll(' ', '_').toLowerCase() + urlPostfix)) {
      thumbMap = webScraper.getElement('span.thumb > a > img', ['src']);
      if (thumbMap.length == 0) {
        this.isNotFound = true;
        return;
      }
      hrefMap = webScraper.getElement('span.thumb > a', ['href']);

      if (this.idxlastPageFrom == 0) {
        paginationMap = webScraper.getElement('div.pagination > a', ['href']);
        String tailHref = paginationMap.removeLast()['attributes']['href'];
        this.idxlastPageFrom = int.parse(tailHref.substring(tailHref.indexOf('&pid=') + 5));
      }

      int indexEachFetching = 0;

      this.idxStartCurPageFrom = this.index;
      this.idxEndCurPageTo = thumbMap.length + this.index;
      this.thumbHrefPair += List<Map<String, String>?>.filled(thumbMap.length, null);

      for (; this.index < this.idxEndCurPageTo; this.index++) {
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

  void paginate(eDir dir) {
    if (dir == eDir.RIGHT) {
      this.paginationMarker++;
      this.toBeRendered.clear();

      if (this.currentPage > this.numFetchedPage) {
        this.fetchThumbnailHrefPair().then((res) => {
          assignTobeRendered(this.idxStartCurPageFrom, this.idxEndCurPageTo),
          if (this.idxStartCurPageFrom == this.idxlastPageFrom) {
            this.resultEndsAt = this.currentPage
          },
          setState(() {
            this.isProcessing = false;
          })
        });
        return;
      }

      int endIdx = (isLastPage)
        ? this.thumbHrefPair.length
        : initialIdxCurPage + NUM_IMG_PER_PAGE;
      assignTobeRendered(initialIdxCurPage, endIdx);
      setState(() {
        this.isProcessing = false;
      });
      return;
    }

    if (dir == eDir.LEFT) {
      this.paginationMarker--;
      this.toBeRendered.clear();

      assignTobeRendered(initialIdxCurPage, initialIdxCurPage + NUM_IMG_PER_PAGE);
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

    this.paginationMarker = 0;
    this.toBeRendered.clear();
    
    if (this.thumbHrefPair.length < NUM_IMG_PER_PAGE) {
      this.resultEndsAt = this.currentPage;
    }
    assignTobeRendered(0, this.thumbHrefPair.length);
    setState(() {
      this.isProcessing = false;
    });
  }

  bool isEdgeOfPagination(eDir dir) {
    return (isFirstPage && dir == eDir.LEFT) || (isLastPage && dir == eDir.RIGHT);
  }

  Widget paginatorArrow(eDir dir) {
    if (this.isNotFound == false && this.isProcessing == false && isKeywordSet == true) {
      return Align(
        alignment: dir == eDir.LEFT ? Alignment.bottomLeft : Alignment.bottomRight,
        child: Padding(
          padding: dir == eDir.LEFT ? EdgeInsets.only(bottom: 25, left: 14.0) : EdgeInsets.only(bottom: 25, right: 14.0),
          child: SizedBox(
            height: 34.5,
            width: 34.5,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () => {
                if (isEdgeOfPagination(dir) == true) {
                  null
                }
                else {
                  dir == eDir.LEFT ? this.currentPage-- : this.currentPage++, this.paginate(dir == eDir.LEFT ? eDir.LEFT : eDir.RIGHT)
                }
              },
              child: dir == eDir.LEFT ? Icon(Icons.arrow_left_rounded) : Icon(Icons.arrow_right_rounded),
              backgroundColor: isEdgeOfPagination(dir) == true ? Colors.grey : Colors.orangeAccent
            )
          ),
        )
      );
    }
    return Align();
  }

  final loadingScreen = const SizedBox(
    height: 170.0,
    width: 170.0,
    child: CircularProgressIndicator(
      strokeWidth: 11,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
    )
  );

  final cover = const Padding(
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
                onTap: () => { this.fetchThumbnailHrefPair().then((res) => { this.paginate(eDir.INIT) })},
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
              child: (isKeywordSet == false)
                ? cover
                : this.isProcessing
                  ? loadingScreen
                  : this.isNotFound 
                    ? Text('Sorry, result has not found with given keyword')
                    : MyGrid( this.toBeRendered )
            ),
            this.paginatorArrow(eDir.LEFT),
            this.paginatorArrow(eDir.RIGHT)
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