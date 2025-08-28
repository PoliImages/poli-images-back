import 'dart:convert';
import 'package:crypt/crypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';

class AuthService {
  final Db _db;

  AuthService(this._db);

  // --- MÉTODO DE LOGIN (NOVO) ---
  Future<Map<String, dynamic>> loginUser(String body) async {
    try {
      final Map<String, dynamic> data = jsonDecode(body);
      final String? email = data['email'];
      final String? password = data['password']; // O CPF

      if (email == null || password == null) {
        return {'status': 400, 'message': 'E-mail e senha são obrigatórios.'};
      }

      final usersCollection = _db.collection('users');
      final existingUser = await usersCollection.findOne({'email': email});

      // 1. Verifica se o usuário existe
      if (existingUser == null) {
        return {'status': 404, 'message': 'Usuário não encontrado.'};
      }

      final hashedPassword = existingUser['password'] as String;

      // 2. Compara a senha enviada com a senha no banco
      if (Crypt(hashedPassword).match(password)) {
        // Senha correta
        return {'status': 200, 'message': 'Login bem-sucedido!'};
      } else {
        // Senha incorreta
        return {'status': 401, 'message': 'Senha inválida.'};
      }
    } catch (e) {
      print('Erro interno no login: $e');
      return {'status': 500, 'message': 'Erro interno no servidor.'};
    }
  }

  // Método principal para registrar um novo usuário (EXISTENTE)
  Future<Map<String, dynamic>> registerUser(String body) async {
    try {
      final Map<String, dynamic> data = jsonDecode(body);
      final String? email = data['email'];
      final String? password = data['password']; // Que será o CPF

      if (email == null || password == null) {
        return {'status': 400, 'message': 'E-mail e senha são obrigatórios.'};
      }

      final role = _validateEmailAndGetRole(email);
      if (role == null) {
        return {'status': 400, 'message': 'Formato de e-mail inválido.'};
      }
      
      if (!CPFValidator.isValid(password)) {
        return {'status': 400, 'message': 'CPF inválido.'};
      }

      final usersCollection = _db.collection('users');

      final existingUser = await usersCollection.findOne({'email': email});
      if (existingUser != null) {
        return {'status': 409, 'message': 'Este e-mail já está em uso.'};
      }

      final hashedPassword = Crypt.sha256(password).toString();

      await usersCollection.insertOne({
        'email': email,
        'password': hashedPassword,
        'role': role,
        'createdAt': DateTime.now(),
      });

      return {'status': 201, 'message': 'Usuário criado com sucesso!'};

    } catch (e) {
      print('Erro interno no cadastro: $e');
      return {'status': 500, 'message': 'Erro interno no servidor.'};
    }
  }

  // Função auxiliar para validar o domínio do e-mail (EXISTENTE)
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
