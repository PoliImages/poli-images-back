import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:poli_images_back/auth_service.dart'; // Importa nosso novo serviço

void main() async {
  final dotEnv = DotEnv(includePlatformEnvironment: true)..load();
  final mongoUri = dotEnv['MONGO_URI'];
  print(mongoUri);
  if (mongoUri == null) {
    print('‼️ Erro: Variável de ambiente MONGO_URI não encontrada.');
    return;
  }

  // Conecta ao banco de dados UMA VEZ quando o servidor inicia
  final db = await Db.create(mongoUri);
  await db.open();
  print('✅ Conectado ao MongoDB Atlas!');

  // Cria uma instância do nosso serviço, passando a conexão com o banco
  final authService = AuthService(db);
  
  final app = Router();

  app.get('/', (Request request) {
    return Response.ok('API do Poli Images está funcionando!');
  });

  // --- ROTA DE CADASTRO ATUALIZADA ---
  app.post('/api/auth/register', (Request request) async {
    final requestBody = await request.readAsString();
    final result = await authService.registerUser(requestBody);

    return Response(
      result['status'], // Código de status (201, 400, 409, 500)
      body: jsonEncode({'message': result['message']}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = const Pipeline().addHandler(app);
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);

  print('🚀 Servidor rodando em http://localhost:${server.port}');
}