import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thunder/core/enums/media_type.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/core/theme/bloc/theme_bloc.dart';
import 'package:thunder/shared/image_viewer.dart';
import 'package:thunder/shared/link_preview_card.dart';
import 'package:thunder/shared/webview.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:lemmy/lemmy.dart';

class MediaView extends StatelessWidget {
  final Post? post;
  final PostViewMedia? postView;
  final bool showFullHeightImages;
  final bool hideNsfwPreviews;

  const MediaView({super.key, this.post, this.postView, this.showFullHeightImages = true, required this.hideNsfwPreviews});

  @override
  Widget build(BuildContext context) {
    if (postView == null || postView!.media.isEmpty) return Container();

    if (postView!.media.firstOrNull?.mediaType == MediaType.link) {
      return LinkPreviewCard(
        originURL: postView!.media.first.originalUrl,
        mediaURL: postView!.media.first.mediaUrl,
        mediaHeight: postView!.media.first.height,
        mediaWidth: postView!.media.first.width,
        showFullHeightImages: showFullHeightImages,
      );
    }

    bool hideNsfw = hideNsfwPreviews && (postView?.post.nsfw ?? true);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageViewer(url: postView!.media.first.mediaUrl!),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              hideNsfw ? ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: previewImage(context)) : previewImage(context),
              if (hideNsfw)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    children: [
                      Icon(Icons.warning_rounded, size: 55),
                      Text("NSFW - Tap to unhide", textScaleFactor: 1.5),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget previewImage(BuildContext context) {
    final theme = Theme.of(context);
    final useDarkTheme = context.read<ThemeBloc>().state.useDarkTheme;

    return CachedNetworkImage(
      imageUrl: postView!.media.first.mediaUrl!,
      height: showFullHeightImages ? postView!.media.first.height : 150,
      width: postView!.media.first.width ?? MediaQuery.of(context).size.width - 24,
      memCacheWidth: (postView!.media.first.width ?? (MediaQuery.of(context).size.width - 24) * MediaQuery.of(context).devicePixelRatio).toInt(),
      fit: BoxFit.fitWidth,
      progressIndicatorBuilder: (context, url, downloadProgress) => Container(
        color: useDarkTheme ? Colors.grey.shade900 : Colors.grey.shade300,
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(value: downloadProgress.progress),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: useDarkTheme ? Colors.grey.shade900 : Colors.grey.shade300,
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
          child: InkWell(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6), // Image border
              child: Stack(
                alignment: Alignment.bottomRight,
                fit: StackFit.passthrough,
                children: [
                  Container(
                    color: Colors.grey.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.link,
                            color: Colors.white60,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            post?.url ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              if (post?.url != null) Navigator.of(context).push(MaterialPageRoute(builder: (context) => WebView(url: post!.url!)));
            },
          ),
        ),
      ),
    );
  }
}
