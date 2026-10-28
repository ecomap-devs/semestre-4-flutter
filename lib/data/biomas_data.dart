import 'package:latlong2/latlong.dart';

import '../models/bioma.dart';
import 'biomas_contornos.dart';
import 'prodes_data.dart';

/// Os seis biomas terrestres.
///
/// Os contornos sao o limite oficial do IBGE (`biomas_contornos.dart`, gerado
/// por `tool/biomas/gerar.mjs`); area e percentual desmatado vem do PRODES
/// (`prodes_data.dart`). Ate 28/10/2026 eram valores de referencia herdados
/// do React, e a Amazonia aparecia 78% desmatada. A descricao ainda e a do
/// `biomesData` do Mapa.jsx.
final biomas = <Bioma>[
  _bioma(
    'Amazônia',
    'Maior floresta tropical do mundo',
    amazoniaContornos,
    amazoniaBuracos,
  ),
  _bioma(
    'Cerrado',
    'Savana tropical com grande biodiversidade',
    cerradoContornos,
    cerradoBuracos,
  ),
  _bioma(
    'Caatinga',
    'Vegetação seca adaptada ao semiárido',
    caatingaContornos,
    caatingaBuracos,
  ),
  _bioma(
    'Mata Atlântica',
    'Floresta costeira altamente ameaçada',
    mataAtlanticaContornos,
    mataAtlanticaBuracos,
  ),
  _bioma(
    'Pantanal',
    'Maior planície alagada do mundo',
    pantanalContornos,
    pantanalBuracos,
  ),
  _bioma(
    'Pampa',
    'Campos nativos do Sul do Brasil',
    pampaContornos,
    pampaBuracos,
  ),
];

Bioma _bioma(
  String nome,
  String descricao,
  List<List<LatLng>> poligonos,
  List<List<LatLng>> buracos,
) {
  final medido = prodes[nome];
  // Bioma sem dado e erro de copia, nao algo para mostrar como "0%".
  if (medido == null) {
    throw StateError('Sem dados do PRODES para "$nome" em prodes_data.dart');
  }
  return Bioma(
    nome: nome,
    areaKm2: medido.areaKm2,
    percentualDesmatado: (medido.acumuladoKm2 / medido.areaKm2 * 100).round(),
    descricao: descricao,
    poligonos: poligonos,
    buracos: buracos,
  );
}
