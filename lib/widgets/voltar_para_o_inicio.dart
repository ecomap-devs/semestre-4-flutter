import 'package:flutter/material.dart';

/// O Voltar do sistema fora do Início leva ao Início; só dali o app fecha,
/// como nos apps do próprio Android.
///
/// Até 11/11/2026 o Voltar fechava o app de qualquer aba (auditoria de
/// responsividade da v1.3.0). Fica separado da `AppShell` para ter teste: a
/// casca monta a Home, que lê o Firestore, e não sobe num teste de widget.
class VoltarParaOInicio extends StatelessWidget {
  const VoltarParaOInicio({
    super.key,
    required this.noInicio,
    required this.irParaOInicio,
    required this.child,
  });

  /// A aba aberta é o Início: o Voltar segue o normal e fecha o app.
  final bool noInicio;

  /// Chamado no lugar de fechar, quando o Voltar chega fora do Início.
  final VoidCallback irParaOInicio;

  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: noInicio,
    onPopInvokedWithResult: (saiu, _) {
      if (!saiu) irParaOInicio();
    },
    child: child,
  );
}
