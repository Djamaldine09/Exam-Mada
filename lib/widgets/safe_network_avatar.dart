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
    if (widget.imageUrl == null || _imageLoadFailed) {
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

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      child: ClipOval(
        child: Image.network(
          widget.imageUrl!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _imageLoadFailed = true);
                }
              });
            }
            return Icon(
              widget.fallbackIcon,
              color: widget.fallbackIconColor,
              size: widget.fallbackIconSize,
            );
          },
        ),
      ),
    );
  }
}
