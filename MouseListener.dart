import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:win32/win32.dart';

class MouseListener {
  static late SendPort sendPort;
  static int lastCreateIsolate = 0;

  /// 注意  在dartffi中，函数只能使用静态函数去传参
  /// 使用Isolate创建线程，只能由他自己内部关闭，外部无法持有其引用，只能通过SendPort交互通信
  /// 在线程内部使用while循环会独占线程资源，其他监听函数无法得到时间片执行，可以改用Timer定时调度，会把Timer作为一个事件去循环，不需要执行的时候会让出时间给其他任务执行
  /// Isolate去创建任务，会完全隔离外部环境，只能通过建立任务的时候去传参初始化和使用SendPort交换数据通信

  static void start(SendPort sendPort) {
    MouseListener.sendPort = sendPort;
    final hMod = GetModuleHandle(nullptr);
    final mouseHook = SetWindowsHookEx(
        WH_MOUSE_LL, Pointer.fromFunction(_mouseProc1, 0), hMod, 0);
    var msg = Pointer<MSG>.fromAddress(0);
    while (GetMessage(msg, NULL, 0, 0) != 0) {
      TranslateMessage(msg);
      DispatchMessage(msg);
    }
    UnhookWindowsHookEx(mouseHook);
    free(msg);
  }

  /// 如果启动了quicker 鼠标手势等软件  这些软件也监听了鼠标事件，会导致重复回调这个事件，需要在createIsolate()方法中做些处理，如果调用太快就直接返回，不去创建线程任务了
  static int _mouseProc1(int nCode, int wParam, int lParam) {
    if (nCode >= 0) {
      switch (wParam) {
        case WM_RBUTTONDOWN:
          createIsolate();
          break;
        case WM_RBUTTONUP:
          print("鼠标按钮松开 发送事件，关闭问询鼠标长按三秒的线程");
          MouseListener.sendPort.send(2);
          break;
      }
    }

    return CallNextHookEx(0, nCode, wParam, lParam);
  }

  static createIsolate() {
    print("createIsolate  starting ");
    /// 鼠标钩子事件重复触发，直接过滤掉
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    var aa = currentTime - lastCreateIsolate;
    if (aa < 300) {
      print("太快了 忽略... ");
      return;
    }
    lastCreateIsolate = currentTime;
    Isolate.spawn(checkLongPress, MouseListener.sendPort);
    print("createIsolate  ending ");
  }

  static Future<void> checkLongPress(SendPort sendPort) async {
    ReceivePort longPressRightReceivePort = ReceivePort();
    SendPort longPressSendPort = longPressRightReceivePort.sendPort;
    sendPort.send(longPressSendPort);
    longPressRightReceivePort.listen((element) {
      if (element == "close") {
        print("close checkLongPress isolate");
        Isolate.current.kill(priority: Isolate.immediate);
        Isolate.exit(sendPort);
      }
    });

    // timer是基于事件循环机制，让当前线程开启一个事件循环，不断去回调函数中去任务，是单线程里事件循环，在其他时间可以让出时间执行其他事情，不会阻塞
    // while循环会阻塞，不要使用+sleep去等待时间做判断处理！！
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      // 检查条件并执行任务  6代表走了6次，一次是 500毫秒，6次就是三秒
      if (timer.tick >= 3) {
        // 在循环期间满足条件后发送消息给主线程
        sendPort.send(1);
        timer.cancel();
      }
    });
    print("循环结束,三秒完成或者线程关闭");
  }
}
