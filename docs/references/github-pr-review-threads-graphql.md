# GitHub GraphQL API: PR review threads

Используется для автоматизации "Разбор PR-ревью" из feature-workflow.
Через `gh api graphql`, репозиторий берём из `gh pr view --json headRefName`
или явно `owner/name`.

## Список тредов (с пагинацией)

```graphql
query {
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: N) {
      reviewThreads(first: 100) {
        pageInfo { hasNextPage endCursor }
        totalCount
        nodes {
          id
          isResolved
          path
          line
          comments(first: 20) {
            nodes { author { login } body createdAt }
          }
        }
      }
    }
  }
}
```

**Важно:** `first` ограничен 100 максимум за запрос. Если `totalCount` >
числа полученных nodes (или `pageInfo.hasNextPage == true`) — нужно повторить
запрос с `after: "<endCursor>"`, иначе часть тредов (в т.ч. нерешённых)
молча потеряется. На PR #1 в этом проекте было 135 тредов — 35 нерешённых
лежали именно на второй странице.

## Резолв треда (справочно, Claude его не вызывает)

Тред резолвит только инициатор (ревьюер), когда его устроит ответ или правки.
По правилу feature-workflow Claude не резолвит тред ни до комментария, ни после
него. Мутация ниже приведена только как справка по API.

```graphql
mutation {
  resolveReviewThread(input: {threadId: "PRRT_..."}) {
    thread { id isResolved }
  }
}
```

## Ответ в тред (после одобрения текста владельцем, коротким комментарием)

Черновик комментария сначала показывается владельцу, публикуется только после его
одобрения. Тред при этом остаётся нерешённым.

```graphql
mutation($body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: "PRRT_...", body: $body}) {
    comment { id url }
  }
}
```

Передавать `body` через `-f body="..."` в `gh api graphql`, не инлайнить в
строку запроса (лишние кавычки/переносы строк ломают запрос).

Была старая жалоба в community-дискуссии, что `addPullRequestReviewThreadReply`
не существует — на практике мутация отработала штатно (проверено 2026-09-14).

Sources:
- [using pagination in the graphql api](https://docs.github.com/en/enterprise-server@3.14/graphql/guides/using-pagination-in-the-graphql-api)
- [addPullRequestReviewThreadReply is missing · community · Discussion #59924](https://github.com/orgs/community/discussions/59924)
