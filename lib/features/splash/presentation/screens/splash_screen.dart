import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isInit = false;
  bool _hasCalledFinish = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/splash.mp4');
      await _controller.initialize();
      _controller.setVolume(0.0);

      if (mounted) {
        setState(() {
          _isInit = true;
        });
        _controller.play();
      }

      _controller.addListener(_checkVideoProgress);
    } catch (e) {
      debugPrint("Error loading splash video: $e");
      _triggerFinish();
    }
  }

  void _checkVideoProgress() {
    if (!_controller.value.isInitialized) return;

    // Check if video is finished
    // We add a small buffer or check if strictly greater/equal
    if (_controller.value.position >= _controller.value.duration) {
      _triggerFinish();
    }
  }

  void _triggerFinish() {
    if (_hasCalledFinish) return;
    _hasCalledFinish = true;
    _controller.removeListener(_checkVideoProgress); // Stop listening
    widget.onFinish();
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show white background (or brand color) while initializing to avoid glitch
    if (!_isInit) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: 150,
            height: 150,
            child: Image.asset('assets/icons/icon_no_bg.png'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
