# Exemplo Aula 13 — Biblioteca

Projeto didático de uma API para livros, evoluído do CRUD da AP1 para persistência com Entity Framework Core/SQLite e uma interface web integrada (escopo da AP2). A aula acrescenta tratamento centralizado de exceções com uma resposta pública genérica.

> Use este repositório para acompanhar a implementação em aula. Cada estudante deve aplicar a mesma ideia no próprio projeto, preservando o recurso e os campos escolhidos na AP1/AP2; não substitua seu projeto pelo exemplo de livros.

## Repositório para a prática

A branch [`ap2-base`](https://github.com/lucasfogacadj/exemplo-aula13-biblioteca/tree/ap2-base) é o ponto de partida com o CRUD da AP2, antes do middleware. A branch `main` contém a versão final da Aula 13. O fluxo de implementação da aula começa em `ap2-base`; compare com `main` somente depois de tentar.

## Requisitos e execução

- .NET SDK 10
- Na raiz do repositório: `dotnet run`
- Abra a URL local informada no terminal. A página da biblioteca é servida pela própria aplicação.
- O banco SQLite `biblioteca.db` é criado automaticamente na primeira execução e fica local (ignorado pelo Git).

## Rotas da API

| Método | Rota | Resultado |
| --- | --- | --- |
| GET | `/api/livros` | Lista livros |
| GET | `/api/livros/{id}` | Busca por ID; 404 se não existir |
| POST | `/api/livros` | Cadastra e persiste; 201 |
| PUT | `/api/livros/{id}` | Atualiza e persiste; 200 ou 404 |
| DELETE | `/api/livros/{id}` | Exclui e persiste; 204 ou 404 |

Exemplo de corpo para POST/PUT:

```json
{"titulo":"O Hobbit","autor":"J. R. R. Tolkien","anoPublicacao":1937}
```

## Como conferir o CRUD

1. Abra a interface e cadastre um livro.
2. Edite-o e confira a lista atualizada.
3. Exclua-o e confirme que desapareceu.
4. Cadastre outro livro, pare a aplicação e rode `dotnet run` novamente: o registro não excluído deve continuar na lista.
5. Para testar a API sem a interface, envie GET/POST/PUT/DELETE para as rotas acima em Bruno, Postman ou `curl`.

## Aula 13 — tratamento de exceções

`Program.cs` registra `UseExceptionHandler` depois de `builder.Build()` e antes dos arquivos estáticos e endpoints. O middleware devolve HTTP 500 e uma mensagem genérica em JSON; não envia detalhes internos ao cliente. A resposta 404 para um livro inexistente continua sendo um resultado esperado, separado de uma exceção.

A rota `/api/teste-erro` existe somente no ambiente automatizado `SmokeTest`, para verificar que o handler devolve 500 genérico sem expor a exceção. Ela não é registrada nos ambientes usuais de desenvolvimento ou produção. Para praticar no seu projeto, acrescente uma rota temporária de teste localmente, remova-a ao terminar e nunca publique uma rota que lança exceção deliberadamente.

## Limites do exemplo

Este é um projeto de demonstração, não uma solução de produção. Não inclui autenticação, autorização, validação abrangente, migrações versionadas ou logging operacional. Não coloque credenciais ou o arquivo do banco no Git. Adapte nomes, campos, endpoints e interface ao seu recurso.
