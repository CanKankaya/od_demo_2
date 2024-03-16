import 'dart:math' as math;
import 'package:flutter/material.dart';

class CustomExpandableFab extends StatefulWidget {
  const CustomExpandableFab({
    super.key,
    this.initialOpen = false,
    required this.distance,
    required this.secondaryDistance,
    required this.children,
    this.step = 90,
    this.alignment = Alignment.bottomLeft,
  });

  final bool initialOpen;
  final double distance;
  final double secondaryDistance;
  final List<ActionButton> children;
  final double step;
  final Alignment alignment;

  @override
  State<CustomExpandableFab> createState() => _CustomExpandableFabState();
}

class _CustomExpandableFabState extends State<CustomExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;
  double turns = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialOpen) {
      _open = true;
      // mapService.toggleFab();
    }

    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.elasticInOut,
      reverseCurve: Curves.elasticInOut,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      turns += 4.0 / 8.0;
      _open = !_open;
      // mapService.toggleFab();
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.only(left: 32.0, bottom: 16),
        child: Stack(
          //**Change the main Fab location here */
          alignment: widget.alignment,
          //** */
          clipBehavior: Clip.none,
          children: [
            _buildTapToCloseFab(),
            ..._buildExpandingActionButtons(),
            _buildTapToOpenFab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: _toggle,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final primaryList = widget.children.where((element) => !element.isSecondary).toList();
    final secondaryList = widget.children.where((element) => element.isSecondary).toList();
    final bigCount = primaryList.length;
    final smallCount = secondaryList.length;

    var step = widget.step / (bigCount - 1);
    for (var i = 0, angleInDegrees = 0.0; i < bigCount; i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: primaryList[i],
        ),
      );
    }

    step = widget.step / (smallCount - 1);
    for (var i = 0, angleInDegrees = 0.0; i < smallCount; i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.secondaryDistance,
          progress: _expandAnimation,
          child: secondaryList[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 650),
        curve: const Interval(0.0, 0.5, curve: Curves.linear),
        child: AnimatedOpacity(
          opacity: _open ? 1.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 650),
          child: FloatingActionButton(
            backgroundColor: Colors.lightBlue,
            onPressed: _toggle,
            child: AnimatedRotation(
              turns: turns,
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticInOut,
              child: const Icon(
                Icons.settings,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          //**Change the action buttons location here */
          left: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          //** */
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.backgroundColor = Colors.black,
    this.isSecondary = false,
    this.size,
  });

  final double? size;
  final VoidCallback? onPressed;
  final Widget icon;
  final Color backgroundColor;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: backgroundColor,
      elevation: 4.0,
      child: IconButton(
        iconSize: size,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}
