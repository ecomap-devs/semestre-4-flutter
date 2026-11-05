# Como lançar uma versão do app

Guia para qualquer pessoa do grupo, mesmo quem nunca fez uma release. Você não precisa da
chave de assinatura na sua máquina: basta ter permissão de escrita no repositório, que hoje
os cinco têm. O trabalho manual é pequeno, e o GitHub compila e publica em menos de 10 minutos.

## O que é uma release

Uma release é uma versão numerada do app, publicada na
[página de Releases](https://github.com/ecomap-devs/semestre-4-flutter/releases), com o APK
pronto para instalar. É por ela que alguém recebe o app sem precisar compilar o projeto.

| | Quando acontece | O que gera |
|---|---|---|
| **PR e merge na `main`** | A cada PR e a cada merge | CI e um APK de **debug**, nos artefatos da execução por 14 dias, para o grupo testar |
| **Release** | Quando alguém cria uma tag | APK de **release**, assinado com a chave do projeto, público e permanente |

**O app não se atualiza sozinho.** Um merge não chega a quem já instalou: a pessoa só recebe
as novidades ao instalar o APK de uma release nova.

## Quando lançar

**Lance** quando houver algo que precisa chegar a quem usa o app:

- uma funcionalidade nova ou um conserto;
- dados novos copiados do site, como os alertas do DETER, o PRODES ou as espécies, porque
  esses dados vão dentro do APK;
- uma entrega ou apresentação, para deixar registrada a versão mostrada.

**Não precisa lançar** por causa de:

- documentação, testes ou CI;
- `firestore.rules`, publicadas com `firebase deploy --only firestore:rules`;
- `supabase/`, porque a Edge Function é publicada à mão e vale para todas as versões do app.

## Como escolher o número

A versão fica no `pubspec.yaml`, no formato `X.Y.Z+N`:

| Parte | Quando muda | Exemplo a partir de `1.0.0+1` |
|---|---|---|
| `Z` | Conserto ou dados atualizados | `1.0.1+2` |
| `Y` | Funcionalidade nova (`Z` volta a 0) | `1.1.0+2` |
| `X` | Mudança grande, como uma nova fase do projeto (`Y` e `Z` voltam a 0) | `2.0.0+2` |
| `N` | **Em toda release, sempre para cima** | |

O `N` é o que o Android compara: se ele não crescer, o celular recusa a atualização. Nunca
reaproveite um número, mesmo depois de uma versão com defeito.

A tag leva só `X.Y.Z`, com um `v` na frente: a versão `1.1.0+2` vira a tag `v1.1.0`. Os
números do app e do site são independentes.

## Passo a passo

Os comandos abaixo valem no PowerShell e no Git Bash. No exemplo, a versão é `1.1.0+2`.

**1. Suba a versão num PR.**

```bash
git switch main
git pull
git switch -c feat/versao-1.1.0
```

Mude a linha `version:` do `pubspec.yaml` para `version: 1.1.0+2`, faça o commit, abra o PR e
siga o caminho normal: CI verde, aprovação e merge.

**2. Teste antes.** Instale o APK de debug do PR, que fica nos artefatos da CI. Se você tiver
o app de release instalado, desinstale primeiro: o Android não troca um pelo outro, porque as
assinaturas são diferentes. Depois, confira ao menos o login e o mapa.

**3. Crie a tag na `main`, depois do merge.**

```bash
git switch main
git pull
git tag v1.1.0
git push origin v1.1.0
```

> [!WARNING]
> Crie a tag pelo `git`, **não** pelo botão "Draft a new release" do GitHub. O botão já cria
> uma release, e o workflow para ao tentar criar a dele.

**4. Acompanhe** em [Actions → Release](https://github.com/ecomap-devs/semestre-4-flutter/actions/workflows/release.yml).
Se algo falhar, veja [Se der errado](#se-der-errado). Nenhuma release é criada até o fim do
primeiro job.

**5. Confira o resultado.** Abra a release, baixe o APK e instale num celular. Quem tem o APK
de debug instalado precisa desinstalar antes. As notas saem sozinhas, a partir dos títulos dos
PRs, e podem ser editadas depois para explicar melhor o que mudou.

## O que o workflow confere

O `.github/workflows/release.yml` para, sem publicar nada, se:

- a versão do `pubspec.yaml` não for a da tag;
- a tag não estiver na `main`;
- o `N` não for maior que o da release anterior;
- faltar algum secret;
- algum teste falhar;
- o APK não sair assinado só com o certificado de release.

## Ensaio

Para testar sem publicar, por exemplo depois de mudar o workflow, use uma tag com hífen. A
parte antes do hífen precisa ser a versão do `pubspec.yaml`, e a tag pode estar em qualquer
branch. O workflow que roda é o do commit da tag.

```bash
git tag v1.1.0-rc.1
git push origin v1.1.0-rc.1
```

O resultado é um **rascunho**, visível só para quem tem escrita no repositório, com o APK para
testar. Ele não confere a `main` nem o `N`. Depois, apague tudo:

```bash
gh release delete v1.1.0-rc.1 --cleanup-tag -y
git tag -d v1.1.0-rc.1
```

Sem o `gh`, apague o rascunho na página de Releases e a tag com
`git push origin --delete v1.1.0-rc.1`. Se o ensaio falhou antes de criar o rascunho, só a tag
precisa sair.

O resultado do ensaio aparece no commit: se a tag estiver num commit de PR, um ensaio que
falhar deixa um check vermelho nele. Avise quem for revisar.

## Se der errado

| O que aparece | O que significa | O que fazer |
|---|---|---|
| Nada roda em Actions | A tag não tem o formato `vX.Y.Z` | Apague a tag e crie de novo |
| `A tag é v1.1.0, e o pubspec.yaml diz ...` | A versão não foi subida, ou o PR não entrou | Apague a tag, faça o merge da versão certa e crie de novo |
| `A tag precisa apontar para um commit da main` | A tag foi criada em outra branch | Apague a tag, vá para a `main` atualizada e crie de novo |
| `O número de build (...) precisa ser maior ...` | O `N` não cresceu | Apague a tag, suba o `N` num PR e crie de novo |
| Falha no passo **Testar** | Algum teste quebrou | Conserte num PR, apague a tag e crie de novo |
| `Secrets vazios ou ausentes: ...` | Um secret do repositório sumiu ou está vazio | Recadastre em Settings → Secrets and variables → Actions e rode de novo |
| `A chave de assinatura não está no ambiente release` | A chave sumiu do ambiente | Veja [A chave de assinatura](#a-chave-de-assinatura) e rode de novo |
| `O APK não saiu assinado só com o certificado esperado` | A chave do ambiente não é a do projeto | **Não contorne.** Veja [A chave de assinatura](#a-chave-de-assinatura) |
| Erro de rede ou de download | Falha passageira do GitHub ou de uma dependência | Em Actions, use **Re-run failed jobs** |
| Falha em **Criar a release**, dizendo que ela já existe | Já há uma release com esse número | Se alguém acabou de criá-la pelo botão, apague-a e use **Re-run failed jobs**. Se ela é uma versão já publicada, deixe como está e use outro número |

O APK compilado fica guardado por um dia. Depois disso, **Re-run failed jobs** não encontra o
arquivo: use **Re-run all jobs**, que compila de novo.

**Para apagar uma tag que não virou release:**

```bash
git push origin --delete v1.1.0
git tag -d v1.1.0
```

**Se uma versão publicada tiver defeito,** não mova a tag nem troque o APK: quem baixou precisa
continuar achando o mesmo arquivo, com o mesmo SHA-256. Conserte num PR e lance outra versão,
como `1.1.1+3`. Se o defeito for grave, avise nas notas da versão com problema.

## A chave de assinatura

O APK de release é assinado com `android/keystore/release.jks`, que **nunca entra no
repositório**. Para lançar uma versão, ninguém precisa dela: o workflow usa a cópia guardada no
GitHub.

| Onde está | O que é |
|---|---|
| Ambiente `release` do repositório, em `ANDROID_KEYSTORE_BASE64` e `ANDROID_KEY_PROPERTIES_BASE64` | A cópia usada pelo workflow. O ambiente só aceita tags `v*`, então branches e PRs não têm acesso a ela |
| Máquina de Vinicius | O original, com o `android/key.properties`. O GitHub não deixa ler um secret de volta, então esse é o único jeito de recuperar a chave |

> [!CAUTION]
> **Perder a chave é irreversível.** Sem ela, nenhuma versão nova consegue atualizar o app já
> instalado: cada pessoa teria que desinstalar antes. Mantenha uma cópia em lugar seguro, fora
> do repositório. Não mande a chave nem as senhas por chat ou e-mail.

**Para enviar a chave de novo ao GitHub,** quem tem o original roda, na raiz do projeto, em Git
Bash e com o `gh` autenticado:

```bash
bash tool/release/enviar-chave.sh
```

**Para trocar a chave,** o que deve ser evitado, são quatro passos, porque cada um quebra algo
se faltar:

1. Enviar a chave nova com o script acima.
2. Cadastrar o SHA-1 novo na chave `FIREBASE_API_KEY_ANDROID`, no Google Cloud. Sem isso, o
   login para de funcionar no APK.
3. Trocar `CERTIFICADO_ESPERADO` no `release.yml`, num PR.
4. Avisar quem já instalou que precisa desinstalar o app antes de instalar a versão nova.

**Quem pode lançar:** qualquer pessoa com escrita no repositório. Por decisão de 04/11/2026, o
ambiente `release` não exige aprovação a cada versão. O risco é que uma tag pode apontar para um
workflow alterado para ler a chave. Se o grupo crescer ou a confiança mudar, ligue a aprovação em
Settings → Environments → `release` → Required reviewers.
