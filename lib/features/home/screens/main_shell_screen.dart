import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../groups/widgets/group_actions_fab.dart';

class MainShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _animation;
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;
    _previousIndex = _currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward(from: 1.0);
  }

  @override
  void didUpdateWidget(MainShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = newIndex;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isForward = _currentIndex >= _previousIndex;
    final beginOffset = Offset(isForward ? 0.22 : -0.22, 0.0);

    VoidCallback? fabAction;
    IconData? fabIcon;
    String? fabTooltip;

    if (_currentIndex == 0) {
      fabIcon = Icons.add;
      fabTooltip = 'Group Options';
      fabAction = () => showGroupActionSheet(context);
    } else if (_currentIndex == 1) {
      fabIcon = Icons.bolt_outlined;
      fabTooltip = 'Quick Book';
      fabAction = () => context.push('/quick-book');
    }

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(_animation),
          child: widget.navigationShell,
        ),
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (newIndex) {
          widget.navigationShell.goBranch(
            newIndex,
            initialLocation: newIndex == widget.navigationShell.currentIndex,
          );
        },
        onFabPressed: fabAction,
        fabIcon: fabIcon,
        fabTooltip: fabTooltip,
      ),
    );
  }
}
