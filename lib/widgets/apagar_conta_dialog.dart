import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'aviso_de_formulario.dart';

/// Confirmação de apagar a conta, com a senha (11/11/2026). O site tem o
/// mesmo diálogo (`ModalApagarConta.tsx`).
///
/// A senha confirma que é a dona da conta, e não alguém com o celular
/// desbloqueado, e faz o login recente que o Firebase exige para apagar.
class ApagarContaDialog extends StatefulWidget {
  const ApagarContaDialog({super.key, required this.aoApagar});

  /// Apaga a conta com a senha digitada. Erro de [ApagamentoIncompleto]
  /// aparece na tela com a mensagem dele.
  final Future<void> Function(String senha) aoApagar;

  /// Abre o diálogo. Devolve `true` se a conta foi apagada.
  static Future<bool> abrir(BuildContext context, AuthService auth) async {
    final apagou = await showDialog<bool>(
      context: context,
      barrierColor: AppCores.tinta.withValues(alpha: 0.55),
      builder: (_) => ApagarContaDialog(
        aoApagar: (senha) => auth.apagarConta(senha: senha),
      ),
    );
    return apagou ?? false;
  }

  @override
  State<ApagarContaDialog> createState() => _ApagarContaDialogState();
}

class _ApagarContaDialogState extends State<ApagarContaDialog> {
  final _senha = TextEditingController();
  bool _carregando = false;
  String _erro = '';

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  Future<void> _apagar() async {
    if (_senha.text.isEmpty) {
      setState(() => _erro = 'Digite sua senha para confirmar.');
      return;
    }
    setState(() {
      _erro = '';
      _carregando = true;
    });
    try {
      await widget.aoApagar(_senha.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApagamentoIncompleto catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (e) {
      if (mounted) setState(() => _erro = AuthService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // No meio do apagamento, nem o voltar nem o toque fora fecham: a pessoa
    // ficaria sem saber se a conta saiu.
    return PopScope(
      canPop: !_carregando,
      child: Dialog(
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
                        child: Text('Apagar conta', style: estiloTitulo(26)),
                      ),
                      IconButton(
                        onPressed: _carregando
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, size: 20),
                        color: AppCores.tinta3,
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Isto apaga, sem volta:',
                    style: TextStyle(fontSize: 15, color: AppCores.tinta2),
                  ),
                  const SizedBox(height: 8),
                  for (final item in const [
                    'a sua conta, com o e-mail e a senha;',
                    'o seu nome e a sua foto de perfil;',
                    'as suas avaliações;',
                    'a contagem das fotos que você enviou.',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        '•  $item',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: AppCores.tinta2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_erro.isNotEmpty) ...[
                    AvisoDeFormulario(texto: _erro, erro: true),
                    const SizedBox(height: 16),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Para confirmar, digite sua senha',
                      style: TextStyle(fontSize: 14, color: AppCores.tinta2),
                    ),
                  ),
                  TextField(
                    controller: _senha,
                    obscureText: true,
                    enabled: !_carregando,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _carregando ? null : _apagar(),
                    decoration: const InputDecoration(hintText: 'Sua senha'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _carregando ? null : _apagar,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppCores.terra,
                      foregroundColor: AppCores.branco,
                    ),
                    child: Text(
                      _carregando ? 'Apagando...' : 'Apagar minha conta',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _carregando
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
