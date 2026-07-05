# WireMock Advanced Configuration: Empty Pages & Header Metadata

This documentation demonstrates how to handle advanced pagination scenarios in WireMock, specifically covering requests for non-existent pages (empty pages) and API architectures that return pagination metadata inside HTTP response headers instead of the JSON payload body.

---

## 1. Requesting a Non-Existent Page (Empty Array Response)

When a client requests a page number that exceeds the total number of available records, the API should return a successful HTTP `200 OK` status, but with an empty JSON array.

### Mapping File
Create this file at `mocks/mappings/get-users-empty-page.json`. This mapping matches queries for page 99.

```json
{
  "request": {
    "method": "GET",
    "urlPath": "/api/v1/users",
    "queryParameters": {
      "page": {
        "equalTo": "99"
      }
    }
  },
  "response": {
    "status": 200,
    "jsonBody": {
      "content": [],
      "pagination": {
        "currentPage": 99,
        "pageSize": 3,
        "totalPages": 5,
        "totalElements": 15,
        "isFirstPage": false,
        "isLastPage": true
      }
    },
    "headers": {
      "Content-Type": "application/json"
    }
  }
}
```

---

## 2. Pagination Metadata Delivered in HTTP Headers

Many REST frameworks (such as GitHub's API or certain spring-data-rest configurations) optimize payloads by placing pagination metadata inside custom HTTP headers or standard `Link` headers, keeping the response body strictly as a clean JSON array.

### Response Body File
Create this file at `mocks/__files/users-clean-array.json`. Notice it contains only the array layer without any surrounding wrapper objects.

```json
[
  {
    "id": "123",
    "username": "john.devops",
    "email": "john.doe@company.com",
    "role": "SOFTWARE_ENGINEER",
    "status": "ACTIVE"
  },
  {
    "id": "124",
    "username": "jane.qa",
    "email": "jane.smith@company.com",
    "role": "QA_ENGINEER",
    "status": "ACTIVE"
  }
]
```

### Mapping File
Create this file at `mocks/mappings/get-users-header-pagination.json`. This configuration uses the `headers` block to inject custom pagination fields and a standard RFC 5988 `Link` header for navigational relation links.

```json
{
  "request": {
    "method": "GET",
    "urlPath": "/api/v2/users",
    "queryParameters": {
      "page": {
        "equalTo": "2"
      },
      "size": {
        "equalTo": "2"
      }
    }
  },
  "response": {
    "status": 200,
    "bodyFileName": "users-clean-array.json",
    "headers": {
      "Content-Type": "application/json",
      "X-Page-Number": "2",
      "X-Page-Size": "2",
      "X-Total-Pages": "10",
      "X-Total-Elements": "20",
      "Link": "</api/v2/users?page=1&size=2>; rel=\"prev\", </api/v2/users?page=3&size=2>; rel=\"next\", </api/v2/users?page=10&size=2>; rel=\"last\""
    }
  }
}
```

---

## 3. Dynamic Response Using Response Templating

If you want a single file to handle multiple pages dynamically using the global response templating feature enabled in your `docker-compose.yaml`, you can extract query parameters directly into the headers or body.

### Dynamic Mapping File
Create this file at `mocks/mappings/get-users-dynamic.json`. It will mirror whatever page parameter the client sends directly back into the response headers.

```json
{
  "request": {
    "method": "GET",
    "urlPath": "/api/v3/users"
  },
  "response": {
    "status": 200,
    "body": "[]",
    "headers": {
      "Content-Type": "application/json",
      "X-Requested-Page": "{{request.query.page}}",
      "X-Requested-Size": "{{request.query.size}}"
    }
  }
}
```

---

## Testing Verification

After saving these files, restart your container environment:

```bash
docker compose down && docker compose up -d
```

### Test Empty Page
```bash
curl -i -X GET "http://localhost:8089/api/v1/users?page=99"
```

### Test Header-Based Metadata Page
```bash
curl -i -X GET "http://localhost:8089/api/v2/users?page=2&size=2"
```
The `-i` flag ensures that the shell output displays the custom HTTP headers (`X-Page-Number`, `Link`, etc.) alongside the response array body.