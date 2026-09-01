import 'package:flutter/material.dart';

/// A safe CircleAvatar wrapper that handles network image loading errors gracefully.
/// If the image fails to load (e.g., 404), it displays a fallback icon instead of throwing exceptions.
class SafeNetworkAvatar extends StatefulWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final double fallbackIconSize;

  const SafeNetworkAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.backgroundColor,
    required this.fallbackIcon,
    this.fallbackIconColor,
    required this.fallbackIconSize,
  });

  @override
  State<SafeNetworkAvatar> createState() => _SafeNetworkAvatarState();
}

class _SafeNetworkAvatarState extends State<SafeNetworkAvatar> {
  bool _imageLoadFailed = false;

  @override
  Widget build(BuildContext context) {
    // If no URL, show fallback icon immediately
    if (widget.imageUrl == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor,
        child: Icon(
          widget.fallbackIcon,
          color: widget.fallbackIconColor,
          size: widget.fallbackIconSize,
        ),
      );
    }

    // If image already failed, show fallback
    if (_imageLoadFailed) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor,
        child: Icon(
          widget.fallbackIcon,
          color: widget.fallbackIconColor,
          size: widget.fallbackIconSize,
        ),
      );
    }

    // Try to load the network image with error callback
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: NetworkImage(widget.imageUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        // Silently mark as failed - don't re-throw
        if (mounted) {
          setState(() => _imageLoadFailed = true);
        }
      },
      child: _imageLoadFailed
          ? Icon(
              widget.fallbackIcon,
              color: widget.fallbackIconColor,
              size: widget.fallbackIconSize,
            )
          : null,
    );
  }
}
