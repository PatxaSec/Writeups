
```
.tables = SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;

.indexes = SELECT name FROM sqlite_master WHERE type='index' ORDER BY name;

.schema = SELECT sql FROM sqlite_master WHERE type IN ('table', 'index', 'trigger') ORDER BY name;
```
