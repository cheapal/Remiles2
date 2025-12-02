/// Simple utility to track the currently open conversation ID
/// This is used to determine if we should suppress notifications for messages
/// in the currently open conversation
class ConversationTracker {
  static String? _currentConversationId;

  /// Get the currently open conversation ID
  static String? get currentConversationId => _currentConversationId;

  /// Set the currently open conversation ID
  static void setCurrentConversation(String? conversationId) {
    _currentConversationId = conversationId;
  }

  /// Check if a conversation is currently open
  static bool isConversationOpen(String conversationId) {
    return _currentConversationId == conversationId;
  }

  /// Clear the current conversation (when chat screen is closed)
  static void clearCurrentConversation() {
    _currentConversationId = null;
  }
}
