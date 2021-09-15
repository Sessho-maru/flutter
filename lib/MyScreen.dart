import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:material_dialogs/material_dialogs.dart';
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
      this.displayed = List.from(this.origin.reversed);
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
    return Column(
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
        Expanded(
          flex: 1,
          child: Row(
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: MyButton('Reverse', this.reverse)
              ),
              Expanded(
                  flex: 1,
                  child: MyButton('Shuffle', this.shuffle)
              ),
              Expanded(
                  flex: 1,
                  child: MyButton('Reset', this.reset)
              )
            ],
          )
        )
      ],
    );
  }
}

typedef SwitchOrderCallback = Function();
class MyButton extends StatelessWidget {
  final String title;
  final SwitchOrderCallback orderSwitch;
  const MyButton(this.title, this.orderSwitch);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        this.orderSwitch();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: Colors.lightGreen[500],
        ),
        child: Center(
          child: Text(this.title),
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
        body: Center(
          child: MyGrid(),
        ),
      ),
    ),
  );
}