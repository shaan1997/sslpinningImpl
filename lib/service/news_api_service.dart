import 'dart:convert';
import 'dart:io';

// import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:medium_ssl_pinning/model/article.dart';
import 'package:medium_ssl_pinning/model/news_response.dart';

class NewsApiService {
  static const apiKey = "788576fa85e0490eacac2d580771d924";
  static const baseUrl = "https://newsapi.org/v2";

  final Dio client;
  //final http.Client client;

  NewsApiService(this.client);

  Future<List<Article>> fetchArticle() async {
    try{
      final uri = Uri.parse(
          '$baseUrl/everything?q=flutter&apiKey=788576fa85e0490eacac2d580771d924');
      final response = await client.get('$baseUrl/everything?q=flutter&apiKey=0257272f3e6e4dffa15f3e01b136d7c5');
      print('$baseUrl/everything?q=flutter&apiKey=788576fa85e0490eacac2d580771d924');
      print(response.data);
      if (response.statusCode == 200) {
        return NewsResponse.fromJson(response.data).articles;
      } else {
        throw Error();
      }
    }
    on DioException catch (e){
      if(e.type == DioExceptionType.badCertificate) throw BadCertificateError(errorCode: '',message: 'Invalid Certificate');
     print('dioexception:${e.type}');
     throw e;
    }
    catch(ex){
      print('exception found:$ex');
      if(ex is HandshakeException){
        print('handshake exception found:$ex');
        throw const HandshakeException();
      }
      throw Error();
    }
  }
}

class BadCertificateError {
  String errorCode;
  String message;
  BadCertificateError({required this.errorCode,required this.message});
}
