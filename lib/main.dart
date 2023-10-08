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
  List hits = [];
  // APIのkeyは環境変数設定
  final token = dotenv.env['ACCESS_TOKEN'];

  Future<void> fetchImages(String text) async {
    Response response = await Dio().get(
        'https://pixabay.com/api/?key=$token&q=$text月&image_type=photo&pretty=true&per_page=100');
    hits = response.data['hits'];
    setState(() {});
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
            itemCount: hits.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> hit = hits[index];
              return InkWell(
                onTap: (() async {
                  // 1.URLから画像をダウンロード
                  Response response = await Dio().get(
                    hit['webformatURL'],
                    options: Options(responseType: ResponseType.bytes),
                  );
                  // 2.ダウンロードしたデータをファイルに保存
                  Directory dir = await getTemporaryDirectory();
                  // 3.Shareパッケージを呼び出して共有
                  final File imageFile = await File('${dir.path}/image.png')
                      .writeAsBytes(response.data);
                  XFile file = XFile(imageFile.path);
                  await Share.shareXFiles([file]);
                }),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      hit['previewURL'],
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
                            Text('${hit['likes']}'),
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
