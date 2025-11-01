import 'dart:async';
import 'package:flutter/material.dart';

class NegotiationTimer extends StatefulWidget {
  final DateTime? expiresAt;
  final bool isExpired;

  const NegotiationTimer({
    super.key,
    this.expiresAt,
    this.isExpired = false,
  });

  @override
  State<NegotiationTimer> createState() => _NegotiationTimerState();
}

class _NegotiationTimerState extends State<NegotiationTimer> {
  Timer? _timer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(NegotiationTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt || oldWidget.isExpired != widget.isExpired) {
      _updateTimeRemaining();
      _startTimer();
    }
  }

  void _updateTimeRemaining() {
    if (widget.isExpired || widget.expiresAt == null) {
      _timeRemaining = Duration.zero;
      return;
    }

    final now = DateTime.now();
    if (now.isAfter(widget.expiresAt!)) {
      _timeRemaining = Duration.zero;
    } else {
      _timeRemaining = widget.expiresAt!.difference(now);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    
    if (widget.isExpired || widget.expiresAt == null) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTimeRemaining();
          if (_timeRemaining == null || _timeRemaining!.inSeconds <= 0) {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getTimerColor() {
    if (widget.isExpired || _timeRemaining == null || _timeRemaining!.inSeconds <= 0) {
      return Colors.red;
    }

    final totalMinutes = _timeRemaining!.inMinutes;
    if (totalMinutes <= 5) {
      return Colors.red;
    } else if (totalMinutes <= 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.isExpired || 
                     (_timeRemaining != null && _timeRemaining!.inSeconds <= 0);

    final timerColor = _getTimerColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade50 : timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpired ? Colors.red : timerColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            size: 18,
            color: timerColor,
          ),
          const SizedBox(width: 8),
          Text(
            isExpired 
                ? 'Negotiation Expired'
                : 'Time Remaining: ${_formatDuration(_timeRemaining ?? Duration.zero)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: timerColor,
            ),
          ),
        ],
      ),
    );
  }
}

