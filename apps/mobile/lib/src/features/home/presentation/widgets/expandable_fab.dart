import 'package:flutter/material.dart';

/// An expandable FAB that shows child action buttons when expanded.
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.children,
  });

  final List<FabAction> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 280,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Expanded action buttons
          ..._buildExpandedActions(),
          // Main FAB
          FloatingActionButton(
            heroTag: 'expandable_fab',
            onPressed: _toggle,
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandedActions() {
    final actions = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      final action = widget.children[i];
      actions.add(
        _ExpandingAction(
          index: i,
          animation: _expandAnimation,
          action: action,
          onPressed: () {
            _toggle();
            action.onPressed();
          },
        ),
      );
    }
    return actions;
  }
}

class _ExpandingAction extends AnimatedWidget {
  const _ExpandingAction({
    required this.index,
    required Animation<double> animation,
    required this.action,
    required this.onPressed,
  }) : super(listenable: animation);

  final int index;
  final FabAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final offset = (index + 1) * 60.0;
    return Positioned(
      bottom: offset * animation.value,
      right: 0,
      child: IgnorePointer(
        ignoring: animation.value == 0,
        child: FadeTransition(
          opacity: animation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    action.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'fab_action_$index',
                onPressed: onPressed,
                child: Icon(action.icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single action in the expandable FAB.
class FabAction {
  const FabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}
