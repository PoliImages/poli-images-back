import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:convert';

import 'package:your_project/auth_service.dart'; // ajuste o caminho

import 'mocks.mocks.dart';

void main() {
  late MockDb mockDb;
  late MockDbCollection mockCollection;
  late AuthService authService;

  setUp(() {
    mockDb = MockDb();
    mockCollection = MockDbCollection();

    when(mockDb.collection('users')).thenReturn(mockCollection);

    authService = AuthService(mockDb);
  });

  test('Login com email e senha válidos deve retornar status 200', () async {
    // Arrange
    const email = 'joao@sistemapoliedro.com.br';
    const password = '12345678900'; // CPF
    final hashedPassword = Crypt.sha256(password).toString();

    when(mockCollection.findOne({'email': email})).thenAnswer((_) async => {
          'email': email,
          'password': hashedPassword,
        });

    final body = jsonEncode({'email': email, 'password': password});

    // Act
    final result = await authService.loginUser(body);

    // Assert
    expect(result['status'], equals(200));
    expect(result['message'], equals('Login bem-sucedido!'));
  });
}
