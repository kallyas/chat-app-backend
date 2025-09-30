import 'package:intl/intl.dart';

class Formatters {
  // Date and time formatters
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');
  static final DateFormat _chatTimeFormat = DateFormat('HH:mm');
  static final DateFormat _chatDateFormat = DateFormat('MMM dd');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM dd, yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM');

  // Format date for display
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  // Format time for display
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  // Format date and time for display
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  // Format time for chat messages
  static String formatChatTime(DateTime time) {
    return _chatTimeFormat.format(time);
  }

  // Format date for chat messages
  static String formatChatDate(DateTime date) {
    return _chatDateFormat.format(date);
  }

  // Format full date for headers
  static String formatFullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  // Format month and year
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  // Format day and month
  static String formatDayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  // Format relative time (time ago)
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '${minutes}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours}h ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${days}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  // Format last seen text
  static String formatLastSeen(DateTime? lastSeen, bool isOnline) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Last seen ${formatDate(lastSeen)}';
    }
  }

  // Format message time for chat
  static String formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);

    if (messageDate == today) {
      return formatChatTime(messageTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${formatChatTime(messageTime)}';
    } else if (messageTime.year == now.year) {
      return '${formatDayMonth(messageTime)} ${formatChatTime(messageTime)}';
    } else {
      return '${formatDate(messageTime)} ${formatChatTime(messageTime)}';
    }
  }

  // Format message date header
  static String formatMessageDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return formatDayMonth(date);
    } else {
      return formatDate(date);
    }
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    String formattedSize;
    if (size < 10) {
      formattedSize = size.toStringAsFixed(1);
    } else {
      formattedSize = size.toStringAsFixed(0);
    }
    
    return '$formattedSize ${suffixes[i]}';
  }

  // Format number with commas
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  // Format count (e.g., for unread messages)
  static String formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  // Format percentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Format duration
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
    } else {
      return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
    }
  }

  // Format typing indicator text
  static String formatTypingIndicator(List<String> typingUsers) {
    if (typingUsers.isEmpty) return '';
    
    if (typingUsers.length == 1) {
      return '${typingUsers.first} is typing...';
    } else if (typingUsers.length == 2) {
      return '${typingUsers.first} and ${typingUsers.last} are typing...';
    } else {
      return '${typingUsers.first} and ${typingUsers.length - 1} others are typing...';
    }
  }

  // Format chat room participants
  static String formatParticipants(List<String> participants, String currentUserId) {
    final otherParticipants = participants.where((id) => id != currentUserId).toList();
    
    if (otherParticipants.isEmpty) {
      return 'Just you';
    } else if (otherParticipants.length == 1) {
      return '1 other person';
    } else {
      return '${otherParticipants.length} other people';
    }
  }

  // Format online status count
  static String formatOnlineCount(int onlineCount, int totalCount) {
    if (onlineCount == 0) {
      return 'Nobody online';
    } else if (onlineCount == 1) {
      return '1 person online';
    } else {
      return '$onlineCount people online';
    }
  }

  // Format phone number
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length == 10) {
      // US format: (123) 456-7890
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      // US format with country code: +1 (123) 456-7890
      return '+1 (${digitsOnly.substring(1, 4)}) ${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}';
    } else {
      // International format: +XX XXXX XXXX
      return '+$digitsOnly';
    }
  }

  // Format URL for display
  static String formatUrlForDisplay(String url) {
    return url.replaceFirst(RegExp(r'^https?://'), '');
  }

  // Format email for display (hide part of email)
  static String formatEmailForDisplay(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 3) {
      return email;
    }
    
    final hiddenPart = '*' * (username.length - 2);
    return '${username.substring(0, 1)}$hiddenPart${username.substring(username.length - 1)}@$domain';
  }

  // Format currency
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // Format initials from name
  static String formatInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    
    if (words.isEmpty) return '';
    
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }

  // Format name for display (First Last)
  static String formatName(String firstName, String lastName) {
    final first = firstName.trim();
    final last = lastName.trim();
    
    if (first.isEmpty && last.isEmpty) {
      return 'Unknown User';
    } else if (first.isEmpty) {
      return last;
    } else if (last.isEmpty) {
      return first;
    } else {
      return '$first $last';
    }
  }

  // Format username with @ symbol
  static String formatUsername(String username) {
    return '@$username';
  }

  // Format message preview for notifications
  static String formatMessagePreview(String content, {int maxLength = 50}) {
    if (content.length <= maxLength) {
      return content;
    }
    
    return '${content.substring(0, maxLength)}...';
  }

  // Format search query for highlighting
  static String formatSearchQuery(String query) {
    return query.trim().toLowerCase();
  }

  // Format version number
  static String formatVersion(String version) {
    return 'v$version';
  }

  // Format boolean to Yes/No
  static String formatBoolean(bool value) {
    return value ? 'Yes' : 'No';
  }

  // Format list to comma-separated string
  static String formatList(List<String> items, {String separator = ', ', String lastSeparator = ' and '}) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items.first}$lastSeparator${items.last}';
    
    final allButLast = items.sublist(0, items.length - 1).join(separator);
    return '$allButLast$lastSeparator${items.last}';
  }

  // Format title case
  static String formatTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Format sentence case
  static String formatSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Format error message
  static String formatErrorMessage(String error) {
    // Remove technical details and make user-friendly
    if (error.contains('SocketException')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (error.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('FormatException')) {
      return 'Data format error. Please try again.';
    } else {
      return error;
    }
  }
}