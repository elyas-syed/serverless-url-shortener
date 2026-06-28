# Diagrams

Architecture diagrams for this project, authored as [Eraser diagram-as-code](https://docs.eraser.io/docs/diagram-as-code).

## Files

| File | Description |
|------|-------------|
| [url-shortener-architecture.eraser](url-shortener-architecture.eraser) | AWS serverless architecture (CloudFront, Lambda, DynamoDB, SQS) |

## View or edit in Eraser

1. Open [Eraser](https://app.eraser.io)
2. Create a new file → **Diagram as code**
3. Paste the contents of `url-shortener-architecture.eraser`

Or import the file if your Eraser plan supports it.

## Eraser MCP (Cursor)

The [Eraser MCP server](https://docs.eraser.io/docs/mcp) lets Cursor generate, edit, and export diagrams from chat.

**Remote server (OAuth):** added to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "eraser": {
      "url": "https://app.eraser.io/api/mcp"
    }
  }
}
```

After adding the server:

1. Reload Cursor (**Settings → MCP** or restart)
2. Approve OAuth in the browser when prompted
3. Ask the agent to generate or export diagrams using Eraser tools

**Local server (API key):** for CI or headless use, see [Eraser MCP FAQ](https://docs.eraser.io/docs/mcp) and `@eraserlabs/eraser-mcp` on npm.

## Export to README

Once connected via MCP, you can export a diagram to PNG/JPEG and save it under `assets/images/` for the root README (same folder as the web UI screenshot).
