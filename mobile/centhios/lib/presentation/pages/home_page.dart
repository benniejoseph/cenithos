import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // _controller = WebViewController()
    //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //   ..setBackgroundColor(const Color(0x00000000))
    //   ..loadRequest(Uri.parse(
    //       'https://my.spline.design/hypercasualcharacters-39c5b19199a117b34e6c31046774618a/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spatial Finance PoC')),
      // body: WebViewWidget(controller: _controller),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'The Spatial Finance PoC is temporarily disabled due to a rendering issue.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
