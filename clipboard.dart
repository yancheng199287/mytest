import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

final Pointer<NativeFunction<WindowProc>> windowProcedure =
    Pointer.fromFunction<WindowProc>(_windowProc, 0);

int _windowProc(int hwnd, int uMsg, int wParam, int lParam) {
  switch (uMsg) {
    case WM_CLIPBOARDUPDATE:
      {
        print('Clipboard content has changed!');
        // 你可以在这里添加代码来处理新的剪贴板内容
      }
      break;
    case WM_DESTROY:
      {
        PostQuitMessage(0);
      }
      break;
    default:
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
  }
  return 0;
}

void main() {
  // 注册窗口类
  final className = TEXT('CLIPBOARD_LISTENER_CLASS');
  final wndClass = calloc<WNDCLASS>()
    ..ref.style = CS_HREDRAW | CS_VREDRAW
    ..ref.lpfnWndProc = windowProcedure
    ..ref.hInstance = GetModuleHandle(nullptr)
    ..ref.lpszClassName = className;

  if (RegisterClass(wndClass) == 0) {
    throw Exception('Error registering class');
  }
  free(wndClass);

  // 创建隐藏窗口
  final hWnd = CreateWindowEx(0, className, TEXT('Clipboard Listener Window'),
      WS_OVERLAPPED, 0, 0, 0, 0, HWND_MESSAGE, nullptr, nullptr, nullptr);

  if (hWnd == 0) {
    throw Exception('Window creation failed');
  }

  // 添加剪贴板监听
  if (AddClipboardFormatListener(hWnd) == 0) {
    throw Exception('Failed to add clipboard listener');
  }

  // 消息循环
  final msg = calloc<MSG>();
  while (GetMessage(msg, NULL, 0, 0) != 0) {
    TranslateMessage(msg);
    DispatchMessage(msg);
  }
  free(msg);

  // 清理
  RemoveClipboardFormatListener(hWnd);
  DestroyWindow(hWnd);
  UnregisterClass(className, GetModuleHandle(nullptr));
}