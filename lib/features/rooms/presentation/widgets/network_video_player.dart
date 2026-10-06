import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class NetworkVideoPlayer extends StatefulWidget {
  const NetworkVideoPlayer({required this.url, super.key});

  final String url;

  @override
  State<NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<NetworkVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didUpdateWidget(covariant NetworkVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _initialize();
  }

  Future<void> _initialize() async {
    final previous = _controller;
    _controller = null;
    _error = null;
    if (mounted) setState(() {});
    await previous?.dispose();

    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) setState(() => _error = const FormatException());
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    controller.addListener(_onPlayerChanged);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (mounted && identical(_controller, controller)) setState(() {});
    } catch (error) {
      if (mounted && identical(_controller, controller)) {
        setState(() => _error = error);
      }
    }
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    controller?.removeListener(_onPlayerChanged);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: _error != null
              ? const _VideoError()
              : controller == null || !controller.value.isInitialized
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio > 0
                            ? controller.value.aspectRatio
                            : 16 / 9,
                        child: VideoPlayer(controller),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          controller.value.isPlaying
                              ? controller.pause()
                              : controller.play();
                        },
                        child: AnimatedOpacity(
                          opacity: controller.value.isPlaying ? 0 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: const Center(
                            child: CircleAvatar(
                              radius: 27,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.only(top: 18),
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF00A884),
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 38),
          SizedBox(height: 8),
          Text(
            'Không thể phát video này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}
