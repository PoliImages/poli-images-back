import 'dart:convert';
import 'package:crypt/crypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';

class AuthService {
  final Db _db;

  AuthService(this._db);

  // Método principal para registrar um novo usuário
  Future<Map<String, dynamic>> registerUser(String body) async {
    try {
      final Map<String, dynamic> data = jsonDecode(body);
      final String? email = data['email'];
      final String? password = data['password']; // Que será o CPF

      // 1. Validação de campos básicos
      if (email == null || password == null) {
        return {'status': 400, 'message': 'E-mail e senha são obrigatórios.'};
      }

      // 2. Validação do formato do e-mail
      final role = _validateEmailAndGetRole(email);
      if (role == null) {
        return {'status': 400, 'message': 'Formato de e-mail inválido.'};
      }
      
      // 3. Validação do formato do CPF
      if (!CPFValidator.isValid(password)) {
        return {'status': 400, 'message': 'CPF inválido.'};
      }

      // 4. Conectar ao banco e pegar a coleção de usuários
      final usersCollection = _db.collection('users');

      // 5. Verificar se o e-mail já existe
      final existingUser = await usersCollection.findOne({'email': email});
      if (existingUser != null) {
        return {'status': 409, 'message': 'Este e-mail já está em uso.'};
      }

      // 6. Hashing da senha (CPF)
      final hashedPassword = Crypt.sha256(password).toString();

      // 7. Salvar no MongoDB
      await usersCollection.insertOne({
        'email': email,
        'password': hashedPassword,
        'role': role, // 'teacher' ou 'student'
        'createdAt': DateTime.now(),
      });

      return {'status': 201, 'message': 'Usuário criado com sucesso!'};

    } catch (e) {
      print('Erro interno no cadastro: $e');
      return {'status': 500, 'message': 'Erro interno no servidor.'};
    }
  }

  // Função auxiliar para validar o domínio do e-mail e retornar o "papel" do usuário
  String? _validateEmailAndGetRole(String email) {
    if (email.endsWith('@sistemapoliedro.com.br')) {
      return 'teacher';
    }
    if (email.endsWith('@p4ed.com')) {
      return 'student';
    }
    return null;
  }
}