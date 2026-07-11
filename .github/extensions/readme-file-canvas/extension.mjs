// Extension: readme-file-canvas
// Renders a markdown file in a local canvas so the agent can review README-like
// content without leaving the CLI experience.

import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { joinSession, createCanvas } from "@github/copilot-sdk/extension";

const servers = new Map();
const defaultReadmePath = "production-ready/aks/README.md";
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..", "..");

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function resolveFilePath(input) {
    const rawPath = input?.filePath || defaultReadmePath;
    return path.resolve(repoRoot, rawPath);
}

function renderHtml(instanceId, filePath, content) {
    return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${escapeHtml(path.basename(filePath))}</title>
    <style>
      body {
        margin: 0;
        font-family: var(--font-sans, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif);
        background: var(--background-color-default, #ffffff);
        color: var(--text-color-default, #1f2328);
        padding: 1rem;
      }
      .header {
        display: flex;
        flex-wrap: wrap;
        justify-content: space-between;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 1rem;
      }
      .badge {
        font-size: 0.8rem;
        color: var(--text-color-muted, #656d76);
      }
      pre {
        margin: 0;
        padding: 1rem;
        border: 1px solid var(--border-color-default, #d0d7de);
        border-radius: 0.5rem;
        overflow: auto;
        background: var(--background-color-muted, #f6f8fa);
        white-space: pre-wrap;
        word-break: break-word;
      }
    </style>
  </head>
  <body>
    <div class="header">
      <div>
        <h1 style="margin: 0;">${escapeHtml(path.basename(filePath))}</h1>
        <div class="badge">${escapeHtml(filePath)}</div>
      </div>
      <div class="badge">instance: ${escapeHtml(instanceId)}</div>
    </div>
    <pre>${escapeHtml(content)}</pre>
  </body>
</html>`;
}

async function startServer(instanceId, filePath) {
    const entry = { server: null, url: "", filePath };
    const server = createServer((req, res) => {
        void (async () => {
            try {
                const content = await readFile(entry.filePath, "utf8");
                res.setHeader("Content-Type", "text/html; charset=utf-8");
                res.end(renderHtml(instanceId, entry.filePath, content));
            } catch (error) {
                res.statusCode = 500;
                res.setHeader("Content-Type", "text/plain; charset=utf-8");
                res.end(`Unable to read ${entry.filePath}: ${error.message}`);
            }
        })();
    });

    await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
    const address = server.address();
    const port = typeof address === "object" && address ? address.port : 0;
    entry.server = server;
    entry.url = `http://127.0.0.1:${port}/`;
    return entry;
}

const session = await joinSession({
    canvases: [
        createCanvas({
            id: "readme-file-canvas",
            displayName: "README file canvas",
            description: "Preview a repository README file in a canvas.",
            inputSchema: {
                type: "object",
                properties: {
                    filePath: {
                        type: "string",
                        description: "Path to a markdown file to render. Defaults to production-ready/aks/README.md.",
                    },
                },
                additionalProperties: false,
            },
            actions: [
                {
                    name: "refresh",
                    description: "Reload the currently selected README file from disk.",
                    inputSchema: {
                        type: "object",
                        properties: {
                            filePath: {
                                type: "string",
                                description: "Optional override for the file to render.",
                            },
                        },
                        additionalProperties: false,
                    },
                    handler: async (ctx) => {
                        const entry = servers.get(ctx.instanceId);
                        if (!entry) {
                            return { ok: false, message: "No active canvas instance found." };
                        }
                        const filePath = resolveFilePath(ctx.input || {});
                        entry.filePath = filePath;
                        return { ok: true, filePath };
                    },
                },
            ],
            open: async (ctx) => {
                const filePath = resolveFilePath(ctx.input || {});
                let entry = servers.get(ctx.instanceId);
                if (!entry) {
                    entry = await startServer(ctx.instanceId, filePath);
                    entry.filePath = filePath;
                    servers.set(ctx.instanceId, entry);
                } else {
                    entry.filePath = filePath;
                }
                return {
                    title: path.basename(filePath),
                    url: entry.url,
                };
            },
            onClose: async (ctx) => {
                const entry = servers.get(ctx.instanceId);
                if (entry) {
                    servers.delete(ctx.instanceId);
                    await new Promise((resolve) => entry.server.close(() => resolve()));
                }
            },
        }),
    ],
});
