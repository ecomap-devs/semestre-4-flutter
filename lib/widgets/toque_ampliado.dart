import 'package:flutter/material.dart';

/// Area de toque de pelo menos [minimo] dp em volta de um desenho menor.
///
/// O Android pede 48 dp para tudo que se toca. Os filtros, as etiquetas de
/// bioma e as barras do slide sao desenhados menores de proposito; com isto o
/// desenho continua do mesmo tamanho, e o toque que cai na margem transparente
/// em volta dele conta como toque nele (auditoria de responsividade de
/// 11/11/2026). O leitor de tela continua com o `Semantics` de quem usa.
class ToqueAmpliado extends StatelessWidget {
  const ToqueAmpliado({
    super.key,
    required this.aoTocar,
    required this.child,
    this.minimo = 48,
  });

  final VoidCallback aoTocar;
  final Widget child;
  final double minimo;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: aoTocar,
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: minimo, minHeight: minimo),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    ),
  );
}
