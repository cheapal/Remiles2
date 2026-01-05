import 'dart:async';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/models/chat_model.dart';
import 'package:remiles/models/offer_model.dart';
import 'package:provider/provider.dart';
import 'package:remiles/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum ConversationFilter {
  all,
  unread,
  loadRelated,
  productInquiry,
  withOffers,
  expired,
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatConversation> _allConversations = [];
  List<ChatConversation> _filteredConversations = [];
  Map<String, OfferModel?> _offerCache = {}; // Cache offers for expired check
  Map<String, String> _userNameCache = {}; // Cache user names
  Map<String, double?> _loadPriceCache = {}; // Cache load prices
  bool _isLoading = false;
  bool _hasLoadedInitial = false; // Track if initial load has been attempted
  ConversationFilter _selectedFilter = ConversationFilter.all;
  String _searchQuery = '';
  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isNavigating = false; // Prevent multiple simultaneous navigations
  StreamSubscription<List<ChatConversation>>? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // Start listening to conversations stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningToConversations();
    });
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _currentPage = 0;
      _applyFilters();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreConversations();
    }
  }

  void _startListeningToConversations({bool showLoading = true}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _allConversations = [];
          _isLoading = false;
          _hasLoadedInitial = true;
        });
      }
      return;
    }

    if (mounted && showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    // Cancel existing subscription if any
    _conversationsSubscription?.cancel();

    // Listen to real-time updates
    _conversationsSubscription =
        FirebaseService.getUserConversationsStream(user.uid).listen(
          (conversations) {
            // Load offers and preload user names and load prices in parallel
            Future.wait([
              _loadOffersForConversations(conversations),
              _preloadUserNames(conversations, user.uid),
              _preloadLoadPrices(conversations),
            ]).then((_) {
              if (mounted) {
                setState(() {
                  _allConversations = conversations;
                  _isLoading = false;
                  _hasLoadedInitial = true;
                });
                _applyFilters();
              }
            });
          },
          onError: (error) {
            print('Error listening to conversations: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasLoadedInitial = true;
              });
            }
          },
        );
  }

  Future<void> _refreshConversations() async {
    // Clear caches and reset pagination
    if (mounted) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _offerCache.clear();
        _userNameCache.clear();
        _loadPriceCache.clear();
      });
    }
    // Restart the stream to force a refresh (show loading on manual refresh)
    _startListeningToConversations(showLoading: true);
  }

  Future<void> _preloadUserNames(
    List<ChatConversation> conversations,
    String currentUserId,
  ) async {
    final userIdsToLoad = <String>{};

    for (final conversation in conversations) {
      final otherUserId = conversation.getOtherParticipant(currentUserId);
      if (otherUserId.isNotEmpty && !_userNameCache.containsKey(otherUserId)) {
        userIdsToLoad.add(otherUserId);
      }
    }

    // Load user names in parallel
    final nameFutures = userIdsToLoad.map((userId) async {
      try {
        final shipperDoc = await FirebaseService.shippers.doc(userId).get();
        if (shipperDoc.exists) {
          final data = shipperDoc.data() as Map<String, dynamic>?;
          final name =
              data?['companyName'] ??
              data?['displayName'] ??
              data?['name'] ??
              'Shipper';
          return MapEntry(userId, name);
        } else {
          final carrierDoc = await FirebaseService.carriers.doc(userId).get();
          if (carrierDoc.exists) {
            final data = carrierDoc.data() as Map<String, dynamic>?;
            final name =
                data?['companyName'] ?? data?['displayName'] ?? 'Carrier';
            return MapEntry(userId, name);
          }
        }
      } catch (e) {
        print('Error fetching user name for $userId: $e');
      }
      return MapEntry(userId, 'User');
    });

    final results = await Future.wait(nameFutures);
    for (final entry in results) {
      _userNameCache[entry.key] = entry.value;
    }
  }

  Future<void> _preloadLoadPrices(List<ChatConversation> conversations) async {
    final loadIdsToLoad = <String>{};

    for (final conversation in conversations) {
      if (conversation.loadId != null &&
          conversation.loadId!.isNotEmpty &&
          !_loadPriceCache.containsKey(conversation.loadId)) {
        loadIdsToLoad.add(conversation.loadId!);
      }
    }

    if (loadIdsToLoad.isEmpty) return;

    // Load all shippers once
    try {
      final shippersSnapshot = await FirebaseService.shippers.get();

      // Load all loads in parallel
      final loadFutures = loadIdsToLoad.map((loadId) async {
        for (final shipperDoc in shippersSnapshot.docs) {
          final loadDoc = await FirebaseService.shippers
              .doc(shipperDoc.id)
              .collection('loads')
              .doc(loadId)
              .get();
          if (loadDoc.exists) {
            final loadData = loadDoc.data();
            final price = (loadData?['price'] as num?)?.toDouble();
            return MapEntry(loadId, price);
          }
        }
        return MapEntry(loadId, null);
      });

      final results = await Future.wait(loadFutures);
      for (final entry in results) {
        _loadPriceCache[entry.key] = entry.value;
      }
    } catch (e) {
      print('Error preloading load prices: $e');
    }
  }

  Future<void> _loadOffersForConversations(
    List<ChatConversation> conversations,
  ) async {
    final offersToLoad = <String>{};

    for (final conversation in conversations) {
      if (conversation.lastMessage?.type == MessageType.offer &&
          conversation.lastMessage?.offerId != null) {
        offersToLoad.add(conversation.lastMessage!.offerId!);
      }
    }

    // Load offers in parallel
    final offerFutures = offersToLoad
        .where((offerId) => !_offerCache.containsKey(offerId))
        .map((offerId) async {
          final offer = await FirebaseService.getOfferById(offerId);
          return MapEntry(offerId, offer);
        });

    final offerResults = await Future.wait(offerFutures);

    for (final entry in offerResults) {
      _offerCache[entry.key] = entry.value;
    }
  }

  void _applyFilters() {
    List<ChatConversation> filtered = List.from(_allConversations);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conv) {
        final title = _getConversationTitle(conv).toLowerCase();
        final lastMessage = conv.lastMessage?.content.toLowerCase() ?? '';
        return title.contains(_searchQuery) ||
            lastMessage.contains(_searchQuery);
      }).toList();
    }

    // Apply filter type
    switch (_selectedFilter) {
      case ConversationFilter.unread:
        final userId = Provider.of<AuthProvider>(
          context,
          listen: false,
        ).currentUser?.uid;
        if (userId != null) {
          filtered = filtered
              .where((conv) => conv.unreadCount[userId] == true)
              .toList();
        }
        break;
      case ConversationFilter.loadRelated:
        filtered = filtered
            .where((conv) => conv.loadId != null && conv.loadId!.isNotEmpty)
            .toList();
        break;
      case ConversationFilter.productInquiry:
        filtered = filtered
            .where((conv) => conv.loadId == null || conv.loadId!.isEmpty)
            .toList();
        break;
      case ConversationFilter.withOffers:
        filtered = filtered
            .where(
              (conv) =>
                  conv.lastMessage?.type == MessageType.offer &&
                  conv.lastMessage?.offerId != null,
            )
            .toList();
        break;
      case ConversationFilter.expired:
        filtered = filtered.where((conv) {
          if (conv.lastMessage?.type == MessageType.offer &&
              conv.lastMessage?.offerId != null) {
            final offer = _offerCache[conv.lastMessage!.offerId];
            return offer != null && offer.isExpired;
          }
          return false;
        }).toList();
        break;
      case ConversationFilter.all:
        break;
    }

    setState(() {
      _filteredConversations = filtered;
    });
  }

  void _loadMoreConversations() {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _currentPage++;
    });
    // In this implementation, we're loading all at once and paginating client-side
    // For true pagination, you'd fetch more from Firebase here
  }

  List<ChatConversation> get _paginatedConversations {
    final endIndex = ((_currentPage + 1) * _itemsPerPage).clamp(
      0,
      _filteredConversations.length,
    );
    return _filteredConversations.sublist(0, endIndex);
  }

  bool get _hasMorePages =>
      _paginatedConversations.length < _filteredConversations.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopNavigationBar(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Messages',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterDialog,
                        tooltip: 'Filter',
                      ),
                      if (kIsWeb)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshConversations,
                          tooltip: 'Refresh',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshConversations,
                      child: _buildConversationsList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search conversations...',
        prefixIcon: Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildConversationsList() {
    // Show loading only if we're loading and haven't loaded initial data yet
    if (_isLoading && !_hasLoadedInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'User not logged in',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Don't load conversations in build method - it's already loaded in initState
    // Only show loading if initial load hasn't completed yet
    if (!_hasLoadedInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredConversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ||
                      _selectedFilter != ConversationFilter.all
                  ? 'No conversations match your filters'
                  : 'No conversations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Your conversations will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final paginated = _paginatedConversations;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: paginated.length + (_hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= paginated.length) {
          if (kIsWeb) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _loadMoreConversations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5B3D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Load More'),
                ),
              ),
            );
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final conversation = paginated[index];
        final otherUserId = conversation.getOtherParticipant(user.uid);

        if (otherUserId.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ConversationTile(
          conversation: conversation,
          otherUserId: otherUserId,
          currentUserId: user.uid,
          offerCache: _offerCache,
          onTap: _isNavigating
              ? null
              : () => _navigateToChat(conversation, otherUserId),
        );
      },
    );
  }

  Future<void> _navigateToChat(
    ChatConversation conversation,
    String otherUserId,
  ) async {
    // Prevent multiple simultaneous navigations
    if (_isNavigating) return;

    if (mounted) {
      setState(() {
        _isNavigating = true;
      });
    }

    try {
      // Get cached user name or use default
      String otherUserName = _userNameCache[otherUserId] ?? 'User';

      // Get cached load price or use null
      String? loadId = conversation.loadId;
      double? loadPrice = loadId != null ? _loadPriceCache[loadId] : null;

      // Navigate immediately - don't wait for any additional fetches
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              listingTitle: conversation.listingTitle,
              listingImageUrl: conversation.listingImageUrl,
              listingId: conversation.listingId,
              loadId: loadId,
              loadPrice: loadPrice,
            ),
          ),
        );
        // No need to manually refresh - stream will update automatically
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Conversations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ConversationFilter.values.map((filter) {
            return RadioListTile<ConversationFilter>(
              title: Text(_getFilterLabel(filter)),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                  _currentPage = 0;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getFilterLabel(ConversationFilter filter) {
    switch (filter) {
      case ConversationFilter.all:
        return 'All Conversations';
      case ConversationFilter.unread:
        return 'Unread';
      case ConversationFilter.loadRelated:
        return 'Load Related';
      case ConversationFilter.productInquiry:
        return 'Product Inquiry';
      case ConversationFilter.withOffers:
        return 'With Offers';
      case ConversationFilter.expired:
        return 'Expired Offers';
    }
  }

  String _getConversationTitle(ChatConversation conversation) {
    if (conversation.loadId != null && conversation.loadId!.isNotEmpty) {
      return 'Load #${conversation.loadId!.substring(0, 8)}';
    }
    return conversation.listingTitle ?? 'Product Inquiry';
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final String otherUserId;
  final String currentUserId;
  final Map<String, OfferModel?> offerCache;
  final VoidCallback? onTap;

  const _ConversationTile({
    required this.conversation,
    required this.otherUserId,
    required this.currentUserId,
    required this.offerCache,
    this.onTap,
  });

  String _getLastMessageText() {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) return 'No messages yet';

    // Check if it's an offer message and if the offer is expired
    if (lastMessage.type == MessageType.offer && lastMessage.offerId != null) {
      final offer = offerCache[lastMessage.offerId];
      if (offer != null && offer.isExpired) {
        return 'Offer expired';
      }
      // Return the original content if not expired
      return lastMessage.content;
    }

    return lastMessage.content;
  }

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Color(0xFF1E5B3D);
    const Color hintColor = Colors.grey;

    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      dense: true,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: iconColor,
        child: Text(
          _getConversationInitial(conversation),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        _getConversationTitle(conversation),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _getLastMessageText(),
        style: const TextStyle(color: hintColor, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.lastMessage != null)
              Text(
                _formatTime(conversation.lastMessage!.timestamp),
                style: const TextStyle(color: hintColor, fontSize: 12),
              ),
            if (conversation.unreadCount[currentUserId] == true) ...[
              const SizedBox(height: 4),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getConversationTitle(ChatConversation conversation) {
    // If it's a load conversation, show load number
    if (conversation.loadId != null && conversation.loadId!.isNotEmpty) {
      return 'Load #${conversation.loadId!.substring(0, 8)}';
    }
    // Otherwise show listing title or default
    return conversation.listingTitle ?? 'Product Inquiry';
  }

  String _getConversationInitial(ChatConversation conversation) {
    // If it's a load conversation, show "L" for Load
    if (conversation.loadId != null && conversation.loadId!.isNotEmpty) {
      return 'L';
    }
    // Otherwise show first letter of listing title or "U" for User
    return conversation.listingTitle?.substring(0, 1).toUpperCase() ?? 'U';
  }
}
