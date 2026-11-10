import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../models/avaliacao.dart' show fotoConfiavel;
import 'reviews_service.dart' show maxNome;
import 'sem_metadados.dart';

/// O mesmo limite do bucket `avatars` no Supabase.
const maxAvatarBytes = 1024 * 1024;

/// O formato que a funcao `enviar-avatar` grava: `<uid>/<uuid>.<ext>`.
final _formatoDoCaminho = RegExp(
  r'^[A-Za-z0-9]{1,128}/[0-9a-f-]{32,36}\.(jpg|png|webp)$',
);

/// O caminho que a funcao `enviar-avatar` devolveu, se tiver o formato dela e
/// for da pasta de [uid]; senao, `null`. A URL publica sai daqui, entao uma
/// resposta estranha nao vira foto de perfil.
String? caminhoDoAvatar(Object? resposta, String uid) {
  final caminho = switch (resposta) {
    {'caminho': final String c} => c,
    _ => null,
  };
  if (caminho == null || !caminho.startsWith('$uid/')) return null;
  return _formatoDoCaminho.hasMatch(caminho) ? caminho : null;
}

/// A conta foi criada, mas o perfil (foto, nome) não terminou de salvar.
class CadastroIncompleto implements Exception {
  const CadastroIncompleto(this.usuario, this.causa);

  final User usuario;
  final Object causa;
}

/// Cadastro e login por e-mail/senha, com avatar no Supabase Storage.
///
/// Mesmo fluxo do site: cria no Firebase Auth, sobe a foto pela funcao
/// `enviar-avatar` (que grava no bucket `avatars`), grava o perfil em
/// `usuarios/{uid}`.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get mudancasDeAutenticacao => _auth.authStateChanges();
  User? get usuarioAtual => _auth.currentUser;

  Future<void> entrar({required String email, required String senha}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
    Uint8List? foto,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    try {
      await concluirPerfil(cred.user!, nome: nome, foto: foto);
    } catch (erro) {
      // A conta JA existe neste ponto. Antes, a falha aqui aparecia como falha
      // do cadastro inteiro, e tentar de novo dava "email já está em uso".
      throw CadastroIncompleto(cred.user!, erro);
    }
  }

  /// A parte do cadastro que vem depois de criar a conta: avatar, nome e
  /// perfil. Pode ser chamada de novo se falhar no meio — cada passo confere o
  /// que já foi feito.
  Future<void> concluirPerfil(
    User user, {
    required String nome,
    Uint8List? foto,
  }) async {
    var fotoUrl = fotoConfiavel(user.photoURL);
    if (foto != null && fotoUrl.isEmpty) {
      fotoUrl = await _enviarAvatar(user, foto);
    }

    final nomeLimpo = nome.trim();
    final nomeFinal = nomeLimpo.substring(
      0,
      nomeLimpo.length.clamp(0, maxNome),
    );
    await user.updateDisplayName(nomeFinal);
    if (fotoUrl.isNotEmpty) {
      await user.updatePhotoURL(fotoUrl);
    }
    await user.reload();

    // O e-mail NAO entra aqui. Ele ja vive no Firebase Auth, que e o lugar
    // dele, e gravar uma copia em documento de leitura aberta tornava dado
    // pessoal publico sem que nada no app precisasse disso (LGPD).
    final perfil = _db.collection('usuarios').doc(user.uid);
    if ((await perfil.get()).exists) {
      await perfil.update({'nome': nomeFinal, 'photoURL': fotoUrl});
    } else {
      await perfil.set({
        'nome': nomeFinal,
        'photoURL': fotoUrl,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Sobe o avatar e devolve a URL pública, ou '' se falhar.
  ///
  /// Falha ao subir avatar nao pode derrubar o cadastro: perder a conta por
  /// causa da foto seria pior que ficar sem foto. Mesmo criterio do
  /// `if (!error)` da versao React.
  ///
  /// A foto vai para a funcao `enviar-avatar`, com o ID token do Firebase, e
  /// ela grava em `<uid>/<uuid>.<ext>`. Ate 10/11/2026 o app gravava direto no
  /// bucket, que aceitava arquivo de qualquer pessoa, ate sem login, e sem
  /// limite de quantidade (revisao de seguranca de 10/11/2026). A funcao confere
  /// o login, o tipo pelos bytes e o limite de fotos por dia.
  ///
  /// O bucket e publico: a foto sobe sem metadados (`semMetadados`). Ate
  /// 02/11/2026 subia com o EXIF que o image_picker copia, GPS incluido.
  Future<String> _enviarAvatar(User user, Uint8List foto) async {
    final ({Uint8List bytes, String extensao}) limpa;
    try {
      limpa = await semMetadados(foto, ladoMaximo: 512);
    } catch (_) {
      return '';
    }
    if (limpa.bytes.lengthInBytes > maxAvatarBytes) return '';
    try {
      final token = await user.getIdToken();
      final supabase = Supabase.instance.client;
      final resposta = await supabase.functions.invoke(
        'enviar-avatar',
        body: {'imagem': base64Encode(limpa.bytes)},
        headers: {'Authorization': 'Bearer $token'},
      );
      final caminho = caminhoDoAvatar(resposta.data, user.uid);
      if (caminho == null) return '';
      return fotoConfiavel(
        supabase.storage.from('avatars').getPublicUrl(caminho),
      );
    } catch (_) {
      return '';
    }
  }

  Future<void> sair() => _auth.signOut();

  /// Traduz o codigo do Firebase para a mensagem que o usuario le.
  /// Porte do mapa `msgs` do AuthModal.jsx.
  static String mensagemDeErro(Object erro) {
    if (erro is! FirebaseAuthException) {
      return 'Algo deu errado. Tente de novo.';
    }
    return switch (erro.code) {
      'email-already-in-use' => 'Este email já está em uso.',
      'invalid-email' => 'Email inválido.',
      'weak-password' => 'Senha deve ter ao menos 6 caracteres.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email ou senha incorretos.',
      'network-request-failed' => 'Sem conexão. Verifique sua internet.',
      'too-many-requests' => 'Muitas tentativas. Aguarde um momento.',
      _ => erro.message ?? 'Algo deu errado. Tente de novo.',
    };
  }
}
