import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
// A importação agora é mais simples, sem o 'show load'
import 'package:dotenv/dotenv.dart';

void main() async {
  // --- CORREÇÃO AQUI ---
  // Carrega as variáveis de ambiente do arquivo .env da forma nova
  final dotEnv = DotEnv(includePlatformEnvironment: true)..load();
  
  // Vamos verificar se a variável do MongoDB foi carregada
  final mongoUri = dotEnv['MONGO_URI'];

  if (mongoUri == null) {
    print('‼️ Erro: Variável de ambiente MONGO_URI não encontrada no arquivo .env');
    // Encerra o programa se a variável essencial não for encontrada
    return;
  }
  
  // O resto do código continua igual
  final app = Router();

  app.get('/', (Request request) {
    return Response.ok('API do Poli Images está funcionando!');
  });

  app.post('/api/auth/register', (Request request) async {
    print('Recebida requisição de cadastro!');
    return Response.ok('Usuário cadastrado com sucesso (simulado)');
  });

  final handler = const Pipeline().addHandler(app);
  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    8080,
  );

  print('🚀 Servidor rodando em http://localhost:${server.port}');
  print('🔑 String de conexão com MongoDB carregada com sucesso.');
}