import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'MouseListener.dart';

var logger = Logger(
  printer: PrettyPrinter(
      methodCount: 2,
      // Number of method calls to be displayed
      errorMethodCount: 8,
      // Number of method calls if stacktrace is provided
      lineLength: 120,
      // Width of the output
      colors: true,
      // Colorful log messages
      printEmojis: true,
      // Print an emoji for each log message
      printTime: true // Should each log print contain a timestamp
      ),
);

String valueAA = "";

final sendPortValue = StateProvider((ref) => "空空");

Future<void> main() async {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  ConsumerState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    // 创建异步任务，绑定鼠标挂钩事件
    _startNewIsolate();
  }

  void _startNewIsolate() async {
    // 创建当前UI接收器端口，用来接受消息处理UI显示或者其他发送送消息
    ReceivePort uiReceivePort = ReceivePort();

    // 创建一个临时发送端口对象，这个是为了获取 长按鼠标右键线程的SendPort。通过这个longPressSendPort我们可以在条件满足对其关闭
    late SendPort longPressSendPort;
    // mouseListenerData 是完全拷贝到线程里去的，为了隔离数据，所以后续代码不能对mouseListenerData额外更改，到线程里都是无效的
    Isolate.spawn(MouseListener.start, uiReceivePort.sendPort);

    // 循环去消费接收到的消息
    uiReceivePort.forEach((element) {
      logger.i("收到鼠标完成事件receive: $element");

      // 存下另外一个线程发送过来的SendPort，拥有 SendPort 我们就可以对其进行通信
      if (element is SendPort) {
        longPressSendPort = element;

      } else if (element == 1) {
        valueAA = "99999999";
        ref.read(sendPortValue.notifier).update((state) => valueAA);

        // 如果鼠标右键按下，会发送2，我们就去关闭longPressSendPort对应的线程
      } else if (element == 2) {
        longPressSendPort.send("close");
      }
    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aa = ref.watch(sendPortValue);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () {
                logger.i("valueAA: $valueAA");
                ref.read(sendPortValue.notifier).update((state) => valueAA);
              },
              child: Text("点击获取内容 $aa"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
