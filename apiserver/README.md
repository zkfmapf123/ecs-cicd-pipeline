## Simple Node-Todo App

## Paths

- GET /health

```
    curl localhost:3000/health
```

- GET /todos

```
    curl localhost:3000/todos
```

- POST /todos

```
    curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"title": "test-title", "desc" : "test-desc"}' \
    localhost:3000/todos
```

- PUT /todos

```
    귀찮음
```

- DELETE /todos

```
    curl -X DELETE \
    -H "Content-Type: application/json" \
    -d '{"id": "1"}' \
    localhost:3000/todos
```
