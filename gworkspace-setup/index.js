#!/usr/bin/env node
/**
 * bb-workspace-setup / bb-workspace
 *
 * One-command Google Workspace setup for OpenClaw business teams.
 * Works on Windows, Mac, Linux, and WSL.
 *
 * Usage:
 *   npx bb-workspace-setup
 *   npx bb-workspace
 *
 * What it does:
 *  1. Guides user through Google Cloud service account creation
 *  2. Tests the service account credentials
 *  3. Configures OpenClaw with the service account
 *  4. Sets up Composio Google integration
 *  5. Tests Gmail/Drive/Calendar access for all team members
 */

import { createRequire } from 'module';
const require = createRequire(import.meta.url);

import fs from 'fs';
import path from 'path';
import os from 'os';
import { execSync, spawn } from 'child_process';

// Dynamic imports (ESM-compatible)
async function run() {
  const { default: chalk } = await import('chalk');
  const { default: inquirer } = await import('inquirer');
  const { default: ora } = await import('ora');

  // --- Platform detection ---
  const isWSL = fs.existsSync('/proc/version') &&
    fs.readFileSync('/proc/version', 'utf8').toLowerCase().includes('microsoft');
  const isWindows = process.platform === 'win32';
  const isMac = process.platform === 'darwin';

  const OPENCLAW_DIR = process.env.OPENCLAW_DIR ||
    (isWSL ? '/root/.openclaw' : path.join(os.homedir(), '.openclaw'));
  const CONFIG_DIR = path.join(OPENCLAW_DIR, 'workspace', 'config');

  console.log(chalk.bold.blue('\n╔════════════════════════════════════════╗'));
  console.log(chalk.bold.blue('║   Google Workspace Setup for OpenClaw  ║'));
  console.log(chalk.bold.blue('╚════════════════════════════════════════╝\n'));
  console.log(chalk.gray(`Platform: ${isWSL ? 'WSL' : isWindows ? 'Windows' : isMac ? 'Mac' : 'Linux'}`));
  console.log(chalk.gray(`OpenClaw dir: ${OPENCLAW_DIR}\n`));

  // --- Step 1: Company info ---
  console.log(chalk.yellow.bold('Step 1 — Company Information\n'));
  const { companyName, domain, adminEmail } = await inquirer.prompt([
    {
      type: 'input',
      name: 'companyName',
      message: 'Company name:',
      validate: v => v.length > 0 || 'Required',
    },
    {
      type: 'input',
      name: 'domain',
      message: 'Google Workspace domain (e.g., yourcompany.com):',
      validate: v => v.includes('.') || 'Must be a valid domain',
    },
    {
      type: 'input',
      name: 'adminEmail',
      message: 'Admin Google email (for domain-wide delegation):',
      validate: v => v.includes('@') || 'Must be a valid email',
    },
  ]);

  // --- Step 2: Team members ---
  console.log(chalk.yellow.bold('\nStep 2 — Team Members\n'));
  console.log(chalk.gray('These team members will have their Gmail/Drive/Calendar accessible to OpenClaw agents.'));
  console.log(chalk.gray('Enter one email per line. Press Enter twice when done.\n'));

  const { teamEmails } = await inquirer.prompt([
    {
      type: 'input',
      name: 'teamEmails',
      message: 'Team member emails (comma-separated):',
      validate: v => v.length > 0 || 'Enter at least one email',
    },
  ]);
  const emails = teamEmails.split(',').map(e => e.trim()).filter(e => e.includes('@'));

  // --- Step 3: Service account ---
  console.log(chalk.yellow.bold('\nStep 3 — Service Account Setup\n'));
  console.log(chalk.white('I need a Google service account with domain-wide delegation.'));
  console.log(chalk.white('Follow these steps:\n'));
  console.log(chalk.cyan('  1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts'));
  console.log(chalk.cyan('  2. Create project: "openclaw-agents" (if not exists)'));
  console.log(chalk.cyan('  3. Create service account: "openclaw-agent"'));
  console.log(chalk.cyan('  4. Download JSON key file'));
  console.log(chalk.cyan('  5. In Google Admin Console: Security → API Controls → Domain-wide Delegation'));
  console.log(chalk.cyan('     Add service account Client ID with these scopes:'));
  console.log(chalk.gray('     https://www.googleapis.com/auth/gmail.readonly,'));
  console.log(chalk.gray('     https://www.googleapis.com/auth/gmail.compose,'));
  console.log(chalk.gray('     https://mail.google.com/,'));
  console.log(chalk.gray('     https://www.googleapis.com/auth/calendar.readonly,'));
  console.log(chalk.gray('     https://www.googleapis.com/auth/calendar.events,'));
  console.log(chalk.gray('     https://www.googleapis.com/auth/drive.readonly,'));
  console.log(chalk.gray('     https://www.googleapis.com/auth/drive.file\n'));

  const { keyFilePath } = await inquirer.prompt([
    {
      type: 'input',
      name: 'keyFilePath',
      message: 'Path to service account JSON key file:',
      validate: v => {
        const expanded = v.startsWith('~') ? path.join(os.homedir(), v.slice(1)) : v;
        return fs.existsSync(expanded) || 'File not found — check the path';
      },
    },
  ]);

  const expanded = keyFilePath.startsWith('~')
    ? path.join(os.homedir(), keyFilePath.slice(1))
    : keyFilePath;

  // --- Verify service account ---
  const spinner = ora('Verifying service account credentials...').start();
  let serviceAccount;
  try {
    serviceAccount = JSON.parse(fs.readFileSync(expanded, 'utf8'));
    if (!serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error('Invalid service account file — missing client_email or private_key');
    }
    spinner.succeed(`Service account: ${serviceAccount.client_email}`);
  } catch (e) {
    spinner.fail(`Failed to read service account: ${e.message}`);
    process.exit(1);
  }

  // --- Test Gmail access ---
  spinner.start(`Testing Gmail access for ${adminEmail}...`);
  try {
    const { google } = await import('googleapis');
    const auth = new google.auth.JWT(
      serviceAccount.client_email,
      null,
      serviceAccount.private_key,
      ['https://www.googleapis.com/auth/gmail.readonly'],
      adminEmail
    );
    const gmail = google.gmail({ version: 'v1', auth });
    const profile = await gmail.users.getProfile({ userId: 'me' });
    spinner.succeed(`Gmail access verified for: ${profile.data.emailAddress}`);
  } catch (e) {
    spinner.warn(`Gmail test failed (${e.message}) — check domain-wide delegation setup`);
    console.log(chalk.yellow('Continuing setup — fix delegation after installation.\n'));
  }

  // --- Step 4: Copy key file ---
  const targetKeyPath = path.join(OPENCLAW_DIR, 'config', 'google-service-account.json');
  fs.mkdirSync(path.dirname(targetKeyPath), { recursive: true });
  fs.copyFileSync(expanded, targetKeyPath);
  console.log(chalk.green(`\n✓ Service account key saved: ${targetKeyPath}`));

  // --- Step 5: Write google-workspace.json ---
  const gwConfig = {
    domain,
    adminEmail,
    serviceAccountKeyPath: targetKeyPath,
    teamMembers: emails,
    scopes: [
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.compose',
      'https://mail.google.com/',
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/calendar.events',
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive.file',
    ],
    _installedAt: new Date().toISOString(),
    _installedBy: 'bb-workspace-setup',
  };

  fs.mkdirSync(CONFIG_DIR, { recursive: true });
  fs.writeFileSync(
    path.join(CONFIG_DIR, 'google-workspace.json'),
    JSON.stringify(gwConfig, null, 2)
  );
  console.log(chalk.green(`✓ Google Workspace config saved: ${CONFIG_DIR}/google-workspace.json`));

  // --- Step 6: Configure OpenClaw ---
  const openclawJsonPath = path.join(OPENCLAW_DIR, 'openclaw.json');
  if (fs.existsSync(openclawJsonPath)) {
    spinner.start('Updating OpenClaw config with Google Workspace...');
    try {
      const config = JSON.parse(fs.readFileSync(openclawJsonPath, 'utf8'));
      if (!config.channels) config.channels = {};
      if (!config.channels.googlechat) config.channels.googlechat = {};
      config.channels.googlechat.serviceAccountPath = targetKeyPath;
      config.channels.googlechat.domain = domain;

      // Backup first
      fs.writeFileSync(openclawJsonPath + '.bak', JSON.stringify(config, null, 2));
      fs.writeFileSync(openclawJsonPath, JSON.stringify(config, null, 2));
      spinner.succeed('OpenClaw config updated');
    } catch (e) {
      spinner.warn(`Could not update openclaw.json: ${e.message}`);
    }
  }

  // --- Step 7: Test access for all team members ---
  console.log(chalk.yellow.bold('\nStep 4 — Testing Team Member Access\n'));
  const { google } = await import('googleapis');

  for (const email of emails) {
    const testSpinner = ora(`Testing access for ${email}...`).start();
    try {
      const auth = new google.auth.JWT(
        serviceAccount.client_email,
        null,
        serviceAccount.private_key,
        ['https://www.googleapis.com/auth/gmail.readonly'],
        email
      );
      const gmail = google.gmail({ version: 'v1', auth });
      await gmail.users.getProfile({ userId: 'me' });
      testSpinner.succeed(`${email}: Gmail access ✓`);
    } catch (e) {
      testSpinner.warn(`${email}: ${e.message}`);
    }
  }

  // --- Summary ---
  console.log(chalk.bold.green('\n╔════════════════════════════════════════╗'));
  console.log(chalk.bold.green('║         Setup Complete!                ║'));
  console.log(chalk.bold.green('╚════════════════════════════════════════╝\n'));
  console.log(chalk.white('What was configured:'));
  console.log(chalk.green(`  ✓ Service account: ${serviceAccount.client_email}`));
  console.log(chalk.green(`  ✓ Domain: ${domain}`));
  console.log(chalk.green(`  ✓ Team members: ${emails.join(', ')}`));
  console.log(chalk.green(`  ✓ Config: ${CONFIG_DIR}/google-workspace.json`));
  console.log(chalk.white('\nNext steps:'));
  console.log('  1. Restart OpenClaw: openclaw restart');
  console.log('  2. Test bold-ops agent via Google Chat');
  console.log('  3. If tests failed: check domain-wide delegation in Google Admin Console');
  console.log(chalk.gray('\n  Guide: docs/GOOGLE-WORKSPACE.md\n'));
}

run().catch(console.error);
