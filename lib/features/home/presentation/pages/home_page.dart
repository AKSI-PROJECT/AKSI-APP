import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/home_banner.dart';
import '../widgets/feature_grid.dart';
import '../widgets/recent_activity.dart';
import '../../../../core/widgets/fade_in_slide.dart';

class HomePage extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const HomePage({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                child: const HomeHeader(),
              ),
              const SizedBox(height: 24),
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: const HomeBanner(),
              ),
              const SizedBox(height: 28),
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: const Text(
                  'Lindungin data anda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInSlide(
                delay: const Duration(milliseconds: 400),
                child: const FeatureGrid(),
              ),
              const SizedBox(height: 28),
              FadeInSlide(
                delay: const Duration(milliseconds: 500),
                child: RecentActivity(
                  onViewAll: () {
                    if (onNavigateToTab != null) {
                      onNavigateToTab!(1);
                    }
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

