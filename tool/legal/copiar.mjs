// Gera lib/data/legal_data.dart a partir do src/dados/legal.ts do site: a
// politica de privacidade e os termos de uso, com as mesmas strings.
//
// O texto e um so para o site e o app, e mora no site. Copiar a mao ja deixou o
// app para tras uma vez (o DETER e a denuncia, 29/10/2026); este script troca a
// copia a mao por uma conferivel.
//
// Como refazer (Node 22.6+, que le TypeScript sem compilar):
//
//   node tool/legal/copiar.mjs ../../"Quarto Semestre - Next.js"/semestre-4-nextjs
//   dart format lib/data/legal_data.dart
//
// O argumento e a pasta do clone do semestre-4-nextjs.

import { writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const site = process.argv[2];
if (!site) {
  console.error("uso: node tool/legal/copiar.mjs <pasta do semestre-4-nextjs>");
  process.exit(1);
}
const legal = await import(pathToFileURL(resolve(site, "src/dados/legal.ts")).href);

/** String do Dart entre aspas simples, sem interpolacao. */
const dart = (texto) => `'${texto.replaceAll("\\", "\\\\").replaceAll("'", "\\'").replaceAll("$", "\\$").replaceAll("\n", "\\n")}'`;
const lista = (itens, recuo) => `[\n${itens.map((i) => `${recuo}  ${i},`).join("\n")}\n${recuo}]`;

function bloco(b, recuo) {
  if (b.tipo === "paragrafo") return `ParagrafoLegal(${dart(b.texto)})`;
  if (b.tipo === "lista") return `ListaLegal(${lista(b.itens.map(dart), recuo)})`;
  if (b.tipo === "tabela") {
    const linhas = b.linhas.map((l) => lista(l.map(dart), recuo + "    "));
    return `TabelaLegal(\n${recuo}  colunas: ${lista(b.colunas.map(dart), recuo + "  ")},\n${recuo}  linhas: ${lista(linhas, recuo + "  ")},\n${recuo})`;
  }
  throw new Error(`bloco desconhecido: ${b.tipo}`);
}

function documento(nome, d) {
  const secoes = d.secoes.map(
    (s) =>
      `    SecaoLegal(\n      id: ${dart(s.id)},\n      titulo: ${dart(s.titulo)},\n      blocos: ${lista(
        s.blocos.map((b) => bloco(b, "        ")),
        "      ",
      )},\n    )`,
  );
  return `const ${nome} = DocumentoLegal(\n  titulo: ${dart(d.titulo)},\n  descricao: ${dart(d.descricao)},\n  abertura: ${dart(d.abertura)},\n  secoes: [\n${secoes.join(",\n")},\n  ],\n);\n`;
}

const saida = `// GERADO por tool/legal/copiar.mjs a partir do src/dados/legal.ts do
// semestre-4-nextjs. Nao edite a mao: mude o texto no site e copie de novo.
//
// A politica de privacidade e os termos de uso valem para o site e para o app.

import '../models/documento_legal.dart';

/// A data da versao em vigor dos dois documentos.
const atualizadoEm = ${dart(legal.ATUALIZADO_EM)};

/// Onde fazer pedidos sobre dados: issue publica, com o modelo que avisa para
/// nao escrever dado pessoal.
const contatoDados = ${dart(legal.CONTATO_DADOS)};

${documento("privacidade", legal.privacidade)}
${documento("termos", legal.termos)}`;

const destino = new URL("../../lib/data/legal_data.dart", import.meta.url);
writeFileSync(destino, saida);
console.log(`ok: ${legal.privacidade.secoes.length} seções de privacidade, ${legal.termos.secoes.length} de termos, versão de ${legal.ATUALIZADO_EM}`);
