import 'dart:convert';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
<<<<<<< HEAD
import 'package:mockito/annotations.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:crypt/crypt.dart';
import '../lib/auth_service.dart';

// Remove CpfValidatorDependency da lista de mocks
@GenerateMocks([Db, DbCollection, WriteResult])
import 'auth_service_test.mocks.dart';

String createBody(String email, String password) => 
    jsonEncode({'email': email, 'password': password});

Map<String, dynamic> _createDbUser(String email, String hashedPassword, String role) {
    return {
        'email': email,
        'password': hashedPassword,
        'role': role,
    };
}

void main() {
    late MockDb mockDb;
    late MockDbCollection mockCollection;
    late MockWriteResult mockWriteResult; 
    
    late AuthService authService;

    // ATENÇÃO: CPFs VÁLIDOS MATEMATICAMENTE (Usando um CPF de teste mais comum)
    // Se este valor ainda falhar, o pacote está bloqueando CPFs simulados.
    const String validCpfAluno = '01234567890'; // Exemplo de CPF válido
    const String validCpfProf = '98765432100'; 
    const String invalidCpf = '00000000000'; // Este deve falhar na validação estática
    
    // HASHES RECALCULADOS E CONSISTENTES (Apenas para simular o DB)
    final String hashedPasswordAluno = Crypt.sha256(validCpfAluno).toString();
    final String hashedPasswordProf = Crypt.sha256(validCpfProf).toString();

    setUp(() {
        mockDb = MockDb();
        mockCollection = MockDbCollection();
        mockWriteResult = MockWriteResult();
        
        when(mockDb.collection('users')).thenReturn(mockCollection);
        
        authService = AuthService(mockDb); 
        
        // Simulação básica do WriteResult (necessária para insertOne)
        when(mockWriteResult.isSuccess).thenReturn(true);
        when(mockCollection.insertOne(any)).thenAnswer((_) async => mockWriteResult);
    });

// =================================================================
// TESTES UNITÁRIOS DE LOGIN
// =================================================================
    group('AuthService - Login Tests', () {
        // --- CENÁRIO 1: Login de aluno com sucesso ---
        test('Login de aluno com sucesso', () async {
            const email = 'aluno.teste@p4ed.com';
            final userInDb = _createDbUser(email, hashedPasswordAluno, 'student');
            final body = createBody(email, validCpfAluno); 

            when(mockCollection.findOne({'email': email})).thenAnswer((_) async => userInDb);

            final result = await authService.loginUser(body);

            expect(result['status'], 200, reason: 'O status deve ser 200 para sucesso.');
            expect(result['message'], 'Login bem-sucedido!');
            verify(mockCollection.findOne({'email': email})).called(1);
        });

        // --- CENÁRIO 2: Login de professor com sucesso ---
        test('Login de professor com sucesso', () async {
            const email = 'professor.teste@sistemapoliedro.com.br';
            final userInDb = _createDbUser(email, hashedPasswordProf, 'teacher');
            final body = createBody(email, validCpfProf); 

            when(mockCollection.findOne({'email': email})).thenAnswer((_) async => userInDb);

            final result = await authService.loginUser(body);

            expect(result['status'], 200, reason: 'O status deve ser 200 para sucesso.');
            expect(result['message'], 'Login bem-sucedido!');
        });
        
        // --- CENÁRIO 3: Login com email inválido (Usuário não encontrado) ---
        test('Login com email inválido', () async {
            const email = 'usuario.externo@gmail.com';
            final body = createBody(email, validCpfAluno);

            when(mockCollection.findOne({'email': email})).thenAnswer((_) async => null);

            final result = await authService.loginUser(body);

            expect(result['status'], 404, reason: 'O status deve ser 404 para usuário não encontrado.');
            expect(result['message'], 'Usuário não encontrado.');
            verify(mockCollection.findOne({'email': email})).called(1);
        });

        // --- CENÁRIO 4: Login com senha inválida ("Senha inválida.") ---
        test('Login com senha inválida', () async {
            const email = 'aluno.teste@p4ed.com';
            const wrongCpf = '00000000000';
            final userInDb = _createDbUser(email, hashedPasswordAluno, 'student');
            final body = createBody(email, wrongCpf);
            
            when(mockCollection.findOne({'email': email})).thenAnswer((_) async => userInDb);

            final result = await authService.loginUser(body);
            
            expect(result['status'], 401, reason: 'O status deve ser 401 quando a senha é inválida.');
            expect(result['message'], 'Senha inválida.');
        });


        // --- Teste de Falha: Dados de entrada ausentes (JSON válido, campos nulos) ---
        test('Deve retornar status 400 quando e-mail ou senha estão faltando', () async {
            final body = jsonEncode({'email': 'aluno@p4ed.com'});
            
            final result = await authService.loginUser(body);

            expect(result['status'], 400);
            expect(result['message'], 'E-mail e senha são obrigatórios.');
        });

        // --- Teste de Falha: Erro de Deserialização (JSON inválido) ---
        test('Deve retornar status 500 se o corpo for JSON inválido', () async {
            const invalidBody = '{"email": "incompleto"'; // JSON malformado
            
            final result = await authService.loginUser(invalidBody);

            expect(result['status'], 500);
            expect(result['message'], 'Erro interno no servidor.');
        });
        
        // --- Teste de Falha: Erro interno no servidor (Exceção do DB) ---
        test('Deve retornar status 500 se ocorrer um erro de banco de dados', () async {
            const email = 'aluno.teste@p4ed.com';
            final body = createBody(email, validCpfAluno);

            when(mockCollection.findOne(any)).thenThrow(
                Exception('Falha de conexão simulada.'));

            final result = await authService.loginUser(body);

            expect(result['status'], 500);
            expect(result['message'], 'Erro interno no servidor.');
        });
    });

// =================================================================
// NOVOS TESTES UNITÁRIOS DE REGISTRO
// =================================================================
    group('AuthService - Register Tests', () {
        
        const String studentEmail = 'novo.aluno@p4ed.com';
        const String teacherEmail = 'novo.prof@sistemapoliedro.com.br';
        const String invalidEmail = 'externo@gmail.com';

        // --- CENÁRIO 1: Cadastro de aluno com sucesso ---
        test('Cadastro de aluno com sucesso', () async {
            const email = studentEmail;
            final body = createBody(studentEmail, validCpfAluno);
            
            when(mockCollection.findOne({'email': studentEmail})).thenAnswer((_) async => null);

            final result = await authService.registerUser(body);

            expect(result['status'], 201, reason: 'O status deve ser 201 para criação bem-sucedida.');
            expect(result['message'], 'Usuário criado com sucesso!');

            final capturer = verify(mockCollection.insertOne(captureAny)).captured;
            final insertedDocument = capturer.first as Map<String, dynamic>;
            
            expect(insertedDocument['email'], email, reason: 'O e-mail deve ser salvo corretamente.');
            expect(insertedDocument['role'], 'student', reason: 'A role deve ser "student".');
            expect(insertedDocument['password'], isA<String>());
            expect(insertedDocument['password'].length, greaterThan(10));
        });

        // --- CENÁRIO 2: Cadastro de professor com sucesso ---
        test('Cadastro de professor com sucesso', () async {
            const email = teacherEmail;
            final body = createBody(teacherEmail, validCpfProf);
            
            when(mockCollection.findOne({'email': teacherEmail})).thenAnswer((_) async => null);

            final result = await authService.registerUser(body);

            expect(result['status'], 201, reason: 'O status deve ser 201 para criação bem-sucedida.');
            expect(result['message'], 'Usuário criado com sucesso!');

            final insertedDocument = verify(mockCollection.insertOne(captureAny)).captured.single as Map<String, dynamic>;

            expect(insertedDocument['email'], email, reason: 'O e-mail deve ser salvo corretamente.');
            expect(insertedDocument, containsPair('role', 'teacher'), reason: 'A role deve ser salva como "teacher".');
            expect(insertedDocument['password'], isA<String>(), reason: 'A senha deve ser salva como uma String.');
            expect(insertedDocument['password'].length, greaterThan(10), reason: 'A senha deve ser uma hash com comprimento adequado.');
        });


        // --- CENÁRIO 3: Cadastro com e-mail não institucional (Formato de e-mail inválido) ---
        test('Cadastro com e-mail não institucional', () async {
            const email = invalidEmail;
            final body = createBody(invalidEmail, validCpfAluno);
            
            final result = await authService.registerUser(body);

            expect(result['status'], 400, reason: 'O status deve ser 400 para erro de validação.');
            expect(result['message'], 'Formato de e-mail inválido.');
            
            verifyNever(mockCollection.findOne(any));
            verifyNever(mockCollection.insertOne(any));
        });


        // --- CENÁRIO 4: Cadastro com e-mail já cadastrado (Conflito - 409) ---
        test('Cadastro com CPF inválido', () async {
            final body = createBody(studentEmail, invalidCpf);
            
            final result = await authService.registerUser(body);

            expect(result['status'], 400, reason: 'O status deve ser 400, indicando que o CPF é inválido.');
            expect(result['message'], 'CPF inválido.', reason: 'A mensagem deve indicar o erro específico de CPF.');
            
            verifyNever(mockCollection.findOne(any));
            verifyNever(mockCollection.insertOne(any));
        });

        // --- CENÁRIO 5: Cadastro com e-mail já cadastrado (Conflito - 409) ---
        test('Cadastro com e-mail já cadastrado ', () async {
            const email = studentEmail;
            final body = createBody(studentEmail, validCpfAluno);
            
            final existingUser = _createDbUser(studentEmail, hashedPasswordAluno, 'student');

            when(mockCollection.findOne({'email': studentEmail})).thenAnswer((_) async => existingUser);
            
            final result = await authService.registerUser(body);

            expect(result['status'], 409, reason: 'O status deve ser 409 (Conflito) para e-mail já em uso.');
            expect(result['message'], 'Este e-mail já está em uso.');

            verify(mockCollection.findOne({'email': email})).called(1);
            verifyNever(mockCollection.insertOne(any));
        });
    
        // --- Cenário de Falha: Erro de DB durante a consulta (findOne) ---
        test('Deve retornar status 500 se ocorrer um erro de banco de dados durante a consulta', () async {
            final body = createBody(studentEmail, validCpfAluno); 
            
            when(mockCollection.findOne(any)).thenThrow(
                Exception('Falha de conexão simulada.'));

            final result = await authService.registerUser(body);

            expect(result['status'], 500);
            expect(result['message'], 'Erro interno no servidor.');
            verifyNever(mockCollection.insertOne(any));
        });

        // --- Cenário de Falha: Erro de DB durante a inserção (insertOne) ---
        test('Deve retornar status 500 se ocorrer um erro de banco de dados durante a inserção', () async {
            final body = createBody(studentEmail, validCpfAluno);
            
            when(mockCollection.findOne(any)).thenAnswer((_) async => null); // OK na consulta
            when(mockCollection.insertOne(any)).thenThrow(
                Exception('Falha de escrita simulada.')); // Falha na inserção

            final result = await authService.registerUser(body);

            expect(result['status'], 500);
            expect(result['message'], 'Erro interno no servidor.');
            verify(mockCollection.insertOne(any)).called(1);
        });
        
        // --- Teste de Falha: Dados de entrada ausentes (JSON válido, campos nulos) ---
        test('Deve retornar status 400 quando e-mail ou senha estão faltando', () async {
            final body = jsonEncode({'email': studentEmail});
            
            final result = await authService.registerUser(body);

            expect(result['status'], 400);
            expect(result['message'], 'E-mail e senha são obrigatórios.');
            verifyNever(mockCollection.findOne(any));
        });

        // --- Teste de Falha: Erro de Deserialização (JSON inválido) ---
        test('Deve retornar status 500 se o corpo for JSON inválido', () async {
            const invalidBody = '{"email": "incompleto"'; // JSON malformado
            
            final result = await authService.registerUser(invalidBody);

            expect(result['status'], 500);
            expect(result['message'], 'Erro interno no servidor.');
            verifyNever(mockCollection.findOne(any));
        });
    });
}
=======
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
>>>>>>> 8a06e6bf43e8c1167050c87b5aaa2b766c36cd8f
