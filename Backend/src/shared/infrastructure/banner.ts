export interface ServerBannerOptions {
  port: number;
  nodeEnv: string;
  dbStatus: 'CONNECTED' | 'FAILED';
  dbLatencyMs?: number;
  version?: string;
}

export const printServerBanner = (options: ServerBannerOptions): void => {
  const cyan = '\x1b[36m';
  const boldCyan = '\x1b[1;36m';
  const boldGreen = '\x1b[1;32m';
  const boldYellow = '\x1b[1;33m';
  const boldRed = '\x1b[1;31m';
  const bold = '\x1b[1m';
  const dim = '\x1b[2m';
  const reset = '\x1b[0m';

  const isDbOk = options.dbStatus === 'CONNECTED';
  const dbStatusText = isDbOk
    ? `${boldGreen}CONNECTED${reset} ${dim}(PostgreSQL 17 + pgvector${options.dbLatencyMs !== undefined ? ` • ${options.dbLatencyMs}ms` : ''})${reset}`
    : `${boldRed}DISCONNECTED (retrying in background)${reset}`;

  const serverStatusBadge = isDbOk
    ? `${boldGreen}● SERVER LIVE & RUNNING${reset}`
    : `${boldYellow}▲ SERVER LIVE (DATABASE DEGRADED)${reset}`;

  const version = options.version ?? '0.1.0';

  const asciiArt = [
    '  ____  __  __    _    ____ _____ ____ _        _    ____ ____  ',
    ' / ___||  \\/  |  / \\  |  _ \\_   _/ ___| |      / \\  / ___/ ___| ',
    ' \\___ \\| |\\/| | / _ \\ | |_) || || |   | |     / _ \\ \\___ \\___ \\ ',
    '  ___) | |  | |/ ___ \\|  _ < | || |___| |___ / ___ \\ ___) |__) |',
    ' |____/|_|  |_/_/   \\_\\_| \\_\\|_| \\____|_____/_/   \\_\\____/____/ ',
  ].join('\n');

  const banner = `
${boldCyan}${asciiArt}${reset}
${dim} :: SmartClass Backend API ::                      (v${version})${reset}

${dim}┌────────────────────────────────────────────────────────────────────────┐${reset}
  ${serverStatusBadge}
${dim}├────────────────────────────────────────────────────────────────────────┤${reset}
  ${bold}• Database    :${reset} ${dbStatusText}
  ${bold}• Environment :${reset} ${cyan}${options.nodeEnv}${reset}
  ${bold}• Local Port  :${reset} ${boldCyan}${options.port}${reset}
  ${bold}• Base URL    :${reset} ${dim}http://localhost:${options.port}/api/v1${reset}
  ${bold}• Liveness    :${reset} ${dim}http://localhost:${options.port}/health/live${reset}
  ${bold}• Readiness   :${reset} ${dim}http://localhost:${options.port}/health/ready${reset}
${dim}└────────────────────────────────────────────────────────────────────────┘${reset}
`;

  console.log(banner);
};
