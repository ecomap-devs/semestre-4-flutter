import 'package:flutter/material.dart';

import '../../data/home_data.dart';
import '../../theme/app_theme.dart';
import '../animacao_na_tela.dart';

/// Area desmatada por bioma, em barras horizontais — o `BarrasAnimadas` do
/// site.
///
/// O React mostrava a mesma serie em quatro graficos (barras, rosca, linha e
/// radar). Ficaram so as barras, que sao as que se leem melhor. Cada uma
/// cresce em sequencia quando o grafico entra na tela; a maior vai em terra e
/// as outras em mata, para o olho ir a que pesa mais.
class BarrasChart extends StatelessWidget {
  const BarrasChart({super.key});

  @override
  Widget build(BuildContext context) {
    final maximo = areaPorBioma
        .map((b) => b.valor)
        .reduce((a, b) => a > b ? a : b);

    return AnimacaoNaTela(
      duracao: const Duration(milliseconds: 1200),
      builder: (_, progresso, _) => Column(
        children: [
          for (final (i, b) in areaPorBioma.indexed)
            Semantics(
              label: '${b.nome}: ${b.valor} mil km²',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.nome,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppCores.tinta,
                            ),
                          ),
                        ),
                        Text(
                          '${b.valor} mil km²',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppCores.tinta3,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppCores.papel2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor:
                            b.valor /
                            maximo *
                            Interval(
                              i * .07,
                              .58 + i * .07,
                              curve: Curves.easeOut,
                            ).transform(progresso),
                        child: Container(
                          decoration: BoxDecoration(
                            color: i == 0 ? AppCores.terra : AppCores.mata,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
