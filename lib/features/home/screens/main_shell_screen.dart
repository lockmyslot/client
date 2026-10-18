import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../groups/widgets/group_actions_fab.dart';
import '../../groups/screens/groups_list_screen.dart';
import '../../bookings/screens/all_bookings_screen.dart';
import '../../profile/screens/me_profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(MainShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    if (_pageController.hasClients &&
        (_pageController.page?.round() ?? _pageController.initialPage) !=
            newIndex) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    VoidCallback? fabAction;
    IconData? fabIcon;
    String? fabTooltip;

    if (currentIndex == 0) {
      fabIcon = Icons.add;
      fabTooltip = 'Group Options';
      fabAction = () => showGroupActionSheet(context);
    } else if (currentIndex == 1) {
      fabIcon = Icons.bolt_outlined;
      fabTooltip = 'Quick Book';
      fabAction = () => context.push('/quick-book');
    }

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (index != widget.navigationShell.currentIndex) {
            widget.navigationShell.goBranch(index);
          }
        },
        children: const [
          GroupsListScreen(),
          AllBookingsScreen(),
          MeProfileScreen(),
        ],
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: currentIndex,
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
