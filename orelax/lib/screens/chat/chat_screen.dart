import 'package:flutter/material.dart';
import 'individual_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  bool _isSearchExpanded = false;
  late AnimationController _staggeredController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> stories = [
    {'name': 'Your Story', 'hasStory': false},
    {'name': 'Sarah', 'hasStory': true, 'color': Colors.amber},
    {'name': 'Chaima', 'hasStory': true, 'color': Colors.blue},
    {'name': 'darine', 'hasStory': true, 'color': Colors.purple},
    {'name': 'melissa', 'hasStory': true, 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> chats = [
    {
      'name': 'Sarah ammari',
      'message': 'Are we still meeting at the clubhouse?',
      'time': '12:07',
      'unread': 2,
      'isOnline': true,
    },
    {
      'name': 'darine khelifa',
      'message': 'Thanks for the help! 🙏',
      'time': '10:42',
      'unread': 0,
      'isOnline': true,
    },
    {
      'name': 'Neighborhood Watch',
      'message': 'Update on the gate security...',
      'time': 'Yesterday',
      'unread': 5,
      'isOnline': false,
    },
    {
      'name': 'melissa zerizer',
      'message': 'See you soon.',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
    },
    {
      'name': 'sabrina ',
      'message': 'its been while we didnt talk .',
      'time': 'Mon',
      'unread': 0,
      'isOnline': false,
    },
     {
      'name': 'sonia ',
      'message': 'Are we still meeting at the clubhouse?',
      'time': '12:07',
      'unread': 2,
      'isOnline': true,
    },
     {
      'name': 'Chaima ',
      'message': ' come with us for the iftar ',
      'time': '10:07',
      'unread': 1,
      'isOnline': false ,
    },
     {
      'name': 'Radia kh ',
      'message': 'how are you ',
      'time': '12:07',
      'unread': 1,
      'isOnline': true,
    },

  ];

  @override
  void initState() {
    super.initState();
    _staggeredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: _isSearchExpanded
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          _isSearchExpanded = false;
                          _searchController.clear();
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              )
            : const Text(
                'Chat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Color(0xFF1A5C2A), // App theme green
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (!_isSearchExpanded)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _isSearchExpanded = true;
                });
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF81C784), Color(0xFF1A5C2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A5C2A).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.edit_square, color: Colors.white, size: 20),
          label: const Text(
            'New Chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active Stories ──
          Container(
            height: 115,
            padding: const EdgeInsets.only(top: 10.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: stories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF81C784), Color(0xFF1A5C2A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your Story',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final story = stories[index];
                final bool hasStory = story['hasStory'] ?? false;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(hasStory ? 3 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasStory 
                            ? const SweepGradient(
                                colors: [
                                  Colors.red,
                                  Colors.orange,
                                  Colors.yellow,
                                  Colors.green,
                                  Colors.blue,
                                  Colors.purple,
                                  Colors.red,
                                ],
                              )
                            : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white, 
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: story['color'] ?? Colors.grey.shade200,
                            child: const Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Chat List ──
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                
                // Calculate slide animation staggered per item
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _staggeredController,
                    curve: Interval(
                      (index / chats.length) * 0.5,
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                );

                final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _staggeredController,
                    curve: Interval(
                      (index / chats.length) * 0.5,
                      1.0,
                      curve: Curves.easeIn,
                    ),
                  ),
                );

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: _ChatListItem(
                      chat: chat,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom stateful widget to handle local tap animations and pulsing
class _ChatListItem extends StatefulWidget {
  final Map<String, dynamic> chat;

  const _ChatListItem({required this.chat});

  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Pulse animation for online dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Tap scale animation
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_tapController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _tapController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _tapController.reverse();
    _navigate();
  }

  void _onTapCancel() {
    _tapController.reverse();
  }

  void _navigate() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            IndividualChatScreen(contactName: widget.chat['name']),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Null safety fixes applied
    final bool isOnline = widget.chat['isOnline'] ?? false;
    final int unread = widget.chat['unread'] ?? 0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dismissible(
          key: ValueKey(widget.chat['name']),
          background: _buildActionBg(Colors.blue.shade400, Icons.volume_off, Alignment.centerLeft),
          secondaryBackground: _buildActionBg(Colors.red.shade400, Icons.delete_outline, Alignment.centerRight),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar with Hero and Green Glow
                  Hero(
                    tag: 'avatar_${widget.chat['name']}',
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isOnline ? 2 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isOnline
                                ? Border.all(color: const Color(0xFF1A5C2A), width: 2)
                                : null,
                            boxShadow: isOnline
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1A5C2A).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(Icons.person, color: Colors.grey, size: 30),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 0.8 + (_pulseController.value * 0.4),
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.shade400,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(0.6),
                                          blurRadius: 6 * _pulseController.value,
                                          spreadRadius: 3 * _pulseController.value,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chat['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (widget.chat['message'] == null || widget.chat['message'].isEmpty)
                              ? 'Say hi! 👋' 
                              : widget.chat['message'],
                          style: TextStyle(
                            color: unread > 0 ? Colors.black87 : Colors.grey.shade600,
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),

                  // Trailing Info (Time + Badge) wrapped in ConstrainedBox to fix overflow
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // Fixes bottom overflow 
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.chat['time'],
                          style: TextStyle(
                            color: unread > 0 ? const Color(0xFF1A5C2A) : Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (unread > 0)
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF81C784), Color(0xFF1A5C2A)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBg(Color color, IconData icon, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: EdgeInsets.only(
        left: alignment == Alignment.centerLeft ? 24 : 0,
        right: alignment == Alignment.centerRight ? 24 : 0,
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
