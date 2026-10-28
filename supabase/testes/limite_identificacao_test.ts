// O SQL do limite por pessoa (supabase/limite-identificacao.sql) rodando num
// Postgres de verdade, em WebAssembly (PGlite), com os papeis e os privilegios
// padrao do Supabase.
//
//   deno test --allow-read --allow-env supabase/testes
//
// Nao cobre a disputa entre dois pedidos simultaneos da mesma pessoa: o PGlite
// tem uma conexao so. Quem cuida disso e o `for update` da funcao.

import { deepStrictEqual, equal } from "node:assert/strict";

import { PGlite } from "npm:@electric-sql/pglite@0.2.17";

const SQL = await Deno.readTextFile(
  new URL("../limite-identificacao.sql", import.meta.url),
);

/** Banco novo, com os papeis do Supabase e o SQL aplicado. */
async function bancoNovo(): Promise<PGlite> {
  const db = new PGlite();
  // Como no Supabase: service_role ignora RLS, e os privilegios padrao dao tudo
  // em tabela e funcao nova do schema public aos tres papeis. E contra isso
  // que os `revoke` do arquivo precisam valer.
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
    "select public.registrar_identificacao($1, 5, 30) as v",
    [uid],
  );
  return r.rows[0].v;
}

async function uso(db: PGlite, uid: string) {
  const r = await db.query<{ no_minuto: number; no_dia: number }>(
    "select no_minuto, no_dia from public.uso_identificacao where uid = $1",
    [uid],
  );
  return r.rows[0];
}

Deno.test("aplicar o SQL duas vezes nao quebra", async () => {
  const db = await bancoNovo();
  await db.exec(SQL);
  await db.close();
});

Deno.test("limite por minuto: o 6o pedido e recusado e nao conta", async () => {
  const db = await bancoNovo();
  await db.exec("set role service_role");
  const vereditos = [];
  for (let i = 0; i < 6; i++) vereditos.push(await chamar(db, "a"));
  deepStrictEqual(vereditos, ["ok", "ok", "ok", "ok", "ok", "limite-minuto"]);
  deepStrictEqual(await uso(db, "a"), { no_minuto: 5, no_dia: 5 });
  equal(await chamar(db, "b"), "ok", "outra pessoa tem o proprio limite");

  await db.exec(
    "update public.uso_identificacao set minuto = minuto - interval '1 minute' where uid = 'a'",
  );
  equal(await chamar(db, "a"), "ok");
  deepStrictEqual(await uso(db, "a"), { no_minuto: 1, no_dia: 6 });
  await db.close();
});

Deno.test("limite por dia: recusa ate o dia seguinte", async () => {
  const db = await bancoNovo();
  await db.exec("set role service_role");
  await chamar(db, "a");
  await db.exec(
    "update public.uso_identificacao set no_dia = 30 where uid = 'a'",
  );
  equal(await chamar(db, "a"), "limite-dia");
  deepStrictEqual(await uso(db, "a"), { no_minuto: 1, no_dia: 30 });

  await db.exec(
    "update public.uso_identificacao set dia = dia - 1 where uid = 'a'",
  );
  equal(await chamar(db, "a"), "ok");
  deepStrictEqual(await uso(db, "a"), { no_minuto: 2, no_dia: 1 });
  await db.close();
});

Deno.test("anon e authenticated nao chamam a funcao nem tocam na tabela", async () => {
  const db = await bancoNovo();
  const tentar = async (sql: string) => {
    try {
      await db.query(sql);
      return "permitido";
    } catch (e) {
      return /permission denied/.test(String(e)) ? "negado" : String(e);
    }
  };
  for (const papel of ["anon", "authenticated"]) {
    await db.exec(`reset role; set role ${papel}`);
    equal(
      await tentar("select public.registrar_identificacao('x', 999, 999)"),
      "negado",
      `${papel} executou a funcao`,
    );
    equal(
      await tentar("select * from public.uso_identificacao"),
      "negado",
      `${papel} leu a tabela`,
    );
    equal(
      await tentar("update public.uso_identificacao set no_dia = 0"),
      "negado",
      `${papel} zerou o uso`,
    );
  }
  await db.close();
});
