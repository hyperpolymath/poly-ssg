// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

import * as path from 'path';
import * as vscode from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext) {
  console.log('PolySSG extension activated');

  // Get configuration
  const config = vscode.workspace.getConfiguration('poly-ssg');
  const customPath = config.get<string>('lsp.path');
  const args = config.get<string[]>('lsp.args', []);

  // Server options
  const serverOptions: ServerOptions = {
    command: customPath || 'mix',
    args: customPath ? args : ['run', '--no-halt'],
    options: {
      cwd: customPath ? path.dirname(customPath) : undefined
    }
  };

  // Client options
  const clientOptions: LanguageClientOptions = {
    // Register the server for markdown, TOML, YAML files
    documentSelector: [
      { scheme: 'file', language: 'markdown' },
      { scheme: 'file', language: 'toml' },
      { scheme: 'file', language: 'yaml' }
    ],
    synchronize: {
      // Notify the server about file changes to SSG config files
      fileEvents: vscode.workspace.createFileSystemWatcher(
        '**/{config.toml,config.yaml,_config.yml,book.toml,config.md,site.hs}'
      )
    }
  };

  // Create the language client
  client = new LanguageClient(
    'poly-ssg',
    'PolySSG Language Server',
    serverOptions,
    clientOptions
  );

  // Register commands
  context.subscriptions.push(
    vscode.commands.registerCommand('poly-ssg.build', async () => {
      await client.sendRequest('workspace/executeCommand', {
        command: 'poly-ssg.build',
        arguments: []
      });
      vscode.window.showInformationMessage('Building site...');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('poly-ssg.serve', async () => {
      const result = await client.sendRequest<{ port: number }>(
        'workspace/executeCommand',
        {
          command: 'poly-ssg.serve',
          arguments: []
        }
      );
      vscode.window.showInformationMessage(
        `Dev server started on port ${result.port || 'unknown'}`
      );
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('poly-ssg.clean', async () => {
      await client.sendRequest('workspace/executeCommand', {
        command: 'poly-ssg.clean',
        arguments: []
      });
      vscode.window.showInformationMessage('Build artifacts cleaned');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('poly-ssg.restartServer', async () => {
      await client.stop();
      await client.start();
      vscode.window.showInformationMessage('LSP server restarted');
    })
  );

  // Start the client (this will also launch the server)
  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
}
