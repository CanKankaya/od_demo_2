import 'package:flutter/material.dart';

class CustomIconButton extends StatefulWidget {
  final AnimatedIconData icon;
  final Function? onPressed;
  final double? iconSize;
  final Color? iconColor;
  final Duration duration;

  const CustomIconButton({
    Key? key,
    this.icon = AnimatedIcons.play_pause,
    this.iconSize,
    this.iconColor,
    this.duration = const Duration(milliseconds: 500),
    required this.onPressed,
  }) : super(key: key);

  @override
  CustomIconButtonState createState() => CustomIconButtonState();
}

class CustomIconButtonState extends State<CustomIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    //** INFO: Bu Widget'a onPressed null atandığında animasyon çalışmaz,
    //* () {} atandığında animasyon çalışır
    //* Dolu fonksiyon atandığında animasyon ve fonksiyon çalışır

    return IconButton(
      iconSize: widget.iconSize,
      onPressed: widget.onPressed != null
          ? () {
              _handleOnPressed();
              widget.onPressed!();
            }
          : () {},
      icon: AnimatedIcon(
        icon: widget.icon,
        progress: _animationController,
        color: widget.iconColor,
        size: 26,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleOnPressed() {
    setState(() {
      isPlaying = !isPlaying;
      isPlaying ? _animationController.forward() : _animationController.reverse();
    });
  }
}
