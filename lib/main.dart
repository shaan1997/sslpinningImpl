import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medium_ssl_pinning/model/article.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/io_client.dart';
import 'package:medium_ssl_pinning/service/news_api_service.dart';

// Future<SecurityContext> get globalContext async {
//   final sslCert = await rootBundle.load('assets/api_certificate.cer');
//   SecurityContext securityContext = SecurityContext(withTrustedRoots: false);
//   securityContext.setTrustedCertificatesBytes(sslCert.buffer.asInt8List());
//   return securityContext;
// }

/*Future<http.Client> getSSLPinningClient() async {
  HttpClient client = HttpClient(context: await globalContext);
  client.badCertificateCallback =
      (X509Certificate cert, String host, int port) => false;
  IOClient ioClient = IOClient(client);
  return ioClient;
}*/

 getSSLPinningClient(dio,cert,certificate256) async {
   SecurityContext securityContext = SecurityContext(withTrustedRoots: false);
   securityContext.setTrustedCertificatesBytes(cert.buffer.asInt8List());
  dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
    final client = HttpClient(
      context: securityContext,
    );
    // You can test the intermediate / root cert here. We just ignore it.
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  },
    validateCertificate: (certtificate, host, port){
        if(certtificate == null){
          return false;
        }
        final parseCert = sha256.convert(certtificate.der).toString();
        print('validate cetificate:$parseCert');
        print(certificate256);
        if(certificate256 == parseCert){
          return true;
        }
        return false;
    }
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sslCert = await rootBundle.load('assets/api_certificate.cer');
  const certificateFingerPrint = 'e4306fb390c3df7a749ab7a82d1f786f302555453d7dd90467c1fe900f0c8055';
  final dio = Dio();
   getSSLPinningClient(dio,sslCert,certificateFingerPrint);
  //final client = await getSSLPinningClient(dio);

  final apiService = NewsApiService(dio);

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final NewsApiService apiService;
  const MyApp({super.key, required this.apiService});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App SSL Pinning',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('News App SSL Pinning'),
        ),
        body: FutureBuilder<List<Article>>(
          future: apiService.fetchArticle(),
          builder:
              (BuildContext context, AsyncSnapshot<List<Article>> snapshot) {
            if(snapshot.hasError){
              if(snapshot.error is BadCertificateError){
                final error = snapshot.error as BadCertificateError;
                return Center(
                  child: Text('${error.message}'),
                );
              }
              else{
                return Center(
                  child: Text('${snapshot.error}'),
                );
              }
            }
            if (snapshot.data != null) {
              return ListView.builder(
                itemBuilder: (context, index) {
                  final article = snapshot.data![index];
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(article.description),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: snapshot.data?.length,
              );
            } else {
              return Center(
                child: Column(
                  children: const [
                    CircularProgressIndicator(),
                    Text("Load data, please wait...")
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
