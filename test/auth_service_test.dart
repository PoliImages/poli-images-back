import 'dart:convert';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:crypt/crypt.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'package:your_package_name/auth_service.dart'; // ajuste para o nome do seu pacote

// --- Mock do MongoDB ---
class MockDbCollection extends Mock implements DbCollection {}
class MockDb extends Mock implements Db {}

void main() {
  late AuthService authService;
  late MockDb db;
  late MockDbCollection usersCollection;

  setUp(() {
    db = MockDb();
    usersCollection = MockDbCollection();
    when(db.collection('users')).thenReturn(usersCollection);
    authService = AuthService(db);
  });

  group('AuthService.registerUser', () {
    test('deve retornar erro se e-mail ou senha forem nulos', () async {
      final body = jsonEncode({'email': null, 'password': null});

      final result = await authService.registerUser(body);

      expect(result['status'], 400);
      expect(result['message'], contains('E-mail e senha são obrigatórios'));
    });

    test('deve retornar erro se CPF for inválido', () async {
      final body = jsonEncode({'email': 'teste@sistemapoliedro.com.br', 'password': '123'});

      final result = await authService.registerUser(body);

      expect(result['status'], 400);
      expect(result['message'], contains('CPF inválido'));
    });

    test('deve registrar usuário com sucesso', () async {
      final cpf = '12345678909';
      expect(CPFValidator.isValid(cpf), true);

      final body = jsonEncode({'email': 'professor@sistemapoliedro.com.br', 'password': cpf});

      when(usersCollection.findOne(any)).thenAnswer((_) async => null);
      when(usersCollection.insertOne(any)).thenAnswer((_) async => Future.value());

      final result = await authService.registerUser(body);

      expect(result['status'], 201);
      expect(result['message'], contains('Usuário criado com sucesso'));
    });
  });

  group('AuthService.loginUser', () {
    test('deve retornar erro se usuário não existir', () async {
      final body = jsonEncode({'email': 'naoexiste@sistemapoliedro.com.br', 'password': '12345678909'});

      when(usersCollection.findOne(any)).thenAnswer((_) async => null);

      final result = await authService.loginUser(body);

      expect(result['status'], 404);
      expect(result['message'], contains('Usuário não encontrado'));
    });

    test('deve retornar erro se senha for incorreta', () async {
      final hash = Crypt.sha256('12345678909').toString();
      final existingUser = {'email': 'teste@sistemapoliedro.com.br', 'password': hash};

      when(usersCollection.findOne(any)).thenAnswer((_) async => existingUser);

      final body = jsonEncode({'email': 'teste@sistemapoliedro.com.br', 'password': 'senhaerrada'});
      final result = await authService.loginUser(body);

      expect(result['status'], 401);
      expect(result['message'], contains('Senha inválida'));
    });

    test('deve logar com sucesso se senha for correta', () async {
      final senha = '12345678909';
      final hash = Crypt.sha256(senha).toString();
      final existingUser = {'email': 'teste@sistemapoliedro.com.br', 'password': hash};

      when(usersCollection.findOne(any)).thenAnswer((_) async => existingUser);

      final body = jsonEncode({'email': 'teste@sistemapoliedro.com.br', 'password': senha});
      final result = await authService.loginUser(body);

      expect(result['status'], 200);
      expect(result['message'], contains('Login bem-sucedido'));
    });
  });
}
