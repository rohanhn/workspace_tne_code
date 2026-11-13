// Launcher for the gitlab-tne MCP server (stdio).
// Claude Code does not expand ${GITLAB_TNE_PAT} from .claude/settings.local.json into a stdio
// server's env, so this reads the token itself: process env first, then settings.local.json.
// Never prints the token; stdout is reserved for the MCP protocol.
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const projectDir = path.resolve(__dirname, '..', '..');

function readLocalToken() {
  try {
    const file = path.join(projectDir, '.claude', 'settings.local.json');
    const json = JSON.parse(fs.readFileSync(file, 'utf8'));
    return json && json.env ? json.env.GITLAB_TNE_PAT : undefined;
  } catch {
    return undefined;
  }
}

const usable = (v) => typeof v === 'string' && v.trim() !== '' && !v.includes('${');
const token = usable(process.env.GITLAB_TNE_PAT) ? process.env.GITLAB_TNE_PAT : readLocalToken();

if (!usable(token)) {
  process.stderr.write('gitlab-launch: GITLAB_TNE_PAT not found in env or .claude/settings.local.json\n');
  process.exit(1);
}

const child = spawn('cmd', ['/c', 'npx', '-y', '@zereight/mcp-gitlab'], {
  stdio: 'inherit',
  env: {
    ...process.env,
    GITLAB_PERSONAL_ACCESS_TOKEN: token,
    GITLAB_API_URL: 'https://git.trangnguyen.edu.vn/api/v4',
    GITLAB_READ_ONLY_MODE: 'true',
    GITLAB_PERMISSION_MODE: 'readonly', // newer name; READ_ONLY_MODE kept for older versions
  },
  windowsHide: true,
});

for (const sig of ['SIGINT', 'SIGTERM']) process.on(sig, () => child.kill(sig));
child.on('exit', (code) => process.exit(code ?? 0));
child.on('error', (err) => {
  process.stderr.write(`gitlab-launch: ${err.message}\n`);
  process.exit(1);
});
