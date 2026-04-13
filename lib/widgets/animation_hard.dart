import 'package:flutter/material.dart';

/// Widget "nâng cao" cho các màn hình phức tạp để vẫn có cảm giác cuộn mượt,
/// giữ chuẩn giống HomeScreen (bounce + dismiss keyboard), nhưng hỗ trợ:
///
/// - SliverAppBar / header (pinned/floating)
/// - Body kiểu sliver (SliverList/SliverGrid/SliverFillRemaining...)
/// - Pull-to-refresh (RefreshIndicator) nếu cần
/// - Chừa khoảng trống dưới (bottom padding) cho FloatingCarBottomNav
/// - Có thể dùng NestedScrollView khi bạn cần AppBar collapse + list bên dưới
///
/// Đây là widget để "dùng lại". Nó không tự sửa cấu trúc màn hình.
/// Bạn chỉ bọc lại body và truyền đúng slivers.
class AnimationHard extends StatelessWidget {
  /// Slivers cho phần header (thường là SliverAppBar hoặc header collapse)
  final List<Widget> headerSlivers;

  /// Slivers cho phần body.
  /// Tip: dùng SliverList/SliverGrid thay vì ListView/GridView shrinkWrap.
  final List<Widget> bodySlivers;

  /// Padding cho body.
  final EdgeInsetsGeometry bodyPadding;

  /// Nếu true: bọc SafeArea.
  final bool useSafeArea;

  /// Nếu kéo để dismiss keyboard.
  final bool dismissKeyboardOnDrag;

  /// Physics override (mặc định bounce như Home/AppInfo)
  final ScrollPhysics? physics;

  /// Controller nếu cần.
  final ScrollController? controller;

  /// Enable pull-to-refresh.
  final Future<void> Function()? onRefresh;

  /// Reserve extra bottom space. Mặc định chừa cho bottom nav nổi.
  /// Nếu màn hình không có bottom nav, set = 0.
  final double bottomReserve;

  const AnimationHard({
    super.key,
    this.headerSlivers = const [],
    required this.bodySlivers,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.useSafeArea = true,
    this.dismissKeyboardOnDrag = true,
    this.physics,
    this.controller,
    this.onRefresh,
    this.bottomReserve = 120,
  });

  ScrollPhysics _defaultPhysics() {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget build(BuildContext context) {
    Widget scroll = NestedScrollView(
      controller: controller,
      physics: physics ?? _defaultPhysics(),
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return headerSlivers;
      },
      body: Builder(
        builder: (context) {
          // NestedScrollView body cần một scrollable riêng.
          Widget inner = CustomScrollView(
            physics: physics ?? _defaultPhysics(),
            keyboardDismissBehavior: dismissKeyboardOnDrag
                ? ScrollViewKeyboardDismissBehavior.onDrag
                : ScrollViewKeyboardDismissBehavior.manual,
            slivers: [
              SliverPadding(
                padding: bodyPadding,
                sliver: SliverMainAxisGroup(slivers: bodySlivers),
              ),
              // Chừa đáy cho bottom nav nổi + safe area.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: bottomReserve + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          );

          if (onRefresh != null) {
            inner = RefreshIndicator(onRefresh: onRefresh!, child: inner);
          }

          return inner;
        },
      ),
    );

    if (useSafeArea) {
      // NestedScrollView đã xử lý một phần insets, nhưng SafeArea vẫn giúp
      // tránh status bar cho các layout tùy biến.
      scroll = SafeArea(child: scroll);
    }

    return scroll;
  }
}
