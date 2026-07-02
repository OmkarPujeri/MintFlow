import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Reusable Youtube Player widget using the official IFrame API for Flutter Web.
class YoutubePlayerWidget extends StatefulWidget {
  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    this.aspectRatio = 16 / 9,
  });

  final String videoId;
  final double aspectRatio;

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant YoutubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      if (widget.videoId.isNotEmpty) {
        _controller.loadVideoById(videoId: widget.videoId);
      } else {
        _controller.stopVideo();
      }
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId.isEmpty) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Text(
          'No video ID provided',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: widget.aspectRatio,
    );
  }
}
