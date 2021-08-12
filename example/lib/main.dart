import 'package:flutter/material.dart';
import 'package:cups_ffi/cups_ffi.dart' as cups;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cups Print Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Cups Print Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loadingPrinters = false;
  bool _printing = false;
  String? _printers;
  bool? _printResult;
  List<cups.Printer> printers = [];

  void listPrinters() {
    setState(() {
      _printers = null;
      _loadingPrinters = true;
    });
    printers = cups.listPrinters(0, 0);
    for (var printer in printers) {
      print("${printer.name}   Default:${printer.isDefault}");
    }
    setState(() {
      _printers = printers.map((p) => p.name).join("\n");
      _loadingPrinters = false;
    });
  }

  void printHelloWorld() {
    if (printers.length == 0) {
      listPrinters();
    }
    if (printers.length == 0) {
      print('No printers found');
      return;
    }
    var defaultPrinter = printers.where((x) => x.isDefault);
    cups.Printer printer;
    if (defaultPrinter.isNotEmpty) {
      printer = defaultPrinter.first;
    } else {
      printer = printers.first;
    }
    setState(() {
      _printResult = null;
      _printing = true;
    });
    var result = cups.printRawText(cups.CupsFormat.CUPS_FORMAT_TEXT,
        printer.name, "Cups Demo", "Hello world\n\n\n");
    setState(() {
      _printResult = result;
      _printing = false;
    });
  }

  void printRaw() {
    if (printers.length == 0) {
      listPrinters();
    }
    if (printers.length == 0) {
      print('No printers found');
      return;
    }
    var defaultPrinter = printers.where((x) => x.isDefault);
    cups.Printer printer;
    if (defaultPrinter.isNotEmpty) {
      printer = defaultPrinter.first;
    } else {
      printer = printers.first;
    }
    setState(() {
      _printResult = null;
      _printing = true;
    });

    var data = [
      0x1B,
      0x40,
      0x1B,
      0x74,
      0x12,
      0x54,
      0x45,
      0x53,
      0x54,
      0x20,
      0xE6,
      0xD1,
      0xAC,
      0x8F,
      0xA6,
      0xE7,
      0xD0,
      0x9F,
      0x86,
      0xA7,
      0x0D,
      0x0A,
      0x0D,
      0x0A,
      0x0D,
      0x0A,
      0x0D,
      0x0A,
      0x0
    ];

    var result = cups.printRawData(
        cups.CupsFormat.CUPS_FORMAT_RAW, printer.name, "Demo", data);
    setState(() {
      _printResult = result;
      _printing = false;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title!),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text("List printers"),
                ),
                onPressed:
                    (_printing || _loadingPrinters) ? null : listPrinters,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text("Print Hello world"),
                ),
                onPressed:
                    (_printing || _loadingPrinters) ? null : printHelloWorld,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text("Print raw data"),
                ),
                onPressed: (_printing || _loadingPrinters) ? null : printRaw,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: _loadingPrinters
                  ? LinearProgressIndicator()
                  : SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _printers ?? '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _printResult == null
                    ? ''
                    : (_printResult!
                        ? 'Printing succeeded'
                        : 'Printing failed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
