import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:poli_images_back/auth_service.dart';
// 1. Importa o novo pacote de CORS
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

void main() async {
  final dotEnv = DotEnv(includePlatformEnvironment: true)..load();
  final mongoUri = dotEnv['MONGO_URI'];

  if (mongoUri == null) {
    print('‼️ Erro: Variável de ambiente MONGO_URI não encontrada.');
    return;
  }

  final db = await Db.create(mongoUri);
  await db.open();
  print('✅ Conectado ao MongoDB Atlas!');

  final authService = AuthService(db);
  final app = Router();

  app.get('/', (Request request) {
    return Response.ok('API do Poli Images está funcionando!');
  });

  app.post('/api/auth/register', (Request request) async {
    final requestBody = await request.readAsString();
    final result = await authService.registerUser(requestBody);

    return Response(
      result['status'],
      body: jsonEncode({'message': result['message']}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // 2. Cria o "porteiro" (middleware) de CORS
  // O overrideHeaders com '*' permite requisições de qualquer origem.
  final corsMiddleware = corsHeaders();

  // 3. Atualiza o handler para usar o Pipeline com o CORS
  final handler = const Pipeline()
      .addMiddleware(corsMiddleware) // Adiciona o porteiro do CORS
      .addHandler(app);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);

  print('🚀 Servidor rodando em http://localhost:${server.port}');
}
