---
name: api-design
description: REST, OpenAPI, and GraphQL API design best practices, payload schemas, and error structures.
---

# API Design Skill

Use this skill when designing, reviewing, or generating backend APIs, schemas, and endpoint contracts.

## 1. RESTful URL Conventions
- Use nouns in plural form for resource collections: `/api/v1/models`, `/api/v1/sessions`.
- Use standard HTTP methods:
  - `GET`: Retrieve resource(s) (idempotent, safe)
  - `POST`: Create a new resource
  - `PUT`: Replace an entire resource
  - `PATCH`: Partially modify an existing resource
  - `DELETE`: Remove a resource

## 2. Standardized Error Response Envelope
Always return structured JSON errors with consistent fields:

```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "The provided API key is invalid or has expired.",
    "details": [
      {
        "field": "apiKey",
        "issue": "Must match pattern ^sk-or-"
      }
    ]
  }
}
```

## 3. Pagination & Filtering
- Support query parameters: `?page=1&limit=20` or cursor-based `?cursor=xyz&limit=20`.
- Include metadata in paginated responses (`total`, `hasMore`, `nextCursor`).
