import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PixabayPage(),
    );
  }
}

class PixabayPage extends StatefulWidget {
  const PixabayPage({super.key});

  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {
  List<PixabayImage> pixabayImages = [];
  // APIのkeyは環境変数設定
  final token = dotenv.env['ACCESS_TOKEN'];

  // APIを通して画像取得
  Future<void> fetchImages(String text) async {
    final response = await Dio().get(
      'https://pixabay.com/api',
      queryParameters: {
        'key': token,
        'q': text,
        'image_type': 'photo',
        'per_page': 100,
      },
    );

    final List hits = response.data['hits'];
    pixabayImages = hits.map(
      (e) {
        return PixabayImage.fromMap(e);
      },
    ).toList();
    setState(() {});
  }

  // 画像シェア
  Future<void> shareImage(String url) async {
    // 1.URLから画像をダウンロード
    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    // 2.ダウンロードしたデータをファイルに保存
    final dir = await getTemporaryDirectory();
    // 3.Shareパッケージを呼び出して共有
    final File imageFile =
        await File('${dir.path}/image.png').writeAsBytes(response.data);
    final file = XFile(imageFile.path);
    await Share.shareXFiles([file]);
  }

  @override
  void initState() {
    super.initState();
    // 最初に一度だけ
    fetchImages('花');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: TextFormField(
            initialValue: '花',
            decoration: const InputDecoration(
              fillColor: Colors.white,
              filled: true,
            ),
            onFieldSubmitted: (text) {
              fetchImages(text);
            },
          ),
        ),
        body: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemCount: pixabayImages.length,
            itemBuilder: (context, index) {
              final pixabayImage = pixabayImages[index];
              return InkWell(
                onTap: (() async {
                  shareImage(pixabayImage.webformatURL);
                }),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      pixabayImage.previewURL,
                      fit: BoxFit.cover,
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        color: Colors.white,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.thumb_up_alt_outlined,
                              size: 14,
                            ),
                            Text('${pixabayImage.likes}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }));
  }
}

class PixabayImage {
  final String webformatURL;
  final String previewURL;
  final int likes;

  PixabayImage({
    required this.webformatURL,
    required this.previewURL,
    required this.likes,
  });

  factory PixabayImage.fromMap(Map<String, dynamic> map) {
    return PixabayImage(
      webformatURL: map['webformatURL'],
      previewURL: map['previewURL'],
      likes: map['likes'],
    );
  }
}
