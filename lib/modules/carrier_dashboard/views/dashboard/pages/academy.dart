import 'package:flutter/material.dart';
import '../../../../../../core/firebase_service.dart';
import '../../../../../../models/academy_content.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
    });
  }

  bool _matchesSearch(AcademyContent content) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return content.title.toLowerCase().contains(query) ||
        content.description.toLowerCase().contains(query) ||
        content.tags.any((tag) => tag.toLowerCase().contains(query));
  }

  Future<void> _shareContent(AcademyContent content) async {
    try {
      final url = content.videoUrl ?? content.documentUrl ?? '';
      final shareText = '${content.title}\n\n${content.description}\n\n${url.isNotEmpty ? url : ''}';
      await Share.share(
        shareText,
        subject: content.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openContent(AcademyContent content) async {
    if (content.contentType == 'video' && content.videoUrl != null) {
      // Open video in webview or external player
      if (await canLaunchUrl(Uri.parse(content.videoUrl!))) {
        await launchUrl(Uri.parse(content.videoUrl!), mode: LaunchMode.externalApplication);
      }
    } else if (content.contentType == 'document' && content.documentUrl != null) {
      // Open document in webview
      if (await canLaunchUrl(Uri.parse(content.documentUrl!))) {
        await launchUrl(Uri.parse(content.documentUrl!), mode: LaunchMode.externalApplication);
      }
    } else {
      // Show details dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(content.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content.description),
                if (content.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: content.tags.map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.grey.shade200,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
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
            Tab(text: 'FILES'),
          ],
        ),
      ),
      // TabBarView holds the content for each tab
      body: TabBarView(
        controller: _tabController,
        children: [
          // Videos tab
          _buildTabContent(contentType: 'video'),
          // Playlists tab
          _buildTabContent(contentType: 'playlist'),
        ],
      ),
    );
  }

  /// Builds the content layout for a single tab page.
  Widget _buildTabContent({required String contentType}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 20),
          // Content Grid
          Expanded(
            child: _buildContentGrid(contentType: contentType),
          ),
        ],
      ),
    );
  }

  /// Builds the styled search bar widget.
  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(25, 85, 41, 0.36),
            blurRadius: 2.8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, size: 18, color: Colors.black.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search videos and documents...',
                hintStyle: const TextStyle(
                  color: Color(0xFF959595),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// Builds the grid of content items.
  Widget _buildContentGrid({required String contentType}) {
    return StreamBuilder<List<AcademyContent>>(
      stream: FirebaseService.getAcademyContentStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final allContent = snapshot.data ?? [];
        
        // Filter content based on tab
        List<AcademyContent> filteredContent;
        if (contentType == 'playlist') {
          // Show documents in the FILES tab
          filteredContent = allContent.where((content) => 
            content.contentType == 'document' && _matchesSearch(content)
          ).toList();
        } else {
          // Show only videos in the VIDEOS tab
          filteredContent = allContent.where((content) => 
            content.contentType == 'video' && _matchesSearch(content)
          ).toList();
        }

        if (filteredContent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off : Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No content found matching your search'
                      : 'No content available yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredContent.length,
          itemBuilder: (context, index) {
            return _buildContentThumbnail(filteredContent[index]);
          },
        );
      },
    );
  }

  /// Builds a single content thumbnail.
  Widget _buildContentThumbnail(AcademyContent content) {
    return GestureDetector(
      onTap: () => _openContent(content),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail container
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.grey.shade400,
                      child: content.thumbnailUrl != null
                          ? Image.network(
                              content.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderThumbnail(content.contentType);
                              },
                            )
                          : _buildPlaceholderThumbnail(content.contentType),
                    ),
                    // Play icon overlay for videos, document icon for documents - properly centered
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(
                            content.contentType == 'video' ? Icons.play_arrow : Icons.description,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    // Share button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _shareContent(content),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title and description section
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        content.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail(String contentType) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
      ),
      child: Center(
        child: Icon(
          contentType == 'video' ? Icons.video_library : Icons.description,
          size: 48,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}