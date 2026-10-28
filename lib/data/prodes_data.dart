/// Desmatamento medido pelo PRODES (INPE), somado por bioma — copia do
/// `src/dados/prodes.ts` do site, que o `scripts/prodes/gerar.mjs` de la gera
/// a partir dos arquivos do painel do TerraBrasilis. Nao edite os numeros a
/// mao: quando o site atualizar, copie de novo.
///
/// Area dos biomas: IBGE (2019). Na Amazonia, floresta e vegetacao nao
/// florestal somadas. Periodos de agosto a julho: 2024–2025 vai de 01/08/2024
/// a 31/07/2025.
///
/// Ate 28/10/2026 a Home e as fichas dos biomas usavam valores de referencia
/// herdados do React, e a Amazonia aparecia 78% desmatada (o PRODES mede 20%).
library;

import 'package:flutter/foundation.dart';

/// Desmatamento de um periodo de um ano do PRODES.
@immutable
class PeriodoProdes {
  const PeriodoProdes(
    this.inicio,
    this.fim,
    this.km2, {
    this.preliminar = false,
  });

  final int inicio;
  final int fim;
  final double km2;

  /// Estimativa do INPE, ainda nao consolidada.
  final bool preliminar;
}

@immutable
class DesmatamentoBioma {
  const DesmatamentoBioma({
    required this.areaKm2,
    required this.acumuladoKm2,
    required this.anos,
    required this.acumulado,
  });

  /// Area do bioma segundo o IBGE.
  final int areaKm2;

  /// Tudo o que o PRODES ja mapeou como desmatado, do inicio da serie ate hoje.
  final double acumuladoKm2;

  /// Desmatamento a cada periodo, do mais antigo ao mais recente.
  final List<PeriodoProdes> anos;

  /// Total ja desmatado ao fim de cada periodo (`fim`), desde o inicio da serie.
  final List<({int fim, double km2})> acumulado;

  /// O desmatamento no periodo que termina em `fim`, se ja consolidado.
  double? noPeriodo(int fim) {
    for (final p in anos) {
      if (p.fim == fim && !p.preliminar) return p.km2;
    }
    return null;
  }
}

/// Taxa anual oficial de desmatamento da Amazonia Legal (so floresta), a que o
/// INPE anuncia. `ano` e o fim do periodo: 2004 = ago/2003 a jul/2004.
@immutable
class TaxaAnual {
  const TaxaAnual(this.ano, this.km2, {this.preliminar = false});

  final int ano;
  final int km2;
  final bool preliminar;
}

/// Data da ultima atualizacao dos dados no TerraBrasilis.
const prodesAtualizadoEm = '2026-10-16';

