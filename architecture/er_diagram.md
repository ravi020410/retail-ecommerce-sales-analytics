# Er Diagram

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    PRODUCTS ||--o{ ORDERS : contains
    REGIONS ||--o{ ORDERS : serves
    ORDERS ||--o{ RETURNS : may_return
    REGIONS ||--o{ MARKETING_SPEND : receives
```
