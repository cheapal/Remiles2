
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_load_ai_match.dart';
import 'package:flutter/material.dart';



class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003D2B), // Dark green color
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Re-Miles Academy",style: TextStyle(color: Colors.white),),
            Text("Learn about the app and its features",style: TextStyle(color: Colors.white,fontSize: 12),),
          ],
        ), //
        leading: Text(''),// No title needed
        // The TabBar is placed in the 'bottom' property of the AppBar
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicator: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white,
                width: 4.0,
              ),
            ),
          ),
          tabs: const [
            Tab(text: 'VIDEOS'),
            Tab(text: 'PLAYLISTS'),
          ],
        ),
      ),
      // TabBarView holds the content for each tab
      body: TabBarView(
        controller: _tabController,
        children: [
          // Content for the first tab
          _buildTabContent(),
          // Content for the second tab (can be different)
          // For this example, we'll show the same layout
          _buildTabContent(),
        ],
      ),
    );
  }

  /// Builds the content layout for a single tab page.
  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 40),
          // Video Grid
          Expanded(
            child: _buildVideoGrid(),
          ),
        ],
      ),
    );
  }

  /// Builds the styled search bar widget.
  Widget _buildSearchBar() {
    return   Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: searchBar(hint: 'Search My Loads',showTrail: false),
    );
  }

  /// Builds the grid of video placeholders.
  Widget _buildVideoGrid() {
    // Using a list of 8 for better scrolling demonstration
    return GridView.builder(
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,        // 2 columns
        crossAxisSpacing: 16.0,   // Horizontal space
        mainAxisSpacing: 16.0,    // Vertical space
        childAspectRatio: 0.75,   // Adjusted for title and caption space
      ),
      itemBuilder: (context, index) {
        return _buildVideoThumbnail();
      },
    );
  }

  /// Builds a single video thumbnail placeholder.
  Widget _buildVideoThumbnail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video thumbnail container
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child:  Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Title and caption section
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Getting Started',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Introduction to the app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}