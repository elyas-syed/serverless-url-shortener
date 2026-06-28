# Diagrams

Architecture diagrams for this project, authored as [Eraser diagram-as-code](https://docs.eraser.io/docs/diagram-as-code).

## Files

| File | Description |
|------|-------------|
| [url-shortener-architecture.eraser](url-shortener-architecture.eraser) | AWS serverless architecture (CloudFront, Lambda, DynamoDB, SQS) |
| [Exported image](../../assets/images/architecture.jpg) | Rendered diagram for docs (from Eraser) |

## Live diagram in Eraser

**[Open in Eraser → AWS URL Shortener Architecture](https://app.eraser.io/workspace/NjIOU5jPmHgeOj4OvVmO?diagram=r8o0_JSJPUNXFo8IWrvh&layout=canvas)**

Edit the diagram in the browser, or update `url-shortener-architecture.eraser` in this repo and re-import.

## View or edit from source

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

Exported diagram: `assets/images/architecture.jpg`. Re-export after edits via Eraser MCP (`export_diagram`) or download from the [live workspace](https://app.eraser.io/workspace/NjIOU5jPmHgeOj4OvVmO?diagram=r8o0_JSJPUNXFo8IWrvh&layout=canvas).
