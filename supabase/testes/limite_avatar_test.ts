// O SQL do limite de fotos de perfil (supabase/limite-avatar.sql) num Postgres
// de verdade, em WebAssembly (PGlite), com os papeis e os privilegios padrao do
// Supabase. Mesmo arranjo de limite_identificacao_test.ts.
//
//   deno test --allow-read --allow-env supabase/testes

import { deepStrictEqual, equal } from "node:assert/strict";

import { PGlite } from "npm:@electric-sql/pglite@0.2.17";

const SQL = await Deno.readTextFile(
  new URL("../limite-avatar.sql", import.meta.url),
);

/** Banco novo, com os papeis do Supabase e o SQL aplicado. */
async function bancoNovo(): Promise<PGlite> {
  const db = new PGlite();
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create role service_role nologin bypassrls;
    grant usage on schema public to anon, authenticated, service_role;
    alter default privileges in schema public
      grant all on tables to anon, authenticated, service_role;
    alter default privileges in schema public
      grant all on functions to anon, authenticated, service_role;
  `);
  await db.exec(SQL);
  return db;
}

async function chamar(db: PGlite, uid: string): Promise<string> {
  const r = await db.query<{ v: string }>(
    "select public.registrar_avatar($1, 5) as v",
    [uid],
  );
  return r.rows[0].v;
}

async function noDia(db: PGlite, uid: string): Promise<number> {
  const r = await db.query<{ no_dia: number }>(
    "select no_dia from public.uso_avatar where uid = $1",
    [uid],
  );
  return r.rows[0].no_dia;
}

Deno.test("avatar: aplicar o SQL duas vezes nao quebra", async () => {
  const db = await bancoNovo();
  await db.exec(SQL);
  await db.close();
});

Deno.test("avatar: a 6a foto do dia e recusada e nao conta", async () => {
  const db = await bancoNovo();
  await db.exec("set role service_role");
  const vereditos = [];
  for (let i = 0; i < 6; i++) vereditos.push(await chamar(db, "a"));
  deepStrictEqual(vereditos, ["ok", "ok", "ok", "ok", "ok", "limite-dia"]);
  equal(await noDia(db, "a"), 5);
  equal(await chamar(db, "b"), "ok", "outra pessoa tem o proprio limite");
  await db.close();
});

Deno.test("avatar: o dia seguinte comeca do zero", async () => {
  const db = await bancoNovo();
  await db.exec("set role service_role");
  for (let i = 0; i < 5; i++) await chamar(db, "a");
  equal(await chamar(db, "a"), "limite-dia");

  await db.exec("update public.uso_avatar set dia = dia - 1 where uid = 'a'");
  equal(await chamar(db, "a"), "ok");
  equal(await noDia(db, "a"), 1);
  await db.close();
});

// As duas camadas, cada uma pela propria mensagem. A funcao roda com os
// privilegios de quem chama: sem o `revoke execute`, o anon ainda esbarraria na
// tabela, e um teste que so procurasse "permission denied" passaria do mesmo
// jeito (a contraprova de 10/11/2026 mostrou isso). Por isso a mensagem certa.
Deno.test("avatar: anon e authenticated nao chamam a funcao nem tocam na tabela", async () => {
  const db = await bancoNovo();
  const tentar = async (sql: string) => {
    try {
      await db.query(sql);
      return "permitido";
    } catch (e) {
      const negado = String(e).match(/permission denied for (function|table)/);
      return negado ? `negado: ${negado[1]}` : String(e);
    }
  };
  for (const papel of ["anon", "authenticated"]) {
    await db.exec(`reset role; set role ${papel}`);
    equal(
      await tentar("select public.registrar_avatar('x', 999)"),
      "negado: function",
      `${papel} executou a funcao`,
    );
    equal(
      await tentar("select * from public.uso_avatar"),
      "negado: table",
      `${papel} leu a tabela`,
    );
    equal(
      await tentar("update public.uso_avatar set no_dia = 0"),
      "negado: table",
      `${papel} zerou o uso`,
    );
  }
  await db.close();
});
