import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'dart:async';
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

class MyGrid extends StatefulWidget{
  @override
  MyGridState createState() => MyGridState();
}

class MyGridState extends State<MyGrid> {
  List<String> origin = <String>[];
  List<String> displayed = <String>[];

  Future<String> fetchFileData() async{
    return await rootBundle.loadString('txt/urls.txt');
  }

  @override
  void initState() {
    super.initState();
    fetchFileData().then((raw) {
      setState(() {
        this.origin = this.displayed = raw.split("|");
      });
    });
  }

  void reverse() {
    setState(() {
      this.displayed = List.from(this.displayed.reversed);
    });
  }

  void shuffle() {
    int size = this.origin.length;
    List<bool> visited = List<bool>.filled(size, false);
    List<String> shuffled = <String>[];

    Random randomObj = Random();
    while(shuffled.length != size) {
      int index = randomObj.nextInt(size);
      if(visited[index] == false) {
        shuffled.add(this.origin[index]);
        visited[index] = true;
      }
    }

    setState(() {
      this.displayed = shuffled;
    });
  }

  void reset() {
    setState(() {
      this.displayed = this.origin;
    });
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
                children: displayed.asMap().entries.map((each) {
                  return Container(
                    child: MyPic(each.value, each.key),
                  );
                }).toList()
            ),
          ),
        ],
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            decoration: const InputDecoration(
              hintText: '  Pinterest',
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
                onTap: () => {},
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
          child: MyGrid(),
        ),
      ),
    ),
  );
}