const prodes = <String, DesmatamentoBioma>{
  'Amazônia': DesmatamentoBioma(
    areaKm2: 4212742,
    acumuladoKm2: 827184.1,
    anos: [
      PeriodoProdes(2013, 2014, 5513.2),
      PeriodoProdes(2018, 2019, 11380.2),
      PeriodoProdes(2019, 2020, 11020.1),
      PeriodoProdes(2020, 2021, 12896.5),
      PeriodoProdes(2021, 2022, 13200.3),
      PeriodoProdes(2022, 2023, 8391.1),
      PeriodoProdes(2023, 2024, 6624.9),
      PeriodoProdes(2024, 2025, 5564.8),
    ],
    acumulado: [
      (fim: 2000, km2: 13071.8),
      (fim: 2002, km2: 16175.4),
      (fim: 2004, km2: 18935.4),
      (fim: 2006, km2: 20817.9),
      (fim: 2007, km2: 678642.1),
      (fim: 2008, km2: 692203.9),
      (fim: 2009, km2: 698076.9),
      (fim: 2010, km2: 704662.4),
      (fim: 2011, km2: 710056.8),
      (fim: 2012, km2: 714184.0),
      (fim: 2013, km2: 720386.5),
      (fim: 2014, km2: 725899.7),
      (fim: 2015, km2: 731808.4),
      (fim: 2016, km2: 739915.1),
      (fim: 2017, km2: 746673.4),
      (fim: 2018, km2: 754743.3),
      (fim: 2019, km2: 766123.5),
      (fim: 2020, km2: 777143.6),
      (fim: 2021, km2: 790040.1),
      (fim: 2022, km2: 803240.4),
      (fim: 2023, km2: 811631.5),
      (fim: 2024, km2: 818256.4),
      (fim: 2025, km2: 823821.2),
      (fim: 2026, km2: 827184.1),
    ],
  ),
  'Cerrado': DesmatamentoBioma(
    areaKm2: 1983017,
    acumuladoKm2: 1041097.3,
    anos: [
      PeriodoProdes(2012, 2013, 13481.6),
      PeriodoProdes(2013, 2014, 10904.4),
      PeriodoProdes(2014, 2015, 11131.6),
      PeriodoProdes(2015, 2016, 7497.1),
      PeriodoProdes(2016, 2017, 7117.4),
      PeriodoProdes(2017, 2018, 7259.8),
      PeriodoProdes(2018, 2019, 6319.0),
      PeriodoProdes(2019, 2020, 7902.7),
      PeriodoProdes(2020, 2021, 8531.4),
      PeriodoProdes(2021, 2022, 10688.6),
      PeriodoProdes(2022, 2023, 11011.7),
      PeriodoProdes(2023, 2024, 8174.2),
      PeriodoProdes(2024, 2025, 7235.3),
      PeriodoProdes(2025, 2026, 5516.7, preliminar: true),
    ],
    acumulado: [
      (fim: 2000, km2: 708768.1),
      (fim: 2002, km2: 762634.1),
      (fim: 2004, km2: 820174.8),
      (fim: 2006, km2: 853929.7),
      (fim: 2008, km2: 880552.8),
      (fim: 2010, km2: 900373.5),
      (fim: 2012, km2: 918325.8),
      (fim: 2013, km2: 931807.4),
      (fim: 2014, km2: 942711.8),
      (fim: 2015, km2: 953843.5),
      (fim: 2016, km2: 961340.6),
      (fim: 2017, km2: 968458.0),
      (fim: 2018, km2: 975717.8),
      (fim: 2019, km2: 982036.8),
      (fim: 2020, km2: 989939.5),
      (fim: 2021, km2: 998470.9),
      (fim: 2022, km2: 1009159.5),
      (fim: 2023, km2: 1020171.2),
      (fim: 2024, km2: 1028345.4),
      (fim: 2025, km2: 1035580.6),
      (fim: 2026, km2: 1041097.3),
    ],
  ),
  'Caatinga': DesmatamentoBioma(
    areaKm2: 862818,
    acumuladoKm2: 377204.2,
    anos: [
      PeriodoProdes(2010, 2011, 4059.4),
      PeriodoProdes(2013, 2014, 3602.2),
      PeriodoProdes(2016, 2017, 2246.2),
      PeriodoProdes(2017, 2018, 2169.5),
      PeriodoProdes(2018, 2019, 1868.2),
      PeriodoProdes(2019, 2020, 2226.0),
      PeriodoProdes(2020, 2021, 2096.2),
      PeriodoProdes(2021, 2022, 2627.6),
      PeriodoProdes(2022, 2023, 3169.6),
      PeriodoProdes(2023, 2024, 3484.4),
      PeriodoProdes(2024, 2025, 2289.5),
    ],
    acumulado: [
      (fim: 2000, km2: 248924.5),
      (fim: 2004, km2: 297670.2),
      (fim: 2006, km2: 314015.4),
      (fim: 2008, km2: 326718.3),
      (fim: 2010, km2: 334604.5),
      (fim: 2011, km2: 338663.9),
      (fim: 2013, km2: 346559.0),
      (fim: 2014, km2: 350161.2),
      (fim: 2016, km2: 355026.9),
      (fim: 2017, km2: 357273.1),
      (fim: 2018, km2: 359442.6),
      (fim: 2019, km2: 361310.8),
      (fim: 2020, km2: 363536.9),
      (fim: 2021, km2: 365633.0),
      (fim: 2022, km2: 368260.7),
      (fim: 2023, km2: 371430.3),
      (fim: 2024, km2: 374914.6),
      (fim: 2025, km2: 377204.2),
    ],
  ),
  'Mata Atlântica': DesmatamentoBioma(
    areaKm2: 1107419,
    acumuladoKm2: 794423.0,
    anos: [
      PeriodoProdes(2010, 2011, 1879.9),
      PeriodoProdes(2013, 2014, 1887.3),
      PeriodoProdes(2016, 2017, 1166.1),
      PeriodoProdes(2017, 2018, 1344.3),
      PeriodoProdes(2018, 2019, 1067.4),
      PeriodoProdes(2019, 2020, 790.6),
      PeriodoProdes(2020, 2021, 927.0),
      PeriodoProdes(2021, 2022, 1032.7),
      PeriodoProdes(2022, 2023, 765.2),
      PeriodoProdes(2023, 2024, 475.2),
      PeriodoProdes(2024, 2025, 402.4),
    ],
    acumulado: [
      (fim: 2000, km2: 730094.5),
      (fim: 2004, km2: 752598.1),
      (fim: 2006, km2: 765366.4),
      (fim: 2008, km2: 773375.2),
      (fim: 2010, km2: 777416.1),
      (fim: 2011, km2: 779296.0),
      (fim: 2013, km2: 782151.6),
      (fim: 2014, km2: 784038.9),
      (fim: 2016, km2: 786452.2),
      (fim: 2017, km2: 787618.3),
      (fim: 2018, km2: 788962.7),
      (fim: 2019, km2: 790030.0),
      (fim: 2020, km2: 790820.7),
      (fim: 2021, km2: 791747.6),
      (fim: 2022, km2: 792780.3),
      (fim: 2023, km2: 793545.5),
      (fim: 2024, km2: 794020.7),
      (fim: 2025, km2: 794423.0),
    ],
  ),
  'Pantanal': DesmatamentoBioma(
    areaKm2: 150988,
    acumuladoKm2: 31943.5,
    anos: [
      PeriodoProdes(2010, 2011, 510.4),
      PeriodoProdes(2013, 2014, 369.7),
      PeriodoProdes(2016, 2017, 711.6),
      PeriodoProdes(2017, 2018, 498.5),
      PeriodoProdes(2018, 2019, 514.5),
      PeriodoProdes(2019, 2020, 677.9),
      PeriodoProdes(2020, 2021, 824.5),
      PeriodoProdes(2021, 2022, 789.4),
      PeriodoProdes(2022, 2023, 723.1),
      PeriodoProdes(2023, 2024, 842.4),
      PeriodoProdes(2024, 2025, 291.2),
    ],
    acumulado: [
      (fim: 2000, km2: 15034.7),
      (fim: 2004, km2: 19034.9),
      (fim: 2006, km2: 20726.8),
      (fim: 2008, km2: 21763.7),
      (fim: 2010, km2: 23093.5),
      (fim: 2011, km2: 23603.9),
      (fim: 2013, km2: 24463.5),
      (fim: 2014, km2: 24833.3),
      (fim: 2016, km2: 26070.4),
      (fim: 2017, km2: 26782.0),
      (fim: 2018, km2: 27280.5),
      (fim: 2019, km2: 27794.9),
      (fim: 2020, km2: 28472.8),
      (fim: 2021, km2: 29297.3),
      (fim: 2022, km2: 30086.7),
      (fim: 2023, km2: 30809.8),
      (fim: 2024, km2: 31652.3),
      (fim: 2025, km2: 31943.5),
    ],
  ),
  'Pampa': DesmatamentoBioma(
    areaKm2: 193836,
    acumuladoKm2: 115858.2,
    anos: [
      PeriodoProdes(2010, 2011, 1699.8),
      PeriodoProdes(2013, 2014, 2118.7),
      PeriodoProdes(2016, 2017, 925.9),
      PeriodoProdes(2017, 2018, 917.8),
      PeriodoProdes(2018, 2019, 1027.4),
      PeriodoProdes(2019, 2020, 888.6),
      PeriodoProdes(2020, 2021, 1526.6),
      PeriodoProdes(2021, 2022, 755.3),
      PeriodoProdes(2022, 2023, 654.6),
      PeriodoProdes(2023, 2024, 524.2),
      PeriodoProdes(2024, 2025, 305.5),
    ],
    acumulado: [
      (fim: 2000, km2: 79985.2),
      (fim: 2004, km2: 91449.2),
      (fim: 2006, km2: 95457.9),
      (fim: 2008, km2: 98357.3),
      (fim: 2010, km2: 100413.2),
      (fim: 2011, km2: 102113.0),
      (fim: 2013, km2: 104364.9),
      (fim: 2014, km2: 106483.6),
      (fim: 2016, km2: 108332.4),
      (fim: 2017, km2: 109258.3),
      (fim: 2018, km2: 110176.1),
      (fim: 2019, km2: 111203.5),
      (fim: 2020, km2: 112092.1),
      (fim: 2021, km2: 113618.6),
      (fim: 2022, km2: 114373.9),
      (fim: 2023, km2: 115028.5),
      (fim: 2024, km2: 115552.7),
      (fim: 2025, km2: 115858.2),
    ],
  ),
};

