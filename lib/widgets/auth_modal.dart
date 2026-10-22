import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/reviews_service.dart' show maxNome;
import '../theme/app_theme.dart';
import 'aviso_de_formulario.dart';

/// Modal de login e cadastro — porte do AuthModal.jsx.
class AuthModal extends StatefulWidget {
  const AuthModal({super.key, required this.auth});

  final AuthService auth;

  static Future<void> abrir(BuildContext context, AuthService auth) {
    return showDialog<void>(
      context: context,
      barrierColor: AppCores.tinta.withValues(alpha: 0.55),
      builder: (_) => AuthModal(auth: auth),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  bool _cadastro = false;
  bool _carregando = false;
  String _erro = '';

  /// Conta criada cujo perfil não terminou de salvar: o botão passa a
  /// concluir o perfil em vez de tentar criar a conta de novo.
  User? _pendente;

  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  XFile? _foto;
  Uint8List? _bytesFoto;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;
    setState(() {
      _foto = img;
      _bytesFoto = bytes;
    });
  }

  Future<void> _enviar() async {
    setState(() => _erro = '');

    if (_email.text.trim().isEmpty || _senha.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha email e senha.');
      return;
    }
    if (_cadastro && _nome.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha seu nome.');
      return;
    }

    setState(() => _carregando = true);
    try {
      final pendente = _pendente;
      if (pendente != null) {
        await widget.auth.concluirPerfil(
          pendente,
          nome: _nome.text,
          foto: _bytesFoto,
          extensaoFoto: _foto?.name.split('.').last,
        );
      } else if (_cadastro) {
        await widget.auth.cadastrar(
          nome: _nome.text,
          email: _email.text,
          senha: _senha.text,
          foto: _bytesFoto,
          extensaoFoto: _foto?.name.split('.').last,
        );
      } else {
        await widget.auth.entrar(email: _email.text, senha: _senha.text);
      }
      if (mounted) Navigator.of(context).pop();
    } on CadastroIncompleto catch (e) {
      if (mounted) {
        setState(() {
          _pendente = e.usuario;
          _erro =
              'Sua conta foi criada, mas o perfil não terminou de salvar. '
              'Toque em "Concluir cadastro" para tentar de novo.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erro = AuthService.mensagemDeErro(e));
      }
    } finally {
      // O formulario nao se apaga em erro: o texto digitado continua la.
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 28, 20, 28),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _cadastro ? 'Criar conta' : 'Entrar na conta',
                        style: estiloTitulo(26),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      color: AppCores.tinta3,
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _cadastro
                      ? 'Cadastre-se para participar da comunidade.'
                      : 'Acesse para deixar sua avaliação.',
                  style: const TextStyle(fontSize: 15, color: AppCores.tinta3),
                ),
                const SizedBox(height: 24),

                if (_erro.isNotEmpty) ...[
                  AvisoDeFormulario(texto: _erro, erro: true),
                  const SizedBox(height: 16),
                ],

                if (_cadastro) ...[
                  const _Rotulo('Nome'),
                  TextField(
                    controller: _nome,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    // O mesmo limite das Firestore Rules: um nome maior
                    // deixaria a pessoa sem conseguir avaliar.
                    maxLength: maxNome,
                    decoration: const InputDecoration(
                      hintText: 'Nome completo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        Semantics(
                          button: true,
                          label: _bytesFoto != null
                              ? 'Trocar foto de perfil'
                              : 'Escolher foto de perfil',
                          child: InkWell(
                            onTap: _escolherFoto,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppCores.mataClara,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppCores.mata),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _bytesFoto != null
                                  ? Image.memory(_bytesFoto!, fit: BoxFit.cover)
                                  : const Icon(
                                      Icons.photo_camera_outlined,
                                      size: 24,
                                      color: AppCores.mata,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Foto de perfil (opcional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppCores.tinta3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const _Rotulo('Email'),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'voce@exemplo.com',
                  ),
                ),
                const SizedBox(height: 12),
                const _Rotulo('Senha'),
                TextField(
                  controller: _senha,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _carregando ? null : _enviar(),
                  decoration: InputDecoration(
                    hintText: _cadastro ? 'Ao menos 6 caracteres' : 'Sua senha',
                  ),
                ),
                const SizedBox(height: 20),

                FilledButton(
                  onPressed: _carregando ? null : _enviar,
                  child: Text(
                    _carregando
                        ? 'Aguarde...'
                        : _pendente != null
                        ? 'Concluir cadastro'
                        : _cadastro
                        ? 'Criar conta'
                        : 'Entrar',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _carregando || _pendente != null
                      ? null
                      : () => setState(() {
                          _cadastro = !_cadastro;
                          _erro = '';
                        }),
                  child: Text(
                    _cadastro
                        ? 'Já tem conta? Entrar'
                        : 'Não tem conta? Cadastre-se',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 14, color: AppCores.tinta2),
    ),
  );
}
