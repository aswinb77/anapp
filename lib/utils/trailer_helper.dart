import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TrailerHelper {
  /// Shows trailer inline on Web, opens YouTube app on Android/iOS
  static void showTrailer(BuildContext context, String videoId) {
    if (kIsWeb) {
      _showInlinePlayer(context, videoId);
    } else {
      _openYouTubeApp(context, videoId);
    }
  }

  static void _showInlinePlayer(BuildContext context, String videoId) {
    final ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        mute: false,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: YoutubePlayerScaffold(
            controller: ytController,
            aspectRatio: 16 / 9,
            builder: (context, player) => player,
          ),
        ),
      ),
    );
  }

  static Future<void> _openYouTubeApp(BuildContext context, String videoId) async {
    // Try YouTube app first, fall back to browser
    final appUrl = Uri.parse('vnd.youtube:$videoId');
    final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open YouTube')),
        );
      }
    }
  }
}
