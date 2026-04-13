import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ScrollView dùng chung để tạo cảm giác vuốt lên/xuống mượt như HomeScreen/AppInfo.
///
/// Mục tiêu:
/// - physics kiểu iOS (bounce) cho cảm giác mượt
/// - hỗ trợ cả kiểu `children` (danh sách widget) và kiểu `slivers`
/// - có thể bọc `SafeArea` và dismiss keyboard khi kéo
///
/// Lưu ý: widget này tập trung vào "cảm giác cuộn". Để tối ưu lag thật sự,
/// nên dùng `slivers` thay vì lồng `ListView/GridView` với `shrinkWrap`.
class ScrollViewAnimation extends StatelessWidget {
  final List<Widget> slivers;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool useSafeArea;
  final bool dismissKeyboardOnDrag;
  final ScrollPhysics? physics;

  /// Dùng khi bạn đã có slivers (khuyên dùng để tối ưu hiệu năng).
  const ScrollViewAnimation.slivers({
    super.key,
    required this.slivers,
    this.padding,
    this.controller,
    this.useSafeArea = true,
    this.dismissKeyboardOnDrag = true,
    this.physics,
  });

  /// Dùng nhanh với danh sách widget thường.
  /// Widget sẽ tự convert sang `SliverList` để cuộn mượt hơn so với SingleChildScrollView.
  factory ScrollViewAnimation.children({
    Key? key,
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
    bool useSafeArea = true,
    bool dismissKeyboardOnDrag = true,
    ScrollPhysics? physics,
  }) {
    return ScrollViewAnimation.slivers(
      key: key,
      controller: controller,
      useSafeArea: useSafeArea,
      dismissKeyboardOnDrag: dismissKeyboardOnDrag,
      physics: physics,
      padding: padding,
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate(
            children,
            addRepaintBoundaries: true,
          ),
        ),
      ],
    );
  }

  ScrollPhysics _defaultPhysics(BuildContext context) {
    // Android thường dùng clamping, iOS bounce.
    // Nhưng yêu cầu của app là muốn "mượt như Home/AppInfo" -> bounce.
    // Giữ bounce cho mọi nền tảng (dễ đồng bộ UI) nhưng vẫn tôn trọng nested scroll.
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget build(BuildContext context) {
    Widget scroll = CustomScrollView(
      controller: controller,
      physics: physics ?? _defaultPhysics(context),
      keyboardDismissBehavior: dismissKeyboardOnDrag
          ? ScrollViewKeyboardDismissBehavior.onDrag
          : ScrollViewKeyboardDismissBehavior.manual,
      slivers: [
        if (padding != null) SliverPadding(padding: padding!, sliver: _wrap()),
        if (padding == null) ...slivers,
      ],
    );

    if (useSafeArea) {
      scroll = SafeArea(child: scroll);
    }

    // Trên web/desktop, bounce có thể "kỳ" nhẹ. Nhưng build vẫn OK.
    // Người dùng đang ưu tiên cảm giác mượt đồng bộ.
    return scroll;
  }

  Widget _wrap() {
    // Khi có padding, phải bọc tất cả slivers trong SliverMainAxisGroup để giữ cấu trúc.
    // Nếu SDK flutter cũ không có SliverMainAxisGroup thì fallback sang SliverList.
    // (Project đang build OK với SliverMainAxisGroup ở HomeScreen.)
    return SliverMainAxisGroup(slivers: slivers);
  }
}
