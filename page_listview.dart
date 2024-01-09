import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 保存分页查询加载的各个状态变量
class PaginationState<T> {
  /// 查询的结果列表
  final List<T> items;

  /// 加载的状态值，加载中（显示），加载完成（隐藏）
  final bool isLoading;

  /// 显示错误的消息
  final String? error;

  /// 当前页码
  final int currentPage;

  PaginationState({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.currentPage,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
  }) {
    return PaginationState<T>(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        currentPage: currentPage ?? this.currentPage);
  }
}

///
class PaginationNotifier<T> extends StateNotifier<PaginationState<T>> {
  final Future<List<T>> Function(int page) fetchItems;
  final int initialPage = 1;

  PaginationNotifier({
    required this.fetchItems,
  }) : super(PaginationState<T>(
          items: [],
          isLoading: false,
          error: null,

          /// 加载下一页会自动+1
          currentPage: 0,
        ));

  /// 重新刷新，加载默认第一页
  Future<void> refresh() async {
    state = state.copyWith(
      items: [],
      isLoading: true,
      error: null,
    );

    try {
      await loadItems(page: initialPage);
    } catch (error) {
      state = state.copyWith(error: _getErrorString(error), isLoading: false);
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading) return;
    //  ~/ 整除运算，两个变量除以保留整数
    final nextPage = state.currentPage + 1;

    await loadItems(page: nextPage);
  }

  Future<void> loadItems({required int page}) async {
    state = state.copyWith(isLoading: true);

    try {
      final items = await fetchItems(page);

      /// 如果返回的列表是空的，页面回滚-1，如果有数据，就更新当前页码
      int currentPage = items.isEmpty ? page-1 : page;

      print("currentPage $currentPage");

      state = state.copyWith(
        items: [...state.items, ...items],
        currentPage: currentPage,
        isLoading: false,
      );
    } catch (error) {
      /// 这里异常了，页面也要回滚上一页
      state = state.copyWith(
        error: _getErrorString(error),
        currentPage: page-1,
        isLoading: false,
      );
    }
  }

  String? _getErrorString(dynamic error) {
    // 根据需要返回错误字符串
    // 针对不同的错误类型可以返回不同的内容
    return error.toString();
  }
}

class PaginationProvider<T> {
  final PaginationNotifier<T> _notifier;

  PaginationProvider(this._notifier);

  PaginationNotifier<T> get notifier => _notifier;

  bool get isLoading => _notifier.state.isLoading;

  int get totalItems => _notifier.state.items.length;

  Future<void> refresh() => _notifier.refresh();

  Future<void> loadNextPage() => _notifier.loadNextPage();

  static PaginationProvider<T> create<T>(
      PaginationNotifier<T> paginationNotifier, WidgetRef ref) {
    final paginationNotifierProvider =
        StateNotifierProvider<PaginationNotifier<T>, PaginationState<T>>((ref) {
      return paginationNotifier;
    });
    ref.watch(paginationNotifierProvider);
    return PaginationProvider<T>(paginationNotifier);
  }
}
















import 'dart:math';

import 'package:ai_chat/com.oneinlet/database/app_database.dart';
import 'package:ai_chat/com.oneinlet/database/dao/BaseDao.dart';
import 'package:ai_chat/com.oneinlet/database/dao/MessageRecordDao.dart';
import 'package:ai_chat/com.oneinlet/database/service/MessageRecordService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../component/listview/page_listview.dart';

class ListViewPage extends ConsumerWidget {
  final paginationNotifierProvider =
      PaginationNotifier<MessageRecordData>(fetchItems: (page) async {
    PageData<MessageRecordData> pageData = await MessageRecordDao.instance
        .selectPageMessageRecord(2, 1, DriftPage(3, page));
    print("jiaz $page  ${pageData.recordList}");
    return pageData.recordList;
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PaginationProvider productProvider =
        PaginationProvider.create(paginationNotifierProvider, ref);

    return Scaffold(
      appBar: AppBar(
        title: TextButton(
            onPressed: () {
              productProvider.loadNextPage();
            },
            child: const Text("点击开始聊天")),
      ),
      body: RefreshIndicator(
        displacement: 44.0,
        onRefresh: () async {
          //模拟网络请求
          await Future.delayed(Duration(milliseconds: 2000));
          //结束刷新
          return Future.value(true);
        },
        child: ListView.builder(
         physics: const AlwaysScrollableScrollPhysics(),
          itemCount: productProvider.totalItems + 1,
          itemBuilder: (context, index) {
            if (index == productProvider.totalItems) {
              if (productProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              } else {
                return SizedBox.shrink();
              }
            }
            final message = productProvider.notifier.state.items[index];
            return ListTile(
              title: Text(message.content),
              subtitle: Text(message.createdTime.toString()),
            );
          },
        ),
      ),
    );
  }
}

