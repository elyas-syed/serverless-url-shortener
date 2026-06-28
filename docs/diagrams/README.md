# Diagrams

Architecture diagrams for this project, authored as [Eraser diagram-as-code](https://docs.eraser.io/docs/diagram-as-code).

## Files

| File | Description |
|------|-------------|
| [url-shortener-architecture.eraser](url-shortener-architecture.eraser) | AWS serverless architecture (CloudFront, Lambda, DynamoDB, SQS) |
| [Exported image](../../assets/images/architecture.png) | High-res horizontal PNG for README and blog posts |

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

## Export for README and blog

- **File:** `assets/images/architecture.png` (5239×1608, horizontal layout)
- **Medium / blog:** upload `architecture.png` directly, or use the [raw GitHub URL](https://raw.githubusercontent.com/elyas-syed/aws-url-shortner/main/assets/images/architecture.png) after merge
- **Re-export:** Eraser MCP `export_diagram` with `imageQuality: 3`, `theme: light`, `format: png`