const taxasAmazoniaLegal = <TaxaAnual>[
  TaxaAnual(1988, 21050),
  TaxaAnual(1989, 17770),
  TaxaAnual(1990, 13730),
  TaxaAnual(1991, 11030),
  TaxaAnual(1992, 13786),
  TaxaAnual(1993, 14896),
  TaxaAnual(1994, 14896),
  TaxaAnual(1995, 29059),
  TaxaAnual(1996, 18161),
  TaxaAnual(1997, 13227),
  TaxaAnual(1998, 17383),
  TaxaAnual(1999, 17259),
  TaxaAnual(2000, 18226),
  TaxaAnual(2001, 18165),
  TaxaAnual(2002, 21650),
  TaxaAnual(2003, 25396),
  TaxaAnual(2004, 27772),
  TaxaAnual(2005, 19014),
  TaxaAnual(2006, 14286),
  TaxaAnual(2007, 11651),
  TaxaAnual(2008, 12911),
  TaxaAnual(2009, 7464),
  TaxaAnual(2010, 7000),
  TaxaAnual(2011, 6418),
  TaxaAnual(2012, 4571),
  TaxaAnual(2013, 5891),
  TaxaAnual(2014, 5012),
  TaxaAnual(2015, 6207),
  TaxaAnual(2016, 7893),
  TaxaAnual(2017, 6947),
  TaxaAnual(2018, 7536),
  TaxaAnual(2019, 10129),
  TaxaAnual(2020, 10851),
  TaxaAnual(2021, 13038),
  TaxaAnual(2022, 11594),
  TaxaAnual(2023, 9064),
  TaxaAnual(2024, 6518),
  TaxaAnual(2025, 5731),
  TaxaAnual(2026, 3335, preliminar: true),
];
