import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spotify/common/widgets/appbar/app_bar.dart';
import 'package:spotify/core/configs/assets/app_images.dart';

import '../../../common/helpers/is_dark_mode.dart';
import '../../../core/configs/assets/app_vectors.dart';
import '../../../core/configs/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        hideBack: true,
        title: SvgPicture.asset(AppVectors.logo, height: 40, width: 40),
      ),
      body: SingleChildScrollView(
        child: Column(children: [_homeTopCard(), _tabs()]),
      ),
    );
  }

  Widget _homeTopCard() {
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: SvgPicture.asset(AppVectors.homeTopCard),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 60),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(AppImages.homeArtist),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      // 👇 去掉 TabBar 上方那条横线
      indicatorColor: AppColors.primary,
      dividerColor: Colors.transparent,
      // 👇 让 Tab 内容居中
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 10
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: context.isDarkMode ? Colors.white : Colors.black,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: context.isDarkMode ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
      ),
      tabs: const [
        Tab(text: 'News'),
        Tab(text: 'Videos'),
        Tab(text: 'Artists'),
        Tab(text: 'Podcasts'),
      ],
    );
  }
}
