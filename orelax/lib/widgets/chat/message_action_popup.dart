import 'package:flutter/material.dart';

enum MessageActionType {
  edit,
  deleteForMe,
  deleteForEveryone,
}

class MessageActionPopup extends StatelessWidget {
  final bool isOwnMessage;
  final Widget child;
  final ValueChanged<MessageActionType> onSelected;

  const MessageActionPopup({
    super.key,
    required this.isOwnMessage,
    required this.child,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MessageActionType>(
      tooltip: '',
      offset: const Offset(0, 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onSelected,
      itemBuilder: (context) {
        final items = <PopupMenuEntry<MessageActionType>>[];
        if (isOwnMessage) {
          items.add(
            const PopupMenuItem<MessageActionType>(
              value: MessageActionType.edit,
              child: Text('Edit'),
            ),
          );
          items.add(
            const PopupMenuItem<MessageActionType>(
              value: MessageActionType.deleteForMe,
              child: Text('Delete for me'),
            ),
          );
          items.add(
            const PopupMenuItem<MessageActionType>(
              value: MessageActionType.deleteForEveryone,
              child: Text('Delete for everyone'),
            ),
          );
        } else {
          items.add(
            const PopupMenuItem<MessageActionType>(
              value: MessageActionType.deleteForMe,
              child: Text('Delete for me'),
            ),
          );
        }
        return items;
      },
      child: child,
    );
  }
}