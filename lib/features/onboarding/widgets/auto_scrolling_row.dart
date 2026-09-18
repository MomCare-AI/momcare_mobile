import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AutoScrollingRow extends StatefulWidget {
  const AutoScrollingRow({
    super.key,
    required this.children,
    this.scrollLeft = true,
    this.speed = 35.0,
  });

  final List<Widget> children;
  final bool scrollLeft;
  final double speed;

  @override
  State<AutoScrollingRow> createState() => _AutoScrollingRowState();
}

class _AutoScrollingRowState extends State<AutoScrollingRow>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ScrollController _scrollController = ScrollController();
  // Start at a large offset so we can infinitely scroll left or right
  double _currentScroll = 50000.0;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!_scrollController.hasClients) return;
      final delta = elapsed - _lastElapsed;
      _lastElapsed = elapsed;
      final distance = (delta.inMilliseconds / 1000.0) * widget.speed;

      if (widget.scrollLeft) {
        _currentScroll += distance;
      } else {
        _currentScroll -= distance;
      }

      _scrollController.jumpTo(_currentScroll);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_currentScroll);
        _ticker.start();
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 52, // Fixed height to bound the horizontal ListView
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            // Modulo to repeat the children infinitely
            final childIndex = index % widget.children.length;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: widget.children[childIndex],
            );
          },
        ),
      ),
    );
  }
}
