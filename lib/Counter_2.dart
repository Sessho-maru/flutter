import  'package:flutter/material.dart';

class CounterDisplay extends StatelessWidget {
  final int count;
  const CounterDisplay({required this.count, Key? key})
    :super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text('Count: $count');
  }
}

class CounterIncrementer extends StatelessWidget {
  final VoidCallback onPressed;
  const CounterIncrementer({required this.onPressed, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Increment'),
    );
  }
}

class Counter extends StatefulWidget {
  const Counter({Key? key})
    : super(key: key);

  @override
  _CounterState createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _counter = 0;

  void _increment() {
    setState(() {
      ++_counter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CounterIncrementer(onPressed: _increment),
        const SizedBox(width: 32),
        CounterDisplay(count: _counter),
      ],
    );
  }
}

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
            child: Counter(),
        ),
      ),
    ),
  );
}